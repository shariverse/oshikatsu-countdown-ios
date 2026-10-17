#!/bin/bash
#
# App Store 用スクリーンショットを撮る。
# 見本の推しと予定で UI テスト（AppStoreScreenshotTests）を 6.9 インチの iPhone と 13 インチの iPad で流し、
# 撮った画像を出力先に書き出す。ステータスバーは 9:41・電池満タンにそろえる。
#
# 使い方:
#   scripts/app-store-screenshots.sh [出力先（既定は build/app-store-screenshots）]
#
# 環境変数:
#   XCODEBUILD  xcodebuild の代わりに使うコマンド（既定は xcodebuild）。空白で区切って引数も渡せる
#   DEVICES     撮る Simulator の名前を改行で区切って並べる（既定は下の DEFAULT_DEVICES）
#
set -euo pipefail

cd "$(dirname "$0")/.."

OUTPUT_DIR=${1:-build/app-store-screenshots}
DEFAULT_DEVICES=$'iPhone 17 Pro Max\niPad Pro 13-inch (M5)'
read -r -a XCODEBUILD_COMMAND <<<"${XCODEBUILD:-xcodebuild}"

mkdir -p "$OUTPUT_DIR"
WORK_DIR=$(mktemp -d)
trap 'rm -rf "$WORK_DIR"' EXIT

while IFS= read -r device; do
  [[ -z "$device" ]] && continue
  udid=$(xcrun simctl list devices available -j |
    jq -r --arg name "$device" '[.devices[][] | select(.name == $name)][0].udid // empty')
  if [[ -z "$udid" ]]; then
    echo "Simulator「${device}」が見つかりません。xcrun simctl list devices available で名前を確かめてください" >&2
    exit 1
  fi

  echo "==> ${device}（${udid}）"
  xcrun simctl boot "$udid" 2>/dev/null || true
  xcrun simctl bootstatus "$udid" -b >/dev/null
  xcrun simctl ui "$udid" appearance light
  xcrun simctl status_bar "$udid" override \
    --time 9:41 --dataNetwork wifi --wifiMode active --wifiBars 3 \
    --cellularMode active --cellularBars 4 --batteryState charged --batteryLevel 100

  result="$WORK_DIR/${udid}.xcresult"
  TEST_RUNNER_APP_STORE_SCREENSHOTS=1 "${XCODEBUILD_COMMAND[@]}" test \
    -project OshiCon.xcodeproj \
    -scheme OshiCon \
    -destination "platform=iOS Simulator,id=${udid}" \
    -only-testing:OshiConUITests/AppStoreScreenshotTests \
    -resultBundlePath "$result"

  device_dir="$OUTPUT_DIR/$device"
  mkdir -p "$device_dir"
  xcrun xcresulttool export attachments --path "$result" --output-path "$device_dir"
  xcrun simctl status_bar "$udid" clear
  echo "    ${device_dir} に書き出しました（manifest.json に画面の名前があります）"
done <<<"${DEVICES:-$DEFAULT_DEVICES}"
