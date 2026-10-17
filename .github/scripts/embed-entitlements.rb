#!/usr/bin/env ruby
# frozen_string_literal: true

#
# 署名せずに作った Archive（CODE_SIGNING_ALLOWED=NO）の各バンドルに、ターゲットの Entitlements を埋め込む。
#
# Entitlements はコード署名に載るため、署名の無い Archive には入らない。xcodebuild -exportArchive は
# Archive の署名に載った Entitlements を引き継いで署名し直すので、そのまま Export すると App Group などが抜け落ちる。
# Export の前にアドホック署名（codesign --sign -）で Entitlements を載せておき、Export で配布用の署名に置き換えさせる。
#
# 埋め込む Entitlements は、各ターゲットの CODE_SIGN_ENTITLEMENTS のファイルの $(変数) をビルド設定で展開したもの。
# Archive に入ったバンドル（アプリと App Extension）を、FULL_PRODUCT_NAME でターゲットと突き合わせる。
# 入れ子のバンドルの署名は外側の署名に含まれるので、内側（App Extension）から先に署名する。
#
# 使い方（環境変数で渡す）:
#   ARCHIVE_PATH=build.xcarchive PROJECT_PATH=MyApp.xcodeproj CONFIGURATION=Release \
#   ruby .github/scripts/embed-entitlements.rb
#
# Ruby の標準ライブラリだけで動く（gem のインストールは不要）。

require 'json'
require 'open3'
require 'tmpdir'

def env!(name)
  value = ENV.fetch(name, '')
  abort "環境変数 #{name} が設定されていません" if value.empty?
  value
end

def run!(*command)
  output, status = Open3.capture2e(*command)
  abort "失敗しました: #{command.join(' ')}\n#{output}" unless status.success?
  output
end

# 値の中の $(NAME) / ${NAME} をビルド設定で展開する。知らない変数は残さずに止める（空の App Group で署名しないため）
def expand(value, settings)
  case value
  when String
    value.gsub(/\$[({](\w+)[)}]/) do
      settings.fetch(Regexp.last_match(1)) { abort "ビルド設定 #{Regexp.last_match(1)} が見つかりません（#{value}）" }
    end
  when Array then value.map { |item| expand(item, settings) }
  when Hash then value.transform_values { |item| expand(item, settings) }
  else value
  end
end

archive_path = env!('ARCHIVE_PATH')
project_path = env!('PROJECT_PATH')
configuration = env!('CONFIGURATION')

# スキームを指定すると依存先（App Extension）のターゲットが出ないので、全ターゲットの設定を取る
targets = JSON.parse(
  run!('xcodebuild', '-showBuildSettings', '-project', project_path, '-alltargets',
       '-configuration', configuration, '-sdk', 'iphoneos', '-json')
)

bundles = Dir.glob(File.join(archive_path, 'Products', 'Applications', '**', '*.{app,appex}'))
abort "#{archive_path} にアプリが見つかりません" if bundles.empty?

project_dir = File.dirname(File.expand_path(project_path))
signed = 0

Dir.mktmpdir do |dir|
  # 深い（内側の）バンドルから署名する
  bundles.sort_by { |path| -path.count('/') }.each do |bundle|
    target = targets.find { |entry| entry.dig('buildSettings', 'FULL_PRODUCT_NAME') == File.basename(bundle) }
    abort "#{File.basename(bundle)} を作るターゲットが見つかりません" unless target

    settings = target['buildSettings']
    entitlements_path = settings.fetch('CODE_SIGN_ENTITLEMENTS', '')
    if entitlements_path.empty?
      puts "#{target['target']}: Entitlements なし"
      run!('codesign', '--force', '--sign', '-', '--timestamp=none', bundle)
      next
    end

    source = JSON.parse(run!('plutil', '-convert', 'json', '-o', '-', File.expand_path(entitlements_path, project_dir)))
    expanded = File.join(dir, "#{target['target']}.entitlements")
    File.write("#{expanded}.json", JSON.generate(expand(source, settings)))
    run!('plutil', '-convert', 'xml1', '-o', expanded, "#{expanded}.json")

    run!('codesign', '--force', '--sign', '-', '--timestamp=none', '--generate-entitlement-der',
         '--entitlements', expanded, bundle)
    puts "#{target['target']}: #{File.basename(bundle)} に Entitlements を埋め込みました"
    puts run!('codesign', '--display', '--entitlements', '-', '--xml', bundle)
    signed += 1
  end
end

abort 'Entitlements を埋め込んだバンドルがありません' if signed.zero?
