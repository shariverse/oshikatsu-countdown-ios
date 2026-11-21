#!/usr/bin/env ruby
# frozen_string_literal: true

#
# App Store Connect API で、課金の商品（自動更新サブスクリプションと非消耗型）を登録する。
#
#   1. Bundle ID からアプリを探す
#   2. サブスクリプショングループを referenceName で探し、無ければ作る。グループの表示名を言語ごとに入れる
#   3. サブスクリプションを productId で探し、無ければ作る。言語ごとに表示名と説明を入れ、
#      販売地域（すべての国・地域、新しい国・地域にも自動で）・価格・お試しの特典を、まだ無ければ入れる
#   4. 非消耗型を productId で探し、無ければ作る。言語ごとに表示名と説明を入れ、販売地域と価格を入れる
#
# 商品の定義は docs/app-store/in-app-purchases.json（定義の正はこのファイル）。言語は docs/app-store/languages.json の storeLocale に直す。
# 価格は baseTerritory（日本）の税込みの価格で、ほかの国・地域は App Store Connect の換算（equalization）に合わせる。
# サブスクリプションの販売地域はすでにあれば触らない。価格とお試しの特典は、まだ無い国・地域にだけ入れる（途中で失敗した実行の続きから入れられる。
# 入っている価格は変えないので、価格の変更は App Store Connect の画面で行う）。
# 非消耗型の価格は、毎回 baseTerritory の価格で価格表を入れ直す（同じ価格なら変わらない）。
# 審査用のスクリーンショットは扱わない（課金画面ができてから App Store Connect の画面で入れる）。審査への提出も行わない。
#
# APPLY が true でなければ、何も作らずに、作るもの・入れるものを表示するだけ（productId は一度作ると変えられないため、まずこれで確かめる）。
#
# 使い方（環境変数で渡す）:
#   BUNDLE_ID=jp.shilokuma.MyApp APPLY=false \
#   API_KEY_PATH=AuthKey_XXXXXXXXXX.p8 APPLE_API_KEY_ID=XXXXXXXXXX APPLE_API_ISSUER_ID=xxxxxxxx-... \
#   ruby .github/scripts/app-store-purchases/register-in-app-purchases.rb
#
# GITHUB_STEP_SUMMARY が設定されていれば（GitHub Actions 上）、結果を Job Summary にも書き出す。
#
# Ruby の標準ライブラリだけで動く（gem のインストールは不要）。

require 'base64'
require 'json'
require 'net/http'
require 'openssl'
require 'uri'

API_BASE = 'https://api.appstoreconnect.apple.com'
DEFINITION_PATH = 'docs/app-store/in-app-purchases.json'
LANGUAGES_PATH = 'docs/app-store/languages.json'

# App Store Connect の文字数の上限（課金の商品の表示名と説明）
LIMITS = { 'name' => 30, 'description' => 45 }.freeze
SUBSCRIPTION_PERIODS = %w[ONE_WEEK ONE_MONTH TWO_MONTHS THREE_MONTHS SIX_MONTHS ONE_YEAR].freeze
IN_APP_PURCHASE_TYPES = %w[CONSUMABLE NON_CONSUMABLE].freeze

def env!(name)
  value = ENV.fetch(name, '')
  abort "環境変数 #{name} が設定されていません" if value.empty?
  value
end

def base64url(data)
  Base64.urlsafe_encode64(data, padding: false)
end

def summary(markdown)
  puts markdown
  path = ENV.fetch('GITHUB_STEP_SUMMARY', '')
  File.write(path, "#{markdown}\n", mode: 'a') unless path.empty?
end

class ApiError < StandardError
  attr_reader :status

  def initialize(message, status = nil)
    super(message)
    @status = status
  end
end

# App Store Connect API の薄いクライアント。国・地域ごとの価格で 1 回の実行が 10 分を超えることがあるため、JWT はリクエストごとに作り直す
class Client
  def initialize(key_path:, key_id:, issuer_id:)
    @key = OpenSSL::PKey::EC.new(File.read(key_path))
    @key_id = key_id
    @issuer_id = issuer_id
  end

  def get(path, query = {})
    request(Net::HTTP::Get, path, query: query)
  end

  # links.next をたどって、すべてのページの data（と included）を集める
  def get_all(path, query = {})
    data = []
    included = []
    uri = URI("#{API_BASE}#{path}")
    uri.query = URI.encode_www_form(query) unless query.empty?
    loop do
      page = request(Net::HTTP::Get, uri.path, query: URI.decode_www_form(uri.query.to_s).to_h)
      data.concat(page.fetch('data', []))
      included.concat(page.fetch('included', []))
      next_url = page.dig('links', 'next')
      break if next_url.nil? || next_url.empty?

      uri = URI(next_url)
    end
    { 'data' => data, 'included' => included }
  end

  def post(path, body)
    request(Net::HTTP::Post, path, body: body)
  end

  def patch(path, body)
    request(Net::HTTP::Patch, path, body: body)
  end

  private

  # https://developer.apple.com/documentation/appstoreconnectapi/generating-tokens-for-api-requests
  def token
    now = Time.now.to_i
    header = { alg: 'ES256', kid: @key_id, typ: 'JWT' }
    payload = { iss: @issuer_id, iat: now, exp: now + (10 * 60), aud: 'appstoreconnect-v1' }
    signing_input = "#{base64url(header.to_json)}.#{base64url(payload.to_json)}"
    # OpenSSL の署名は DER 形式なので、JWT が求める r || s（各 32 バイト）に変換する
    der = @key.sign(OpenSSL::Digest.new('SHA256'), signing_input)
    r, s = OpenSSL::ASN1.decode(der).value.map { |n| n.value.to_s(2).rjust(32, "\x00") }
    "#{signing_input}.#{base64url(r + s)}"
  end

  def request(klass, path, query: {}, body: nil)
    uri = URI("#{API_BASE}#{path}")
    uri.query = URI.encode_www_form(query) unless query.empty?
    req = klass.new(uri)
    req['Authorization'] = "Bearer #{token}"
    # 価格の一覧は CSV でも返せるため、JSON を明示する
    req['Accept'] = 'application/json'
    if body
      req['Content-Type'] = 'application/json'
      req.body = body.to_json
    end
    res = Net::HTTP.start(uri.host, uri.port, use_ssl: true, open_timeout: 10, read_timeout: 60) { |http| http.request(req) }
    # 日本語のメッセージと連結するため、レスポンスは UTF-8 として扱う
    res.body&.force_encoding(Encoding::UTF_8)
    unless res.is_a?(Net::HTTPSuccess)
      raise ApiError.new("#{klass::METHOD} #{path} が失敗しました（HTTP #{res.code}）\n#{res.body}", res.code.to_i)
    end

    res.body.to_s.empty? ? {} : JSON.parse(res.body)
  end
end

def relationship(type, id)
  { data: { type: type, id: id } }
end

# 定義を読み、言語コードを App Store Connect のロケールに直す。定義の誤りは、API を呼ぶ前にまとめて止める
def read_definition
  definition = JSON.parse(File.read(DEFINITION_PATH))
  locales = JSON.parse(File.read(LANGUAGES_PATH)).fetch('languages').to_h { |l| [l.fetch('language'), l.fetch('storeLocale')] }
  errors = []

  check_localizations = lambda do |label, localizations, keys|
    missing = locales.keys - localizations.keys
    unknown = localizations.keys - locales.keys
    errors << "#{label}: 言語が足りません（#{missing.join(', ')}）" unless missing.empty?
    errors << "#{label}: languages.json に無い言語です（#{unknown.join(', ')}）" unless unknown.empty?
    localizations.each do |language, texts|
      keys.each do |key|
        text = texts[key].to_s
        errors << "#{label} #{language}: #{key} がありません" if text.empty?
        # 文字数は書記素で数える
        count = text.grapheme_clusters.size
        errors << "#{label} #{language}: #{key} が #{LIMITS[key]} 文字を超えています（#{count} 文字）" if count > LIMITS[key]
      end
    end
  end

  group = definition.fetch('subscriptionGroup')
  check_localizations.call('subscriptionGroup', group.fetch('localizations'), %w[name])
  definition.fetch('subscriptions').each do |product|
    check_localizations.call(product.fetch('productId'), product.fetch('localizations'), %w[name description])
    unless SUBSCRIPTION_PERIODS.include?(product.fetch('period'))
      errors << "#{product['productId']}: period が不正です（#{product['period']}）"
    end
  end
  definition.fetch('inAppPurchases').each do |product|
    check_localizations.call(product.fetch('productId'), product.fetch('localizations'), %w[name description])
    errors << "#{product['productId']}: type が不正です（#{product['type']}）" unless IN_APP_PURCHASE_TYPES.include?(product.fetch('type'))
  end
  product_ids = (definition['subscriptions'] + definition['inAppPurchases']).map { |p| p['productId'] }
  errors << "productId が重複しています（#{product_ids.group_by(&:itself).select { |_, ids| ids.size > 1 }.keys.join(', ')}）" if product_ids.uniq.size != product_ids.size
  abort "::error::#{DEFINITION_PATH} に誤りがあります\n#{errors.join("\n")}" unless errors.empty?

  [definition, locales]
end

def find_app(client, bundle_id)
  data = client.get('/v1/apps', 'filter[bundleId]' => bundle_id, 'fields[apps]' => 'name,bundleId').fetch('data')
  # filter が完全一致でない場合に備えて、Bundle ID が一致するものだけを見る
  data.find { |app| app.dig('attributes', 'bundleId') == bundle_id }
end

def all_territories(client)
  client.get_all('/v1/territories', 'limit' => '200').fetch('data').map { |t| t['id'] }
end

# 価格は "280" や "280.0" で返るので、数値で比べる
def same_price?(a, b)
  (Float(a) - Float(b)).abs < 0.001
end

# 一覧の中から locale で探し、あれば更新・無ければ作る
def upsert_localization(client, list_path:, type:, parent_key:, parent_type:, parent_id:, locale:, attributes:)
  existing = client.get_all(list_path, 'limit' => '200').fetch('data').find { |l| l.dig('attributes', 'locale') == locale }
  if existing
    same = attributes.all? { |key, value| existing.dig('attributes', key.to_s) == value }
    return '変更なし' if same

    client.patch("/v1/#{type}/#{existing['id']}", { data: { type: type, id: existing['id'], attributes: attributes } })
    '更新'
  else
    client.post("/v1/#{type}", {
      data: {
        type: type,
        attributes: attributes.merge(locale: locale),
        relationships: { parent_key => relationship(parent_type, parent_id) }
      }
    })
    '作成'
  end
end

def localize_all(client, localizations, locales, **options)
  localizations.map do |language, texts|
    attributes = texts.transform_keys(&:to_sym)
    result = upsert_localization(client, **options, locale: locales.fetch(language), attributes: attributes)
    "#{language}: #{result}"
  end
end

def find_group(client, app_id, reference_name)
  client.get_all("/v1/apps/#{app_id}/subscriptionGroups", 'limit' => '200').fetch('data')
        .find { |g| g.dig('attributes', 'referenceName') == reference_name }
end

def find_subscription(client, app_id, product_id)
  # productId はアプリの中で一意なので、ほかのグループにあっても見つける
  client.get_all("/v1/apps/#{app_id}/subscriptionGroups", 'limit' => '200').fetch('data').each do |group|
    found = client.get_all("/v1/subscriptionGroups/#{group['id']}/subscriptions", 'limit' => '200').fetch('data')
                  .find { |s| s.dig('attributes', 'productId') == product_id }
    return [found, group] if found
  end
  nil
end

def find_in_app_purchase(client, app_id, product_id)
  client.get_all("/v1/apps/#{app_id}/inAppPurchasesV2", 'limit' => '200').fetch('data')
        .find { |p| p.dig('attributes', 'productId') == product_id }
end

def prepare_group(client, app_id, group_definition, locales, apply:, log:)
  reference_name = group_definition.fetch('referenceName')
  group = find_group(client, app_id, reference_name)
  if group.nil?
    unless apply
      log << "- サブスクリプショングループ「#{reference_name}」を作ります"
      return nil
    end
    group = client.post('/v1/subscriptionGroups', {
      data: {
        type: 'subscriptionGroups',
        attributes: { referenceName: reference_name },
        relationships: { app: relationship('apps', app_id) }
      }
    }).fetch('data')
    log << "- サブスクリプショングループ「#{reference_name}」を作りました（#{group['id']}）"
  else
    log << "- サブスクリプショングループ「#{reference_name}」はあります（#{group['id']}）"
  end
  return group unless apply

  results = localize_all(
    client, group_definition.fetch('localizations'), locales,
    list_path: "/v1/subscriptionGroups/#{group['id']}/subscriptionGroupLocalizations",
    type: 'subscriptionGroupLocalizations', parent_key: :subscriptionGroup, parent_type: 'subscriptionGroups', parent_id: group['id']
  )
  log << "  - 表示名: #{results.join(' / ')}"
  group
end

def create_subscription(client, group_id, product)
  client.post('/v1/subscriptions', {
    data: {
      type: 'subscriptions',
      attributes: {
        name: product.fetch('referenceName'),
        productId: product.fetch('productId'),
        subscriptionPeriod: product.fetch('period'),
        groupLevel: product.fetch('groupLevel'),
        familySharable: product.fetch('familySharable'),
        reviewNote: product.fetch('reviewNote')
      },
      relationships: { group: relationship('subscriptionGroups', group_id) }
    }
  }).fetch('data')
end

def ensure_subscription_availability(client, subscription_id, territories)
  begin
    existing = client.get("/v1/subscriptions/#{subscription_id}/subscriptionAvailability")
    return 'すでにあります（変更しない）' if existing['data']
  rescue ApiError => e
    raise unless e.status == 404
  end
  client.post('/v1/subscriptionAvailabilities', {
    data: {
      type: 'subscriptionAvailabilities',
      attributes: { availableInNewTerritories: true },
      relationships: {
        subscription: relationship('subscriptions', subscription_id),
        availableTerritories: { data: territories.map { |t| { type: 'territories', id: t } } }
      }
    }
  })
  "すべての国・地域（#{territories.size}）と、新しい国・地域"
end

# 基準の国・地域の価格の price point と、ほかの国・地域の換算した price point を返す（territory => id）
def subscription_price_points(client, subscription_id, base_territory, price)
  points = client.get_all(
    "/v1/subscriptions/#{subscription_id}/pricePoints",
    'filter[territory]' => base_territory, 'fields[subscriptionPricePoints]' => 'customerPrice', 'limit' => '8000'
  ).fetch('data')
  base = points.find { |p| same_price?(p.dig('attributes', 'customerPrice'), price) }
  if base.nil?
    near = points.map { |p| p.dig('attributes', 'customerPrice') }.min_by(3) { |c| (Float(c) - Float(price)).abs }
    abort "::error::#{base_territory} に #{price} の価格がありません（近い価格: #{near.join(', ')}）。#{DEFINITION_PATH} の price を直してください"
  end

  equalized = client.get_all(
    "/v1/subscriptionPricePoints/#{base['id']}/equalizations",
    'include' => 'territory', 'fields[subscriptionPricePoints]' => 'customerPrice,territory', 'limit' => '8000'
  ).fetch('data')
  { base_territory => base['id'] }.merge(equalized.to_h { |p| [p.dig('relationships', 'territory', 'data', 'id'), p['id']] })
end

def territories_of(client, path)
  client.get_all(path, 'include' => 'territory', 'limit' => '200')
        .fetch('data').map { |item| item.dig('relationships', 'territory', 'data', 'id') }.compact.uniq
end

# 価格がまだ無い国・地域にだけ入れる（途中で失敗した実行の続きも、ここから入れられる）
def ensure_subscription_prices(client, subscription_id, base_territory, price, territories)
  priced = territories_of(client, "/v1/subscriptions/#{subscription_id}/prices")
  remaining = territories - priced
  return "すでにあります（#{priced.size} の国・地域。変更しない）" if remaining.empty?

  points = subscription_price_points(client, subscription_id, base_territory, price)
  targets = remaining & points.keys
  targets.each do |territory|
    client.post('/v1/subscriptionPrices', {
      data: {
        type: 'subscriptionPrices',
        attributes: { preserveCurrentPrice: false },
        relationships: {
          subscription: relationship('subscriptions', subscription_id),
          subscriptionPricePoint: relationship('subscriptionPricePoints', points.fetch(territory)),
          territory: relationship('territories', territory)
        }
      }
    })
  end
  missing = remaining - points.keys
  note = missing.empty? ? '' : "（換算の無い国・地域: #{missing.join(', ')}）"
  kept = priced.empty? ? '' : "（すでにある #{priced.size} の国・地域は変更しない）"
  "#{base_territory} #{price} を基準に #{targets.size} の国・地域#{note}#{kept}"
end

# お試しがまだ無い国・地域にだけ入れる。価格のある国・地域だけが対象
def ensure_introductory_offer(client, subscription_id, offer, territories)
  offered = territories_of(client, "/v1/subscriptions/#{subscription_id}/introductoryOffers")
  priced = territories_of(client, "/v1/subscriptions/#{subscription_id}/prices")
  return '価格のある国・地域が無いので入れません' if priced.empty?

  remaining = (territories & priced) - offered
  return "すでにあります（#{offered.size} の国・地域。変更しない）" if remaining.empty?

  attributes = {
    offerMode: offer.fetch('offerMode'),
    duration: offer.fetch('duration'),
    numberOfPeriods: offer.fetch('numberOfPeriods')
  }
  # 無料のお試しは価格が要らないので subscriptionPricePoint を付けない。territory は国・地域ごとに 1 件ずつ作る（画面で作ったときと同じ形）
  remaining.each do |territory|
    client.post('/v1/subscriptionIntroductoryOffers', {
      data: {
        type: 'subscriptionIntroductoryOffers',
        attributes: attributes,
        relationships: {
          subscription: relationship('subscriptions', subscription_id),
          territory: relationship('territories', territory)
        }
      }
    })
  end
  "#{offer['offerMode']} #{offer['duration']} × #{offer['numberOfPeriods']}（#{remaining.size} の国・地域）"
end

def prepare_subscription(client, app_id, group, product, locales, base_territory, territories, apply:, log:)
  product_id = product.fetch('productId')
  found, found_group = find_subscription(client, app_id, product_id)
  if found && group && found_group['id'] != group['id']
    abort "::error::#{product_id} は別のグループ（#{found_group.dig('attributes', 'referenceName')}）にあります"
  end

  if found.nil?
    unless apply
      log << "- サブスクリプション #{product_id} を作ります（#{product['period']}・#{base_territory} #{product['price']}・" \
             "ファミリー共有 #{product['familySharable'] ? 'ON' : 'OFF'}#{product['introductoryOffer'] ? '・お試しあり' : ''}）"
      return
    end
    found = create_subscription(client, group.fetch('id'), product)
    log << "- サブスクリプション #{product_id} を作りました（#{found['id']}）"
  else
    log << "- サブスクリプション #{product_id} はあります（#{found['id']}・#{found.dig('attributes', 'state')}）"
  end
  return unless apply

  subscription_id = found['id']
  results = localize_all(
    client, product.fetch('localizations'), locales,
    list_path: "/v1/subscriptions/#{subscription_id}/subscriptionLocalizations",
    type: 'subscriptionLocalizations', parent_key: :subscription, parent_type: 'subscriptions', parent_id: subscription_id
  )
  log << "  - 表示名と説明: #{results.join(' / ')}"
  log << "  - 販売地域: #{ensure_subscription_availability(client, subscription_id, territories)}"
  log << "  - 価格: #{ensure_subscription_prices(client, subscription_id, base_territory, product.fetch('price'), territories)}"
  offer = product['introductoryOffer']
  log << "  - お試し: #{ensure_introductory_offer(client, subscription_id, offer, territories)}" if offer
end

def ensure_in_app_purchase_availability(client, iap_id, territories)
  begin
    existing = client.get("/v2/inAppPurchases/#{iap_id}/inAppPurchaseAvailability")
    return 'すでにあります（変更しない）' if existing['data']
  rescue ApiError => e
    raise unless e.status == 404
  end
  client.post('/v1/inAppPurchaseAvailabilities', {
    data: {
      type: 'inAppPurchaseAvailabilities',
      attributes: { availableInNewTerritories: true },
      relationships: {
        inAppPurchase: relationship('inAppPurchases', iap_id),
        availableTerritories: { data: territories.map { |t| { type: 'territories', id: t } } }
      }
    }
  })
  "すべての国・地域（#{territories.size}）と、新しい国・地域"
end

# 基準の国・地域の価格で価格表を入れる。ほかの国・地域は App Store Connect が換算する
def set_in_app_purchase_price(client, iap_id, base_territory, price)
  points = client.get_all(
    "/v2/inAppPurchases/#{iap_id}/pricePoints",
    'filter[territory]' => base_territory, 'fields[inAppPurchasePricePoints]' => 'customerPrice', 'limit' => '8000'
  ).fetch('data')
  point = points.find { |p| same_price?(p.dig('attributes', 'customerPrice'), price) }
  if point.nil?
    near = points.map { |p| p.dig('attributes', 'customerPrice') }.min_by(3) { |c| (Float(c) - Float(price)).abs }
    abort "::error::#{base_territory} に #{price} の価格がありません（近い価格: #{near.join(', ')}）。#{DEFINITION_PATH} の price を直してください"
  end

  local_id = '${base-price}'
  client.post('/v1/inAppPurchasePriceSchedules', {
    data: {
      type: 'inAppPurchasePriceSchedules',
      relationships: {
        inAppPurchase: relationship('inAppPurchases', iap_id),
        baseTerritory: relationship('territories', base_territory),
        manualPrices: { data: [{ type: 'inAppPurchasePrices', id: local_id }] }
      }
    },
    included: [{
      type: 'inAppPurchasePrices',
      id: local_id,
      attributes: { startDate: nil },
      relationships: {
        inAppPurchaseV2: relationship('inAppPurchases', iap_id),
        inAppPurchasePricePoint: relationship('inAppPurchasePricePoints', point['id'])
      }
    }]
  })
  "#{base_territory} #{price} を基準（ほかの国・地域は換算）"
end

def prepare_in_app_purchase(client, app_id, product, locales, base_territory, territories, apply:, log:)
  product_id = product.fetch('productId')
  found = find_in_app_purchase(client, app_id, product_id)
  if found.nil?
    unless apply
      log << "- #{product['type']} #{product_id} を作ります（#{base_territory} #{product['price']}・" \
             "ファミリー共有 #{product['familySharable'] ? 'ON' : 'OFF'}）"
      return
    end
    found = client.post('/v2/inAppPurchases', {
      data: {
        type: 'inAppPurchases',
        attributes: {
          name: product.fetch('referenceName'),
          productId: product_id,
          inAppPurchaseType: product.fetch('type'),
          familySharable: product.fetch('familySharable'),
          reviewNote: product.fetch('reviewNote')
        },
        relationships: { app: relationship('apps', app_id) }
      }
    }).fetch('data')
    log << "- #{product['type']} #{product_id} を作りました（#{found['id']}）"
  else
    log << "- #{found.dig('attributes', 'inAppPurchaseType')} #{product_id} はあります（#{found['id']}・#{found.dig('attributes', 'state')}）"
  end
  return unless apply

  iap_id = found['id']
  results = localize_all(
    client, product.fetch('localizations'), locales,
    list_path: "/v2/inAppPurchases/#{iap_id}/inAppPurchaseLocalizations",
    type: 'inAppPurchaseLocalizations', parent_key: :inAppPurchaseV2, parent_type: 'inAppPurchases', parent_id: iap_id
  )
  log << "  - 表示名と説明: #{results.join(' / ')}"
  log << "  - 販売地域: #{ensure_in_app_purchase_availability(client, iap_id, territories)}"
  log << "  - 価格: #{set_in_app_purchase_price(client, iap_id, base_territory, product.fetch('price'))}"
end

def main
  definition, locales = read_definition
  apply = ENV.fetch('APPLY', 'false') == 'true'
  bundle_id = env!('BUNDLE_ID')
  client = Client.new(key_path: env!('API_KEY_PATH'), key_id: env!('APPLE_API_KEY_ID'), issuer_id: env!('APPLE_API_ISSUER_ID'))

  app = find_app(client, bundle_id)
  abort "::error::App Store Connect に #{bundle_id} のアプリがありません" if app.nil?

  base_territory = definition.fetch('baseTerritory')
  territories = all_territories(client)
  abort "::error::国・地域の一覧に #{base_territory} がありません" unless territories.include?(base_territory)

  log = []
  begin
    group = prepare_group(client, app['id'], definition.fetch('subscriptionGroup'), locales, apply: apply, log: log)
    definition.fetch('subscriptions').each do |product|
      prepare_subscription(client, app['id'], group, product, locales, base_territory, territories, apply: apply, log: log)
    end
    definition.fetch('inAppPurchases').each do |product|
      prepare_in_app_purchase(client, app['id'], product, locales, base_territory, territories, apply: apply, log: log)
    end
  ensure
    # 途中で失敗しても、そこまでにしたことを残す（作り直さないよう、次の実行は productId で見つけて続きから行う）
    title = apply ? '課金の商品を登録しました' : '課金の商品の確認（何も作っていません）'
    summary(["## #{title}", '', "アプリ: #{app.dig('attributes', 'name')}（#{bundle_id}）", '', *log].join("\n"))
  end
end

main
