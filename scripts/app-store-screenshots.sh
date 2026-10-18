#!/bin/bash
#
# App Store 用スクリーンショットを、1 つの表示サイズについて言語ごとに撮る。
# 見本の推しと予定で UI テスト（AppStoreScreenshotTests）を流し、撮った画像を出力先に書き出す。ステータスバーは 9:41・電池満タンにそろえる。
#
# 使い方:
#   scripts/app-store-screenshots.sh <表示サイズ> [言語（カンマ区切り）]
#   scripts/app-store-screenshots.sh APP_IPHONE_67          # docs/app-store/languages.json の全言語
#   scripts/app-store-screenshots.sh APP_IPAD_PRO_3GEN_129 ja,en
#
# 表示サイズと機種は docs/app-store/screenshots.json、言語は docs/app-store/languages.json で決める。
# 機種は screenshots.json の devices のうち、ランナーにある最初のものを、SDK 以下でいちばん新しい iOS のランタイムで新しく作る。
# 1 回ビルドしたもの（build-for-testing）を言語ごとに使い回す。
#
# 出力先: $SCREENSHOTS_DIR/<表示サイズ>/<言語>/（画像と manifest.json。既定は build/app-store-screenshots）
#
# 環境変数:
#   SCREENSHOTS_DIR  出力先（既定は build/app-store-screenshots）
#   XCODEBUILD       xcodebuild の代わりに使うコマンド（既定は xcodebuild）。空白で区切って引数も渡せる（~ は展開しないので $HOME を使う）。
#                    テストは手元の Simulator で流す前提なので、別の Mac で流すラッパーは使わない
#
set -euo pipefail

cd "$(dirname "$0")/.."

DISPLAY_TYPE="${1:?表示サイズ（例: APP_IPHONE_67）を指定してください}"
LANGUAGES="${2:-}"
SCREENSHOTS_DIR="${SCREENSHOTS_DIR:-build/app-store-screenshots}"
SCREENSHOTS_JSON=docs/app-store/screenshots.json
LANGUAGES_JSON=docs/app-store/languages.json
read -r -a XCODEBUILD_COMMAND <<<"${XCODEBUILD:-xcodebuild}"

if ! jq -e --arg type "$DISPLAY_TYPE" '.displayTypes[$type]' "$SCREENSHOTS_JSON" >/dev/null; then
  echo "表示サイズ ${DISPLAY_TYPE} は ${SCREENSHOTS_JSON} にありません" >&2
  exit 1
fi
EXPECTED_SCREENSHOTS=$(jq -r '.screenshotCount' "$SCREENSHOTS_JSON")
EXPECTED_SIZES=$(jq -r --arg type "$DISPLAY_TYPE" '.displayTypes[$type].sizes | join(" ")' "$SCREENSHOTS_JSON")

# 言語の一覧（language appleLanguage appleLocale をタブ区切り）。指定が無ければ全言語、指定に無い言語があれば止まる
LANGUAGE_LIST=$(jq -r --arg wanted "$LANGUAGES" '
  ($wanted | split(",") | map(select(. != ""))) as $w
  | .languages
  | if ($w | length) == 0 then . else
      (map(.language) as $known | ($w - $known)) as $unknown
      | if ($unknown | length) > 0 then error("languages.json に無い言語: \($unknown | join(","))") else . end
      | map(select(.language as $l | $w | index($l)))
    end
  | .[] | [.language, .appleLanguage, .appleLocale] | @tsv' "$LANGUAGES_JSON")

WORK_DIR=$(mktemp -d)
UDID=""

# 途中で失敗しても、作った Simulator と作業用のディレクトリを消す
cleanup() {
  if [[ -n "$UDID" ]]; then
    xcrun simctl shutdown "$UDID" 2>/dev/null || true
    xcrun simctl delete "$UDID" 2>/dev/null || true
  fi
  rm -rf "$WORK_DIR"
}
trap cleanup EXIT

# MARK: - Simulator

SDK_VERSION=$(xcrun --sdk iphonesimulator --show-sdk-version)

# ビルドに使う SDK より新しいランタイム（ベータなど）には入れられないので、SDK 以下でいちばん新しいものを使う
latest_runtime() {
  xcrun simctl list -j runtimes | jq -r --arg sdk "$SDK_VERSION" '
    def ver: split(".") | map(tonumber);
    [.runtimes[] | select(.isAvailable and (.identifier | contains("SimRuntime.iOS")))
      | select((.version | ver)[:2] <= ($sdk | ver)[:2])]
    | sort_by(.version | ver) | last | .identifier // empty'
}

# SDK と同じ版のランタイムがあるか（新しい機種は新しいランタイムにしか無い。iPhone Duo には iOS 27.1 が要る）
has_sdk_runtime() {
  xcrun simctl list -j runtimes | jq -e --arg sdk "$SDK_VERSION" '
    def ver: split(".") | map(tonumber);
    any(.runtimes[]; .isAvailable and (.identifier | contains("SimRuntime.iOS")) and (.version | ver)[:2] == ($sdk | ver)[:2])' >/dev/null
}

# ランナーのイメージには、選んだ Xcode の SDK と同じ版のランタイムが入っていないことがある
# （xcode-27 のイメージは iOS 27.0 だけ）ので、無ければダウンロードする
if ! has_sdk_runtime; then
  echo "iOS ${SDK_VERSION} のランタイムが無いのでダウンロードします"
  xcodebuild -downloadPlatform iOS
fi
RUNTIME_ID=$(latest_runtime)
if [[ -z "$RUNTIME_ID" ]]; then
  echo "iOS ${SDK_VERSION} 以下のランタイムがありません" >&2
  xcrun simctl list runtimes >&2 || true
  exit 1
fi
# macOS の bash 3.2 は、変数名の直後に全角文字が続くと変数名の一部と見なすことがあるので、必ず波括弧で閉じる
echo "ランタイム: ${RUNTIME_ID}（SDK ${SDK_VERSION}）"

DEVICE_NAME=""
while IFS= read -r -u 3 candidate; do
  device_type=$(xcrun simctl list -j devicetypes | jq -r --arg name "$candidate" '.devicetypes[] | select(.name == $name) | .identifier' | head -n 1)
  if [[ -n "$device_type" ]] && UDID=$(xcrun simctl create "OshiCon-Screenshot-${DISPLAY_TYPE}" "$device_type" "$RUNTIME_ID" 2>/dev/null); then
    DEVICE_NAME="$candidate"
    break
  fi
  UDID=""
done 3< <(jq -r --arg type "$DISPLAY_TYPE" '.displayTypes[$type].devices[]' "$SCREENSHOTS_JSON")

if [[ -z "$UDID" ]]; then
  echo "${DISPLAY_TYPE} の Simulator を作れませんでした。${SCREENSHOTS_JSON} の devices を見直してください" >&2
  xcrun simctl list devicetypes >&2 || true
  exit 1
fi
echo "機種: ${DEVICE_NAME}（${UDID}）"

boot() {
  xcrun simctl boot "$UDID" 2>/dev/null || true
  xcrun simctl bootstatus "$UDID" -b >/dev/null
  xcrun simctl ui "$UDID" appearance light
  xcrun simctl status_bar "$UDID" override \
    --time 9:41 --dataNetwork wifi --wifiMode active --wifiBars 3 \
    --cellularMode active --cellularBars 4 --batteryState charged --batteryLevel 100
}

# iPad のステータスバーには日付も出る。日付は Simulator 全体の言語・地域に従うので、言語ごとに設定して起動し直す
set_device_language() {
  xcrun simctl spawn "$UDID" defaults write -g AppleLanguages -array "$1"
  xcrun simctl spawn "$UDID" defaults write -g AppleLocale -string "$2"
  xcrun simctl shutdown "$UDID"
  boot
}

# MARK: - ビルド

# Simulator を起動したままビルドすると、非力なランナーが固まることがあるので、ビルドしてから起動する
DERIVED_DATA="$WORK_DIR/DerivedData"
"${XCODEBUILD_COMMAND[@]}" build-for-testing \
  -project OshiCon.xcodeproj \
  -scheme OshiCon \
  -destination "platform=iOS Simulator,id=${UDID}" \
  -derivedDataPath "$DERIVED_DATA" \
  -quiet
boot

# MARK: - 撮影

run_tests() {
  TEST_RUNNER_APP_STORE_SCREENSHOTS=1 \
    TEST_RUNNER_APP_STORE_LANGUAGE="$2" \
    TEST_RUNNER_APP_STORE_LOCALE="$3" \
    "${XCODEBUILD_COMMAND[@]}" test-without-building \
    -project OshiCon.xcodeproj \
    -scheme OshiCon \
    -destination "platform=iOS Simulator,id=${UDID}" \
    -derivedDataPath "$DERIVED_DATA" \
    -only-testing:OshiConUITests/AppStoreScreenshotTests \
    -resultBundlePath "$1"
}

while IFS=$'\t' read -r -u 3 language apple_language apple_locale; do
  echo "==> ${DISPLAY_TYPE} / ${language}"
  if [[ "$DISPLAY_TYPE" == APP_IPAD* ]]; then
    set_device_language "$apple_language" "$apple_locale"
  fi

  # CI の Simulator は、スクリーンショットの取得がタイムアウトすることがあるので、1 回だけやり直す
  result="$WORK_DIR/${language}.xcresult"
  if ! run_tests "$result" "$apple_language" "$apple_locale"; then
    echo "::warning::${DISPLAY_TYPE} / ${language} の撮影に失敗したので、やり直します"
    rm -rf "$result"
    run_tests "$result" "$apple_language" "$apple_locale"
  fi

  # 前の実行の画像が溜まらないよう、言語ごとに作り直す
  destination="$SCREENSHOTS_DIR/$DISPLAY_TYPE/$language"
  rm -rf "${destination:?}"
  mkdir -p "$destination"
  xcrun xcresulttool export attachments --path "$result" --output-path "$destination"

  # テストが飛ばされた（環境変数が渡らなかった）ときも xcodebuild は成功で終わるので、撮れた枚数を確かめる
  count=0
  if [[ -f "$destination/manifest.json" ]]; then
    count=$(jq '[.[].attachments | length] | add // 0' "$destination/manifest.json")
  fi
  if [[ "$count" -ne "$EXPECTED_SCREENSHOTS" ]]; then
    echo "${DISPLAY_TYPE} / ${language} のスクリーンショットが ${count} 枚でした（${EXPECTED_SCREENSHOTS} 枚のはず）。テストが飛ばされていないか確かめてください" >&2
    exit 1
  fi

  # App Store Connect は寸法が 1px でも違えば弾くので、撮った時点で確かめる
  for image in "$destination"/*.png; do
    size=$(sips -g pixelWidth -g pixelHeight "$image" | awk '/pixelWidth/ { w = $2 } /pixelHeight/ { h = $2 } END { print w "x" h }')
    if [[ " $EXPECTED_SIZES " != *" $size "* ]]; then
      echo "$(basename "$image") の寸法が ${size} でした（${EXPECTED_SIZES} のどれかのはず）" >&2
      exit 1
    fi
  done
  echo "    ${destination} に ${count} 枚を書き出しました（manifest.json に画面の名前があります）"
done 3< <(printf '%s\n' "$LANGUAGE_LIST")
