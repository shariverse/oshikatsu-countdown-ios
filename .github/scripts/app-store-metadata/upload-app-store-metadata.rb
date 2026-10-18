#!/usr/bin/env ruby
# frozen_string_literal: true

#
# App Store Connect API で、App Store の掲載文とスクリーンショットを登録する。
#
#   1. Bundle ID からアプリを探し、VERSION の App Store バージョンを用意する
#      （無ければ、審査前のバージョンの番号を VERSION に変える。それも無ければ作る）
#   2. App 情報のローカリゼーションに、アプリ名・サブタイトルを入れる
#   3. バージョンのローカリゼーションに、説明文・キーワード・プロモーションテキストを入れる
#   4. App Review に関する情報のメモに、審査用メモを入れる
#   5. SCREENSHOT_DIR があれば、画像のサイズから端末の種類を決めて、スクリーンショットを差し替える
#
# 文面は docs/app-store/listing.md と review-notes.md の、見出しの下のコードブロックから読む（文面の正はこの 2 つ）。
# サポート URL・プライバシーポリシー URL・著作権・連絡先・カテゴリ・年齢制限・価格は扱わないので、App Store Connect の画面で入れる。
# 審査への提出は行わない。
#
# 使い方（環境変数で渡す）:
#   BUNDLE_ID=jp.shilokuma.MyApp VERSION=1.0.0 LOCALE=ja \
#   SCREENSHOT_DIR=build/app-store-screenshots \
#   API_KEY_PATH=AuthKey_XXXXXXXXXX.p8 APPLE_API_KEY_ID=XXXXXXXXXX APPLE_API_ISSUER_ID=xxxxxxxx-... \
#   ruby .github/scripts/app-store-metadata/upload-app-store-metadata.rb
#
# SCREENSHOT_DIR は scripts/app-store-screenshots.sh の出力先（端末ごとのフォルダに画像と manifest.json がある）。
# 空ならスクリーンショットは触らない。透過のある PNG は App Store Connect が受け付けないため、sips で JPEG にしてから上げる（macOS が要る）。
# GITHUB_STEP_SUMMARY が設定されていれば（GitHub Actions 上）、結果を Job Summary にも書き出す。
#
# Ruby の標準ライブラリだけで動く（gem のインストールは不要）。

require 'base64'
require 'digest'
require 'json'
require 'net/http'
require 'openssl'
require 'tmpdir'
require 'uri'

API_BASE = 'https://api.appstoreconnect.apple.com'
# 番号を変えたり文面を入れたりできる（審査に出す前・却下後の）バージョンの状態
EDITABLE_STATES = %w[PREPARE_FOR_SUBMISSION DEVELOPER_REJECTED REJECTED METADATA_REJECTED INVALID_BINARY].freeze
PROCESSING_TIMEOUT = 15 * 60

# App Store Connect の文字数の上限
LIMITS = { name: 30, subtitle: 30, promotionalText: 170, keywords: 100, description: 4000, notes: 4000 }.freeze

# 画像のサイズ（縦向き）→ スクリーンショットの種類。6.9 インチの iPhone は APP_IPHONE_67、13 インチの iPad は APP_IPAD_PRO_3GEN_129 に入る
DISPLAY_TYPES = {
  [1320, 2868] => 'APP_IPHONE_67',
  [1290, 2796] => 'APP_IPHONE_67',
  [2064, 2752] => 'APP_IPAD_PRO_3GEN_129',
  [2048, 2732] => 'APP_IPAD_PRO_3GEN_129'
}.freeze

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

# App Store Connect API の薄いクライアント。処理待ちで 10 分を超えることがあるため、JWT はリクエストごとに作り直す
class Client
  def initialize(key_path:, key_id:, issuer_id:)
    @key = OpenSSL::PKey::EC.new(File.read(key_path))
    @key_id = key_id
    @issuer_id = issuer_id
  end

  def get(path, query = {})
    request(Net::HTTP::Get, path, query: query)
  end

  def post(path, body)
    request(Net::HTTP::Post, path, body: body)
  end

  def patch(path, body)
    request(Net::HTTP::Patch, path, body: body)
  end

  def delete(path)
    request(Net::HTTP::Delete, path)
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

# Markdown の「## <見出し>」の下にある最初のコードブロックの中身を返す。見出しが nil なら、ファイルの最初のコードブロック
def code_block(markdown, heading = nil)
  lines = markdown.lines
  start = heading ? lines.index { |l| l.start_with?("## #{heading}") } : -1
  abort "見出し「#{heading}」が見つかりません" unless start
  open = (start + 1...lines.size).find { |i| lines[i].start_with?('```') }
  abort "見出し「#{heading}」の下にコードブロックがありません" unless open
  close = (open + 1...lines.size).find { |i| lines[i].start_with?('```') }
  abort "見出し「#{heading}」のコードブロックが閉じていません" unless close
  lines[(open + 1)...close].join.strip
end

def read_texts(listing_path, review_notes_path)
  listing = File.read(listing_path, encoding: Encoding::UTF_8)
  texts = {
    name: code_block(listing, 'アプリ名'),
    subtitle: code_block(listing, 'サブタイトル'),
    promotionalText: code_block(listing, 'プロモーションテキスト'),
    description: code_block(listing, '説明文'),
    keywords: code_block(listing, 'キーワード'),
    notes: code_block(File.read(review_notes_path, encoding: Encoding::UTF_8))
  }
  over = texts.select { |key, value| value.length > LIMITS.fetch(key) }
  unless over.empty?
    abort over.map { |key, value| "#{key} が #{value.length} 文字です（上限 #{LIMITS[key]} 文字）" }.join("\n")
  end
  texts
end

def find_app(client, bundle_id)
  data = client.get('/v1/apps', 'filter[bundleId]' => bundle_id, 'fields[apps]' => 'name,bundleId,primaryLocale').fetch('data')
  # filter が完全一致でない場合に備えて、Bundle ID が一致するものだけを見る
  data.find { |app| app.dig('attributes', 'bundleId') == bundle_id }
end

def version_state(version)
  version.dig('attributes', 'appVersionState') || version.dig('attributes', 'appStoreState')
end

# VERSION の App Store バージョンを返す。無ければ審査前のものの番号を変え、それも無ければ作る
def prepare_version(client, app_id, version_string)
  versions = client.get(
    "/v1/apps/#{app_id}/appStoreVersions",
    'filter[platform]' => 'IOS',
    'fields[appStoreVersions]' => 'versionString,appVersionState,appStoreState',
    'limit' => '20'
  ).fetch('data')

  version = versions.find { |v| v.dig('attributes', 'versionString') == version_string }
  if version
    state = version_state(version)
    abort "::error::バージョン #{version_string} は編集できない状態です（#{state}）" unless EDITABLE_STATES.include?(state)
    return [version, 'そのまま使いました']
  end

  editable = versions.find { |v| EDITABLE_STATES.include?(version_state(v)) }
  if editable
    old = editable.dig('attributes', 'versionString')
    updated = client.patch("/v1/appStoreVersions/#{editable['id']}", {
      data: { type: 'appStoreVersions', id: editable['id'], attributes: { versionString: version_string } }
    }).fetch('data')
    return [updated, "審査前のバージョン #{old} の番号を変えました"]
  end

  created = client.post('/v1/appStoreVersions', {
    data: {
      type: 'appStoreVersions',
      attributes: { platform: 'IOS', versionString: version_string },
      relationships: { app: { data: { type: 'apps', id: app_id } } }
    }
  }).fetch('data')
  [created, '新しく作りました']
end

# 審査前の App 情報（アプリ名・サブタイトルを持つ）を返す
def editable_app_info(client, app_id)
  infos = client.get("/v1/apps/#{app_id}/appInfos").fetch('data')
  infos.find { |i| EDITABLE_STATES.include?(i.dig('attributes', 'state') || i.dig('attributes', 'appStoreState')) }
end

# ローカリゼーションを locale で探し、あれば更新・無ければ作る
def upsert_localization(client, list_path:, type:, parent_key:, parent_type:, parent_id:, locale:, attributes:)
  existing = client.get(list_path, "fields[#{type}]" => 'locale').fetch('data').find { |l| l.dig('attributes', 'locale') == locale }
  if existing
    client.patch("/v1/#{type}/#{existing['id']}", { data: { type: type, id: existing['id'], attributes: attributes } })
    [existing['id'], '更新']
  else
    created = client.post("/v1/#{type}", {
      data: {
        type: type,
        attributes: attributes.merge(locale: locale),
        relationships: { parent_key => { data: { type: parent_type, id: parent_id } } }
      }
    }).fetch('data')
    [created['id'], '作成']
  end
end

def upsert_review_notes(client, version_id, notes)
  attributes = { notes: notes, demoAccountRequired: false }
  detail = begin
    client.get("/v1/appStoreVersions/#{version_id}/appStoreReviewDetail").fetch('data')
  rescue ApiError => e
    raise unless e.status == 404

    nil
  end

  if detail
    client.patch("/v1/appStoreReviewDetails/#{detail['id']}", { data: { type: 'appStoreReviewDetails', id: detail['id'], attributes: attributes } })
    '更新'
  else
    client.post('/v1/appStoreReviewDetails', {
      data: {
        type: 'appStoreReviewDetails',
        attributes: attributes,
        relationships: { appStoreVersion: { data: { type: 'appStoreVersions', id: version_id } } }
      }
    })
    '作成'
  end
end

# PNG の幅・高さと透過の有無を IHDR から読む
def png_info(path)
  header = File.binread(path, 26)
  abort "#{path} は PNG ではありません" unless header&.start_with?("\x89PNG".b)
  width, height = header.byteslice(16, 8).unpack('NN')
  color_type = header.getbyte(25)
  { width: width, height: height, alpha: [4, 6].include?(color_type) }
end

# scripts/app-store-screenshots.sh の出力から、種類ごとに撮った順の画像を集める
def collect_screenshots(screenshot_dir, work_dir)
  groups = Hash.new { |h, k| h[k] = [] }
  Dir.glob(File.join(screenshot_dir, '*/manifest.json')).sort.each do |manifest_path|
    device_dir = File.dirname(manifest_path)
    # 書き出したファイル名は UUID なので、添付の名前（「01-ホーム_0_…」）の順に並べる
    attachments = JSON.parse(File.read(manifest_path, encoding: Encoding::UTF_8)).flat_map { |test| test.fetch('attachments') }
    files = attachments.sort_by { |a| a.fetch('suggestedHumanReadableName') }.map { |a| a.fetch('exportedFileName') }
    files.each do |file|
      path = File.join(device_dir, file)
      info = png_info(path)
      type = DISPLAY_TYPES[[info[:width], info[:height]]]
      abort "#{path} のサイズ（#{info[:width]}x#{info[:height]}）に合うスクリーンショットの種類がありません" unless type

      if info[:alpha]
        jpeg = File.join(work_dir, "#{File.basename(device_dir)}-#{File.basename(file, '.*')}.jpg")
        system('sips', '-s', 'format', 'jpeg', '-s', 'formatOptions', '95', path, '--out', jpeg, out: File::NULL, exception: true)
        path = jpeg
      end
      groups[type] << path
    end
  end
  groups
end

def upload_screenshot(client, set_id, path)
  file_name = File.basename(path)
  bytes = File.binread(path)
  reservation = client.post('/v1/appScreenshots', {
    data: {
      type: 'appScreenshots',
      attributes: { fileName: file_name, fileSize: bytes.bytesize },
      relationships: { appScreenshotSet: { data: { type: 'appScreenshotSets', id: set_id } } }
    }
  }).fetch('data')
  screenshot_id = reservation['id']

  # アップロード先の URL は認証不要・期限付きのため、JWT は付けない
  reservation.dig('attributes', 'uploadOperations').each do |op|
    uri = URI(op['url'])
    req = Net::HTTPGenericRequest.new(op['method'], true, true, uri)
    op['requestHeaders'].each { |h| req[h['name']] = h['value'] }
    req.body = bytes.byteslice(op['offset'], op['length'])
    res = Net::HTTP.start(uri.host, uri.port, use_ssl: true) { |http| http.request(req) }
    raise ApiError, "#{file_name} のアップロードに失敗しました（HTTP #{res.code}）\n#{res.body}" unless res.is_a?(Net::HTTPSuccess)
  end

  client.patch("/v1/appScreenshots/#{screenshot_id}", {
    data: { type: 'appScreenshots', id: screenshot_id, attributes: { uploaded: true, sourceFileChecksum: Digest::MD5.hexdigest(bytes) } }
  })
  puts "アップロードしました: #{file_name}（#{screenshot_id}）"
  screenshot_id
end

def wait_screenshots(client, ids)
  deadline = Time.now + PROCESSING_TIMEOUT
  pending = ids.dup
  results = {}
  until pending.empty?
    pending.reject! do |id|
      delivery = client.get("/v1/appScreenshots/#{id}", 'fields[appScreenshots]' => 'fileName,assetDeliveryState').dig('data', 'attributes')
      state = delivery.dig('assetDeliveryState', 'state')
      next false if %w[AWAITING_UPLOAD UPLOAD_COMPLETE].include?(state)

      results[id] = [delivery['fileName'], state, delivery.dig('assetDeliveryState', 'errors')]
      true
    end
    break if pending.empty?
    raise ApiError, "スクリーンショットの処理が #{PROCESSING_TIMEOUT / 60} 分で終わりませんでした" if Time.now > deadline

    sleep 10
  end
  results
end

# 種類ごとに、既存のスクリーンショットを消してから撮った順に上げ直す
def replace_screenshots(client, localization_id, groups)
  sets = client.get(
    "/v1/appStoreVersionLocalizations/#{localization_id}/appScreenshotSets",
    'fields[appScreenshotSets]' => 'screenshotDisplayType'
  ).fetch('data')

  rows = []
  groups.each do |type, paths|
    set = sets.find { |s| s.dig('attributes', 'screenshotDisplayType') == type }
    set ||= client.post('/v1/appScreenshotSets', {
      data: {
        type: 'appScreenshotSets',
        attributes: { screenshotDisplayType: type },
        relationships: { appStoreVersionLocalization: { data: { type: 'appStoreVersionLocalizations', id: localization_id } } }
      }
    }).fetch('data')

    existing = client.get("/v1/appScreenshotSets/#{set['id']}/appScreenshots", 'fields[appScreenshots]' => 'fileName').fetch('data')
    existing.each { |s| client.delete("/v1/appScreenshots/#{s['id']}") }

    ids = paths.map { |path| upload_screenshot(client, set['id'], path) }
    results = wait_screenshots(client, ids)
    # 上げた順に並べる
    client.patch("/v1/appScreenshotSets/#{set['id']}/relationships/appScreenshots", { data: ids.map { |id| { type: 'appScreenshots', id: id } } })

    ids.each do |id|
      file_name, state, errors = results[id]
      details = errors && !errors.empty? ? "<br>#{errors.to_json}" : ''
      rows << "| #{type} | #{file_name} | #{state}#{details} |"
    end
    rows << "| #{type} | （既存の #{existing.size} 枚を削除） | |" unless existing.empty?
  end

  summary(<<~MARKDOWN)
    ### スクリーンショット

    | 種類 | ファイル | 状態 |
    | --- | --- | --- |
    #{rows.join("\n")}
  MARKDOWN
  rows.none? { |r| r.include?('FAILED') }
end

bundle_id = env!('BUNDLE_ID')
version_string = env!('VERSION')
locale = ENV.fetch('LOCALE', 'ja')
listing_path = ENV.fetch('LISTING_PATH', 'docs/app-store/listing.md')
review_notes_path = ENV.fetch('REVIEW_NOTES_PATH', 'docs/app-store/review-notes.md')
screenshot_dir = ENV.fetch('SCREENSHOT_DIR', '')

texts = read_texts(listing_path, review_notes_path)
client = Client.new(key_path: env!('API_KEY_PATH'), key_id: env!('APPLE_API_KEY_ID'), issuer_id: env!('APPLE_API_ISSUER_ID'))

begin
  summary("## App Store の掲載文とスクリーンショットの登録（#{bundle_id} #{version_string} / #{locale}）\n")

  app = find_app(client, bundle_id)
  unless app
    summary("Bundle ID `#{bundle_id}` のアプリが App Store Connect にありません。先に Web 画面でアプリを作成してください。")
    puts "::error::App Store Connect に #{bundle_id} のアプリがありません"
    exit 1
  end
  primary_locale = app.dig('attributes', 'primaryLocale')
  summary("アプリ: #{app.dig('attributes', 'name')}（ID: `#{app['id']}`、主要言語: #{primary_locale}）\n")
  puts "::warning::アプリの主要言語が #{primary_locale} です（#{locale} のローカリゼーションを入れます）" if primary_locale != locale

  version, how = prepare_version(client, app['id'], version_string)
  summary("バージョン #{version_string}: #{how}（ID: `#{version['id']}`）\n")

  rows = []
  app_info = editable_app_info(client, app['id'])
  abort '::error::編集できる（審査前の）App 情報がありません' unless app_info
  _, done = upsert_localization(
    client,
    list_path: "/v1/appInfos/#{app_info['id']}/appInfoLocalizations",
    type: 'appInfoLocalizations', parent_key: :appInfo, parent_type: 'appInfos', parent_id: app_info['id'],
    locale: locale, attributes: { name: texts[:name], subtitle: texts[:subtitle] }
  )
  rows << "| App 情報 | アプリ名・サブタイトル | #{done} |"

  localization_id, done = upsert_localization(
    client,
    list_path: "/v1/appStoreVersions/#{version['id']}/appStoreVersionLocalizations",
    type: 'appStoreVersionLocalizations', parent_key: :appStoreVersion, parent_type: 'appStoreVersions', parent_id: version['id'],
    locale: locale, attributes: texts.slice(:description, :keywords, :promotionalText)
  )
  rows << "| バージョン #{version_string} | 説明文・キーワード・プロモーションテキスト | #{done} |"

  done = upsert_review_notes(client, version['id'], texts[:notes])
  rows << "| App Review に関する情報 | メモ（デモ用アカウントは不要） | #{done} |"

  summary(<<~MARKDOWN)
    ### 掲載文

    | 場所 | 項目 | 結果 |
    | --- | --- | --- |
    #{rows.join("\n")}
  MARKDOWN

  if screenshot_dir.empty?
    summary("スクリーンショットは触っていません（SCREENSHOT_DIR が空）。\n")
  else
    groups = Dir.mktmpdir { |work_dir| replace_screenshots(client, localization_id, collect_screenshots(screenshot_dir, work_dir)) }
    exit 1 unless groups
  end

  summary(<<~MARKDOWN)
    ### 画面で入れるもの

    サポート URL・プライバシーポリシー URL・著作権・App Review の連絡先・カテゴリ・年齢制限・価格と配信国・App のプライバシー・ビルドの選択は、このスクリプトでは入れていません。審査に出す前に App Store Connect の画面で入れてください。
  MARKDOWN
rescue ApiError => e
  summary("### エラー\n\n```\n#{e.message}\n```\n")
  puts "::error::#{e.message.lines.first.strip}"
  exit 1
end
