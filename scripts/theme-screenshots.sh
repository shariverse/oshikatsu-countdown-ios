#!/bin/bash
#
# テーマ案の見本を、ライトとダークで撮る（README の「テーマの見本」）。
# アプリの画面（ホーム・予定の詳細・予定の追加）は UI テスト ThemeScreenshotTests が DEBUG の起動引数 -previewTheme で、
# ウィジェット 2 種は Unit テスト ThemeWidgetScreenshotTests がウィジェットの大きさの枠で撮り、画像を出力先に書き出す。
#
# 使い方:
#   scripts/theme-screenshots.sh <テーマの id> <Simulator の UDID>
#   scripts/theme-screenshots.sh standard 9B5AF7FD-96D2-4113-916C-B2261D99ED0C
#
# Simulator は手元のもの（言語を日本語にしたもの）を使う。外観を切り替え、ステータスバーを 9:41 にそろえて撮り、終わったらライトと元のステータスバーに戻す。
#
# 出力先: $SCREENSHOTS_DIR/<テーマの id>/<light|dark>/（画像と manifest.json。既定は build/theme-screenshots）
#
# 環境変数:
#   SCREENSHOTS_DIR   出力先（既定は build/theme-screenshots）
#   DERIVED_DATA_PATH xcodebuild の -derivedDataPath（既定は xcodebuild の既定の場所）
#
set -euo pipefail

cd "$(dirname "$0")/.."

THEME_ID="${1:?テーマの id（例: standard）を指定してください}"
UDID="${2:?Simulator の UDID を指定してください（xcrun simctl list devices available）}"
SCREENSHOTS_DIR="${SCREENSHOTS_DIR:-build/theme-screenshots}"
DERIVED_DATA_ARGS=()
if [[ -n "${DERIVED_DATA_PATH:-}" ]]; then
  DERIVED_DATA_ARGS=(-derivedDataPath "$DERIVED_DATA_PATH")
fi

WORK_DIR=$(mktemp -d)

cleanup() {
  xcrun simctl ui "$UDID" appearance light 2>/dev/null || true
  xcrun simctl status_bar "$UDID" clear 2>/dev/null || true
  rm -rf "$WORK_DIR"
}
trap cleanup EXIT

xcrun simctl boot "$UDID" 2>/dev/null || true
xcrun simctl bootstatus "$UDID" -b >/dev/null
xcrun simctl status_bar "$UDID" override --time 9:41 --batteryState charged --batteryLevel 100 --cellularBars 4 --wifiBars 3

for appearance in light dark; do
  xcrun simctl ui "$UDID" appearance "$appearance"
  out="${SCREENSHOTS_DIR}/${THEME_ID}/${appearance}"
  result="${WORK_DIR}/${appearance}.xcresult"
  rm -rf "$out"
  mkdir -p "$out"
  echo "テーマ ${THEME_ID} を ${appearance} で撮ります"
  TEST_RUNNER_THEME_SCREENSHOTS=1 TEST_RUNNER_THEME_ID="$THEME_ID" xcodebuild test \
    -project OshiCon.xcodeproj -scheme OshiCon \
    -destination "platform=iOS Simulator,id=${UDID}" \
    "${DERIVED_DATA_ARGS[@]+"${DERIVED_DATA_ARGS[@]}"}" \
    -parallel-testing-enabled NO \
    -only-testing:OshiConUITests/ThemeScreenshotTests \
    -only-testing:OshiConTests/ThemeWidgetScreenshotTests \
    -resultBundlePath "$result" \
    -skipPackagePluginValidation -skipMacroValidation CODE_SIGNING_ALLOWED=NO \
    >"${WORK_DIR}/${appearance}.log" 2>&1 || {
      tail -40 "${WORK_DIR}/${appearance}.log" >&2
      exit 1
    }
  xcrun xcresulttool export attachments --path "$result" --output-path "$out" >/dev/null
  echo "書き出しました: ${out}（$(find "$out" -name '*.png' | wc -l | tr -d ' ') 枚）"
done
