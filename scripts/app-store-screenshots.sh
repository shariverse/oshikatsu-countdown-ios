#!/bin/bash
#
# App Store 用スクリーンショット（10 枚）を、1 つの表示サイズについて言語ごとに書き出す。
#
#   1. 撮る: 見本の推しと予定で UI テスト（AppStoreScreenshotTests）を流し、アプリの画面・ホーム画面・ロック画面を撮る
#      （ステータスバーは電池満タン・時刻は上書きしない、外観はダーク。端末の言語もその言語にする）
#   2. 描き出す: Unit テスト（AppStoreSurfaceRenderingTests）で、ウィジェット・ロック画面のアクセサリ・通知を本物の View から PNG に描き出す
#   3. 重ねる: scripts/render-app-store-screenshots.sh で、見出し・地・端末の枠を付けて 01.png〜10.png にする
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
# 出力先: $SCREENSHOTS_DIR/<表示サイズ>/<言語>/（既定は build/app-store-screenshots）
#   01.png〜10.png  App Store に載せる画像（App Store Metadata のワークフローが登録する）
#   raw/            撮った画面と manifest.json（クリエイティブアセットの元にもする）
#   surfaces/       描き出したウィジェット・ロック画面のアクセサリ・通知
#
# 環境変数:
#   SCREENSHOTS_DIR  出力先（既定は build/app-store-screenshots）
#   XCODEBUILD       xcodebuild の代わりに使うコマンド（既定は xcodebuild）。空白で区切って引数も渡せる（~ は展開しないので $HOME を使う）。
#                    テストは手元の Simulator で流す前提なので、別の Mac で流すラッパーは使わない
#   CHROME           重ねるのに使う Google Chrome（scripts/render-app-store-screenshots.sh）
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
EXPECTED_SIZES=$(jq -r --arg type "$DISPLAY_TYPE" '.displayTypes[$type].sizes | join(" ")' "$SCREENSHOTS_JSON")

# 描き出すウィジェット・ロック画面のアクセサリと通知の数（AppStoreSurfaceRenderingTests）
EXPECTED_SURFACES=11

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

# ビルドに使う SDK より新しいランタイム（ベータなど）には入れられないので、SDK 以下で、その機種を作れるいちばん新しいものを使う
# （iOS 27.1 のランタイムは iPhone Duo しか作れないので、ほかの機種は iOS 27.0 などで作る）
latest_runtime() {
  xcrun simctl list -j runtimes | jq -r --arg sdk "$SDK_VERSION" --arg type "$1" '
    def ver: split(".") | map(tonumber);
    [.runtimes[] | select(.isAvailable and (.identifier | contains("SimRuntime.iOS")))
      | select((.version | ver)[:2] <= ($sdk | ver)[:2])
      | select(any(.supportedDeviceTypes[]?; .identifier == $type))]
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

DEVICE_NAME=""
while IFS= read -r -u 3 candidate; do
  device_type=$(xcrun simctl list -j devicetypes | jq -r --arg name "$candidate" '.devicetypes[] | select(.name == $name) | .identifier' | head -n 1)
  [[ -n "$device_type" ]] || continue
  RUNTIME_ID=$(latest_runtime "$device_type")
  if [[ -n "$RUNTIME_ID" ]] && UDID=$(xcrun simctl create "OshiCon-Screenshot-${DISPLAY_TYPE}" "$device_type" "$RUNTIME_ID" 2>/dev/null); then
    DEVICE_NAME="$candidate"
    break
  fi
  UDID=""
done 3< <(jq -r --arg type "$DISPLAY_TYPE" '.displayTypes[$type].devices[]' "$SCREENSHOTS_JSON")

if [[ -z "$UDID" ]]; then
  echo "${DISPLAY_TYPE} の Simulator を作れませんでした（SDK ${SDK_VERSION} 以下のランタイム）。${SCREENSHOTS_JSON} の devices を見直してください" >&2
  xcrun simctl list devicetypes >&2 || true
  xcrun simctl list runtimes >&2 || true
  exit 1
fi
# macOS の bash 3.2 は、変数名の直後に全角文字が続くと変数名の一部と見なすことがあるので、必ず波括弧で閉じる
echo "機種: ${DEVICE_NAME}（${UDID}）・ランタイム: ${RUNTIME_ID}（SDK ${SDK_VERSION}）"

boot() {
  xcrun simctl boot "$UDID" 2>/dev/null || true
  xcrun simctl bootstatus "$UDID" -b >/dev/null
  # アプリの画面・ホーム画面・ロック画面はダークで撮る（推し色のテーマとライトのホームは、アプリが起動引数で外観を固定する）
  xcrun simctl ui "$UDID" appearance dark
}

# アプリの中の画面は、ステータスバーの電波・電池をそろえる。時刻は上書きしない（9:41 では、当日の配信の開始の時刻と合わないため）
override_status_bar() {
  xcrun simctl status_bar "$UDID" override \
    --operatorName "" --dataNetwork wifi --wifiMode active --wifiBars 3 \
    --cellularMode active --cellularBars 4 --batteryState charged --batteryLevel 100
}

# ステータスバーを上書きしていると、ロック画面の日付が 1 月 1 日になるので、アプリの外の面は上書きを外して撮る
clear_status_bar() {
  xcrun simctl status_bar "$UDID" clear
}

# ホーム画面のアプリ名・ロック画面の日付・iPad のステータスバーの日付は、Simulator 全体の言語・地域に従うので、言語ごとに設定して起動し直す。
# 起動し直すと、前の言語で出したライブアクティビティ・通知やロックの状態も残らない
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

# $1: 結果の xcresult、$2・$3: 言語と地域、$4: 流すテスト（AppStoreScreenshotTests のメソッド）
run_tests() {
  TEST_RUNNER_APP_STORE_SCREENSHOTS=1 \
    TEST_RUNNER_APP_STORE_LANGUAGE="$2" \
    TEST_RUNNER_APP_STORE_LOCALE="$3" \
    "${XCODEBUILD_COMMAND[@]}" test-without-building \
    -project OshiCon.xcodeproj \
    -scheme OshiCon \
    -destination "platform=iOS Simulator,id=${UDID}" \
    -derivedDataPath "$DERIVED_DATA" \
    -parallel-testing-enabled NO \
    -only-testing:"OshiConUITests/AppStoreScreenshotTests/$4" \
    -resultBundlePath "$1"
}

# 1 つのテスト（$5）を流し、撮った画面を $6 に書き出す。CI の Simulator は、スクリーンショットの取得がタイムアウトすることがあるので、1 回だけやり直す
capture() {
  local result="$1" language="$2" apple_language="$3" apple_locale="$4" test="$5" output="$6"
  if ! run_tests "$result" "$apple_language" "$apple_locale" "$test"; then
    echo "::warning::${DISPLAY_TYPE} / ${language} / ${test} の撮影に失敗したので、やり直します"
    rm -rf "$result"
    set_device_language "$apple_language" "$apple_locale"
    if [[ "$test" == testCaptureScreensInApp ]]; then
      override_status_bar
    else
      clear_status_bar
    fi
    run_tests "$result" "$apple_language" "$apple_locale" "$test"
  fi
  mkdir -p "$output"
  xcrun xcresulttool export attachments --path "$result" --output-path "$output"
}

# ウィジェットの View は文言と日付をアプリの言語で出すので、テストのホストのアプリの言語と地域を替えて流す
render_surfaces() {
  TEST_RUNNER_APP_STORE_SURFACES_DIR="$1" \
    "${XCODEBUILD_COMMAND[@]}" test-without-building \
    -project OshiCon.xcodeproj \
    -scheme OshiCon \
    -destination "platform=iOS Simulator,id=${UDID}" \
    -derivedDataPath "$DERIVED_DATA" \
    -parallel-testing-enabled NO \
    -only-testing:OshiConTests/AppStoreSurfaceRenderingTests \
    -testLanguage "$2" \
    -testRegion "$3" \
    -resultBundlePath "$4"
}

while IFS=$'\t' read -r -u 3 language apple_language apple_locale; do
  echo "==> ${DISPLAY_TYPE} / ${language}"
  set_device_language "$apple_language" "$apple_locale"

  # 前の実行の画像が溜まらないよう、言語ごとに作り直す
  destination="$SCREENSHOTS_DIR/$DISPLAY_TYPE/$language"
  rm -rf "${destination:?}"
  mkdir -p "$destination/raw" "$destination/surfaces"

  # ウィジェットなどの描き出しを先にする（UI テストの後は撮影のアプリが動いたままで、テストのホストが起動しきれず止まることがあった）。
  # 重いランナーでも起動しきれないことがあるので、1 回だけやり直す
  surfaces_result="$WORK_DIR/${language}-surfaces.xcresult"
  if ! render_surfaces "$(cd "$destination/surfaces" && pwd)" "$apple_language" "${apple_locale#*_}" "$surfaces_result"; then
    echo "::warning::${DISPLAY_TYPE} / ${language} のウィジェットの描き出しに失敗したので、やり直します"
    rm -rf "$surfaces_result"
    render_surfaces "$(cd "$destination/surfaces" && pwd)" "$apple_language" "${apple_locale#*_}" "$surfaces_result"
  fi
  count=$(find "$destination/surfaces" -name '*.png' | wc -l | tr -d ' ')
  if [[ "$count" -ne "$EXPECTED_SURFACES" ]]; then
    echo "${DISPLAY_TYPE} / ${language} のウィジェットが ${count} 個でした（${EXPECTED_SURFACES} 個のはず）。テストが飛ばされていないか確かめてください" >&2
    exit 1
  fi

  # アプリの中の画面（ステータスバーをそろえる）→ アプリの外の面（上書きを外す）の順に撮り、添付を raw/ に集める
  override_status_bar
  capture "$WORK_DIR/${language}-app.xcresult" "$language" "$apple_language" "$apple_locale" testCaptureScreensInApp "$WORK_DIR/${language}-app"
  clear_status_bar
  capture "$WORK_DIR/${language}-outside.xcresult" "$language" "$apple_language" "$apple_locale" testCaptureSurfacesOutsideApp "$WORK_DIR/${language}-outside"
  for part in app outside; do
    find "$WORK_DIR/${language}-${part}" -type f ! -name manifest.json -exec cp {} "$destination/raw/" \;
  done
  jq -s 'add' "$WORK_DIR/${language}-app/manifest.json" "$WORK_DIR/${language}-outside/manifest.json" >"$destination/raw/manifest.json"

  # テストが飛ばされた（環境変数が渡らなかった）ときも xcodebuild は成功で終わるので、撮れたかを確かめる
  if [[ ! -f "$destination/raw/manifest.json" ]] || [[ $(jq '[.[].attachments | length] | add // 0' "$destination/raw/manifest.json") -eq 0 ]]; then
    echo "${DISPLAY_TYPE} / ${language} の画面が撮れていません。テストが飛ばされていないか確かめてください" >&2
    exit 1
  fi

  # App Store Connect は寸法が 1px でも違えば弾くので、撮った時点で確かめる
  for image in "$destination"/raw/*.png; do
    size=$(sips -g pixelWidth -g pixelHeight "$image" | awk '/pixelWidth/ { w = $2 } /pixelHeight/ { h = $2 } END { print w "x" h }')
    if [[ " $EXPECTED_SIZES " != *" $size "* ]]; then
      echo "$(basename "$image") の寸法が ${size} でした（${EXPECTED_SIZES} のどれかのはず）" >&2
      exit 1
    fi
  done

  scripts/render-app-store-screenshots.sh "$destination" "$DISPLAY_TYPE" "$language"
done 3< <(printf '%s\n' "$LANGUAGE_LIST")
