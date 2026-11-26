#!/bin/bash
#
# 撮った画面（UI テストの添付）と描き出したウィジェットから、App Store 用スクリーンショット 10 枚を書き出す。
# 見出し・地・端末の枠を付けるのは docs/app-store/screenshots/screenshots.html（Google Chrome のヘッドレスで実寸で撮る）。
#
# 使い方:
#   scripts/render-app-store-screenshots.sh <言語のフォルダ> <表示サイズ> <言語>
#   scripts/render-app-store-screenshots.sh build/app-store-screenshots/APP_IPHONE_67/ja APP_IPHONE_67 ja
#
# <言語のフォルダ> は scripts/app-store-screenshots.sh の出力（raw/ に撮った画面と manifest.json、surfaces/ に描き出したウィジェット）。
# 書き出す先は同じフォルダの 01.png〜10.png（前に書き出したものは消す）。寸法は撮った画面と同じ（screenshots.json の sizes のどれか）。
# 撮り直さずに見出しだけ直したいときも、これだけを流せばよい。
#
# 環境変数:
#   CHROME  Google Chrome の実行ファイル（既定は /Applications/Google Chrome.app/Contents/MacOS/Google Chrome）
#
set -euo pipefail

cd "$(dirname "$0")/.."

FOLDER="${1:?言語のフォルダ（例: build/app-store-screenshots/APP_IPHONE_67/ja）を指定してください}"
DISPLAY_TYPE="${2:?表示サイズ（例: APP_IPHONE_67）を指定してください}"
LANGUAGE="${3:?言語（例: ja）を指定してください}"
CHROME="${CHROME:-/Applications/Google Chrome.app/Contents/MacOS/Google Chrome}"
SOURCE=docs/app-store/screenshots
SCREENSHOTS_JSON=docs/app-store/screenshots.json
EXPECTED_SCREENSHOTS=$(jq -r '.screenshotCount' "$SCREENSHOTS_JSON")
EXPECTED_SIZES=$(jq -r --arg type "$DISPLAY_TYPE" '.displayTypes[$type].sizes | join(" ")' "$SCREENSHOTS_JSON")

if [[ ! -x "$CHROME" ]]; then
  echo "Google Chrome が見つかりません（CHROME で場所を指定できます）: ${CHROME}" >&2
  exit 1
fi
manifest="$FOLDER/raw/manifest.json"
if [[ ! -f "$manifest" ]]; then
  echo "${manifest} がありません。先に scripts/app-store-screenshots.sh で撮ってください" >&2
  exit 1
fi
# copy.js に、その言語の文言が 10 枚ぶん無いと崩れた画像になる
if ! grep -Eq "^  \"?${LANGUAGE}\"?: \[" "$SOURCE/copy.js"; then
  echo "${SOURCE}/copy.js に ${LANGUAGE} の文言がありません" >&2
  exit 1
fi

case "$DISPLAY_TYPE" in
  APP_IPAD*) DEVICE=ipad ;;
  APP_IPHONE_DUO) DEVICE=duo ;;
  *) DEVICE=iphone ;;
esac

WORK=$(mktemp -d)
# 描けなかったときは、Chrome で開いて確かめられるよう作業用のフォルダを残す
trap 'status=$?; if [[ $status -eq 0 ]]; then rm -rf "$WORK"; else echo "作業用のフォルダを残しました: ${WORK}" >&2; fi' EXIT
cp "$SOURCE/screenshots.html" "$SOURCE/copy.js" "$WORK/"
mkdir -p "$WORK/raw" "$WORK/surfaces" "$WORK/fonts"
cp Shared/Resources/Fonts/KaiseiDecol-Bold.ttf Shared/Resources/Fonts/KaiseiDecol-Regular.ttf Shared/Resources/Fonts/Outfit-Variable.ttf "$WORK/fonts/"
cp "$FOLDER"/surfaces/*.png "$WORK/surfaces/"

# 書き出したファイル名は UUID なので、添付の名前（「detail_0_<UUID>.png」）の頭を名前にして並べ直す
while IFS=$'\t' read -r name file; do
  base="${name%%_[0-9]*_*}"
  case "$file" in
    *.png) cp "$FOLDER/raw/$file" "$WORK/raw/$base.png" ;;
    *.json) { printf 'window.HOME_LAYOUT = '; cat "$FOLDER/raw/$file"; printf ';\n'; } >"$WORK/raw/layout.js" ;;
  esac
done < <(jq -r '.[].attachments[] | [.suggestedHumanReadableName, .exportedFileName] | @tsv' "$manifest")

# 書き出す寸法は撮った画面と同じ
size=$(sips -g pixelWidth -g pixelHeight "$WORK/raw/detail.png" | awk '/pixelWidth/ { w = $2 } /pixelHeight/ { h = $2 } END { print w "x" h }')
if [[ " $EXPECTED_SIZES " != *" $size "* ]]; then
  echo "撮った画面の寸法が ${size} でした（${EXPECTED_SIZES} のどれかのはず）" >&2
  exit 1
fi
width="${size%x*}"
height="${size#*x}"

rm -f "$FOLDER"/[0-9][0-9].png
output_dir=$(cd "$FOLDER" && pwd)
for slide in $(seq 1 "$EXPECTED_SCREENSHOTS"); do
  output="$output_dir/$(printf '%02d' "$slide").png"
  url="file://$WORK/screenshots.html?slide=$slide&lang=$LANGUAGE&device=$DEVICE"
  chrome_flags=(--headless=new --disable-gpu --hide-scrollbars --force-device-scale-factor=1
    --allow-file-access-from-files --virtual-time-budget=8000 --window-size="$width,$height")
  # 画面や文言が足りないと、HTML は赤い文字のエラーを描くだけなので、描き終えた印（data-ready）を先に確かめる。
  # マシンが重いと、画像を読み終える前に Chrome が DOM を書き出すことがあるので、3 回まで試す
  ready=false
  for _ in 1 2 3; do
    if "$CHROME" "${chrome_flags[@]}" --dump-dom "$url" 2>/dev/null | grep -q 'data-ready="true"'; then
      ready=true
      break
    fi
  done
  if [[ "$ready" != true ]]; then
    echo "${slide} 枚目（${LANGUAGE}）を描けませんでした。Chrome で ${url} を開いてエラーを確かめてください" >&2
    exit 1
  fi
  # Chrome は大きな画面（iPad）で、何も言わずに落ちることがあるので、書き出せるまで 3 回まで試す
  rm -f "$WORK/raw-output.png"
  for _ in 1 2 3; do
    if "$CHROME" "${chrome_flags[@]}" --screenshot="$WORK/raw-output.png" "$url" >/dev/null 2>&1 && [[ -s "$WORK/raw-output.png" ]]; then
      break
    fi
    rm -f "$WORK/raw-output.png"
  done
  if [[ ! -s "$WORK/raw-output.png" ]]; then
    echo "${slide} 枚目（${LANGUAGE}）を Chrome で書き出せませんでした: ${url}" >&2
    exit 1
  fi
  # 透過を落とす（JPEG を経由して PNG に戻す。App Store Connect は透過のある画像を受け付けない）
  sips -s format jpeg -s formatOptions 100 "$WORK/raw-output.png" --out "$WORK/flat.jpg" >/dev/null
  sips -s format png "$WORK/flat.jpg" --out "$output" >/dev/null
  actual=$(sips -g pixelWidth -g pixelHeight "$output" | awk '/pixelWidth/ { w = $2 } /pixelHeight/ { h = $2 } END { print w "x" h }')
  if [[ "$actual" != "$size" ]]; then
    echo "${output} の寸法が ${size} ではありません（${actual}）" >&2
    exit 1
  fi
done
echo "    ${FOLDER} に ${EXPECTED_SCREENSHOTS} 枚を書き出しました（${size}）"
