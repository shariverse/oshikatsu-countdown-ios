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
#   XCODEBUILD  xcodebuild の代わりに使うコマンド（既定は xcodebuild）。空白で区切って引数も渡せる（~ は展開しないので $HOME を使う）。
#               テストは手元の Simulator で流す前提なので、別の Mac で流すラッパーは使わない
#   DEVICES     撮る Simulator の名前を改行で区切って並べる（既定は下の DEFAULT_DEVICES）
#
set -euo pipefail

cd "$(dirname "$0")/.."

OUTPUT_DIR=${1:-build/app-store-screenshots}
DEFAULT_DEVICES=$'iPhone 17 Pro Max\niPad Pro 13-inch (M5)'
# 撮る画面の数（AppStoreScreenshotTests の capture の数）
EXPECTED_SCREENSHOTS=4
read -r -a XCODEBUILD_COMMAND <<<"${XCODEBUILD:-xcodebuild}"

mkdir -p "$OUTPUT_DIR"
WORK_DIR=$(mktemp -d)
OVERRIDDEN_UDIDS=()

# 途中で失敗しても、ステータスバーの上書きを戻して作業用のディレクトリを消す
cleanup() {
  for udid in ${OVERRIDDEN_UDIDS[@]+"${OVERRIDDEN_UDIDS[@]}"}; do
    xcrun simctl status_bar "$udid" clear 2>/dev/null || true
  done
  rm -rf "$WORK_DIR"
}
trap cleanup EXIT

# 同じ名前の端末が複数のランタイムにあるときは、いちばん新しい iOS のものを選ぶ
find_udid() {
  xcrun simctl list devices available -j | jq -r --arg name "$1" '
    .devices | to_entries
    | map(select(.key | contains("SimRuntime.iOS")))
    | sort_by(.key | capture("iOS-(?<maj>[0-9]+)-(?<min>[0-9]+)") | [(.maj | tonumber), (.min | tonumber)])
    | reverse
    | map(.value[] | select(.name == $name))
    | .[0].udid // empty'
}

while IFS= read -r device; do
  [[ -z "$device" ]] && continue
  udid=$(find_udid "$device")
  if [[ -z "$udid" ]]; then
    echo "Simulator「${device}」が見つかりません。xcrun simctl list devices available で名前を確かめてください" >&2
    exit 1
  fi

  echo "==> ${device}（${udid}）"
  xcrun simctl boot "$udid" 2>/dev/null || true
  xcrun simctl bootstatus "$udid" -b >/dev/null
  xcrun simctl ui "$udid" appearance light
  OVERRIDDEN_UDIDS+=("$udid")
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

  # 前の実行の画像が溜まらないよう、端末ごとに作り直す
  device_dir="$OUTPUT_DIR/$device"
  rm -rf "${device_dir:?}"
  mkdir -p "$device_dir"
  xcrun xcresulttool export attachments --path "$result" --output-path "$device_dir"

  # テストが飛ばされた（環境変数が渡らなかった）ときも xcodebuild は成功で終わるので、撮れた枚数を確かめる
  count=$(jq '[.[].attachments | length] | add // 0' "$device_dir/manifest.json")
  if [[ "$count" -ne "$EXPECTED_SCREENSHOTS" ]]; then
    echo "${device} のスクリーンショットが ${count} 枚でした（${EXPECTED_SCREENSHOTS} 枚のはず）。テストが飛ばされていないか確かめてください" >&2
    exit 1
  fi
  echo "    ${device_dir} に ${count} 枚を書き出しました（manifest.json に画面の名前があります）"
done <<<"${DEVICES:-$DEFAULT_DEVICES}"
