#!/bin/bash
#
# App Store のクリエイティブアセット（プロダクトページのヘッダー / 検索結果）を言語ごとに書き出す。
#
# 使い方:
#   scripts/render-creative-assets.sh <6.9 インチのスクリーンショットのフォルダ> [出力先] [言語（カンマ区切り）]
#   scripts/render-creative-assets.sh build/app-store-screenshots/APP_IPHONE_67
#
# 元は docs/app-store/creative/creative.html。画面の画像には scripts/app-store-screenshots.sh APP_IPHONE_67 の出力
# （<言語>/ に画像と manifest.json）を使う。Google Chrome をヘッドレスで開いて実寸で撮り、透過を落として
# <出力先>/<言語>/header.png・search_results.png に書き出す（出力先の既定は build/creative-assets）。
# アプリ名は docs/app-store/metadata/<言語>.md の「## アプリ名」から読む。アイコンは Icon Composer の ictool で書き出す（無ければ載せない）。
#
# 寸法: ヘッダーは 21:9（3840x1646）、検索結果は 3:2（3840x2560）。どちらも透過なし
# 仕様: https://developer.apple.com/help/app-store-connect/reference/app-information/creative-assets-specifications
#
set -euo pipefail

cd "$(dirname "$0")/.."

SCREENSHOTS="${1:?6.9 インチのスクリーンショットのフォルダ（例: build/app-store-screenshots/APP_IPHONE_67）を指定してください}"
OUTPUT_DIR="${2:-build/creative-assets}"
LANGUAGES="${3:-}"
CHROME="${CHROME:-/Applications/Google Chrome.app/Contents/MacOS/Google Chrome}"
HTML=docs/app-store/creative/creative.html

if [[ ! -x "$CHROME" ]]; then
  echo "Google Chrome が見つかりません（CHROME で場所を指定できます）: ${CHROME}" >&2
  exit 1
fi

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT
cp "$HTML" "$WORK/"

# xcode-select -p は Xcode.app/Contents/Developer を返す。Icon Composer は 1 つ上の Contents/Applications にある
ictool="$(xcode-select -p)/../Applications/Icon Composer.app/Contents/Executables/ictool"
if [[ -x "$ictool" ]]; then
  "$ictool" OshiCon/AppIcon.icon --export-image --output-file "$WORK/icon.png" \
    --platform iOS --rendition Default --width 1024 --height 1024 --scale 1 >/dev/null
else
  echo "::warning::ictool が見つからないので、アイコンを載せずに書き出します: ${ictool}"
fi

# 書き出す種類: <type> <ファイル名> <幅> <高さ>
TARGETS="header header.png 3840 1646
search search_results.png 3840 2560"

# 「## アプリ名」の下のコードブロックの 1 行目
app_name() {
  awk '/^## アプリ名/ { found = 1; next } found && /^```/ { if (inside) exit; inside = 1; next } inside { print; exit }' "$1"
}

while IFS= read -r -u 3 language; do
  # creative.html の copy に、その言語の文言が無いと崩れた画像になる
  if ! grep -Eq "^    \"?${language}\"?: \{" "$HTML"; then
    echo "${HTML} の copy に ${language} の文言がありません" >&2
    exit 1
  fi
  manifest="$SCREENSHOTS/$language/manifest.json"
  if [[ ! -f "$manifest" ]]; then
    echo "${manifest} がありません。先に scripts/app-store-screenshots.sh APP_IPHONE_67 で撮ってください" >&2
    exit 1
  fi

  # 書き出したファイル名は UUID なので、添付の名前（「01-ホーム_0_…」）の順に 01.png〜 として並べる
  mkdir -p "$WORK/screens/$language"
  index=0
  while IFS= read -r file; do
    index=$((index + 1))
    cp "$SCREENSHOTS/$language/$file" "$WORK/screens/$language/$(printf '%02d' "$index").png"
  done < <(jq -r '[.[].attachments[]] | sort_by(.suggestedHumanReadableName) | .[].exportedFileName' "$manifest")

  metadata="docs/app-store/metadata/$language.md"
  [[ -f "$metadata" ]] || metadata=docs/app-store/listing.md
  name=$(app_name "$metadata")
  query_name=$(jq -rn --arg v "$name" '$v | @uri')

  mkdir -p "$OUTPUT_DIR/$language"
  # Chrome には絶対パスで渡す
  output_dir=$(cd "$OUTPUT_DIR/$language" && pwd)
  while read -r type file width height; do
    output="$output_dir/$file"
    "$CHROME" --headless=new --disable-gpu --hide-scrollbars --force-device-scale-factor=1 \
      --allow-file-access-from-files --virtual-time-budget=3000 \
      --window-size="$width,$height" --screenshot="$output.raw.png" \
      "file://$WORK/creative.html?type=$type&lang=$language&name=$query_name" >/dev/null 2>&1
    # 透過を落とす（JPEG を経由して PNG に戻す）
    sips -s format jpeg -s formatOptions 100 "$output.raw.png" --out "$WORK/flat.jpg" >/dev/null
    sips -s format png "$WORK/flat.jpg" --out "$output" >/dev/null
    rm -f "$output.raw.png"
    actual=$(sips -g pixelWidth -g pixelHeight "$output" | awk '/pixelWidth/ { w = $2 } /pixelHeight/ { h = $2 } END { print w "x" h }')
    if [[ "$actual" != "${width}x${height}" ]]; then
      echo "${output} の寸法が ${width}x${height} ではありません（${actual}）" >&2
      exit 1
    fi
    echo "${output}（${actual}）"
  done <<<"$TARGETS"
done 3< <(
  if [[ -n "$LANGUAGES" ]]; then
    tr ',' '\n' <<<"$LANGUAGES"
  else
    # 撮ってある言語だけ書き出す
    find "$SCREENSHOTS" -mindepth 2 -maxdepth 2 -name manifest.json | awk -F/ '{ print $(NF-1) }' | sort
  fi
)
