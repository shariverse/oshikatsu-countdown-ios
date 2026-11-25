# App Store の掲載文とスクリーンショットの登録

Actions タブの「App Store Metadata」を手動実行すると、言語ごとの掲載文（[docs/app-store/metadata/](metadata/) の `<言語>.md` のアプリ名・サブタイトル・プロモーションテキスト・説明文・キーワード）・マーケティング URL と、このバージョンの新機能（[docs/app-store/whats-new/](whats-new/) の `<バージョン>.md`）、[docs/app-store/review-notes.md](review-notes.md) の審査用メモを、App Store Connect API で App Store バージョン（既定は `MARKETING_VERSION`）に登録します。スクリーンショットは表示サイズごとに別のジョブで並行して `scripts/app-store-screenshots.sh`（撮り方は [screenshots/README.md](screenshots/README.md)）で撮って見出しを付け、表示サイズ × 言語ぶん（10 枚ずつ）を差し替えます。

```bash
gh workflow run app-store-metadata.yml --ref develop
# 一部だけ撮る・撮るだけで登録しない
gh workflow run app-store-metadata.yml --ref develop -f display_types=APP_IPHONE_67 -f languages=ja,en -f upload=false
# クリエイティブアセットのデザインだけを変えたとき（前の実行の 6.9 インチの画面から書き出して配置する。撮り直さない）
gh workflow run app-store-metadata.yml --ref develop -f screenshots=false -f creative_from_run=<前の実行の ID>,<前の実行の ID> -f languages=ja,en
# 実行中の回と言語が 1 つも重ならない回を、待たずに並べて流す（macOS のランナーを空けないため）
gh workflow run app-store-metadata.yml --ref develop -f display_types=APP_IPHONE_DUO -f languages=th -f creative_assets=false -f parallel=true
```

- 文面は各見出しの下のコードブロックから読みます。文字数の上限を超えていたら何も登録せずに止まります。`metadata/<言語>.md` が無い言語は飛ばします（ja は無ければ `listing.md` を読みます）
- アプリの主要言語は languages.json の先頭の言語（en-US）にそろえます
- マーケティング URL は全言語で同じで、[docs/app-store/listing.md](listing.md) の「マーケティング URL」のコードブロックから読み、登録するたびに全言語に入れます。App Store Connect は新しいバージョンに前のバージョンの値を写すので、URL を変えたら画面ではなくこのファイルを直して登録し直します。https の URL でなければ、何も登録せずに止まります
- このバージョンの新機能は、登録するバージョンと同じ名前のファイル（`docs/app-store/whats-new/1.1.0.md` など）の `## <言語>` の下のコードブロックから読みます。アップデートを出すたびに新しいファイルを足します。ファイルが無ければ新機能は触りません（最初のバージョンには入れられないため）。ファイルがあるのに登録する言語の見出しが無いときは、何も登録せずに止まります
- 6.9 インチを撮ったときは、その撮った画面（見出しを付ける前の `raw/`）からクリエイティブアセット（プロダクトページのヘッダー 3840x1646・検索結果 3840x2560）を [docs/app-store/creative/creative.html](creative/creative.html) と `scripts/render-creative-assets.sh` で言語ごとに書き出し、App Asset Library に上げて各言語のローカリゼーションに配置します（`creative_assets` を外すと飛ばします）。文言は creative.html の `copy` に言語ごとに書きます。
  地・模様・書体・端末の枠はスクリーンショット（[docs/app-store/screenshots/screenshots.html](screenshots/screenshots.html)）にそろえます
- クリエイティブアセットだけを作り直すときは、`creative_from_run` に 6.9 インチを撮った前の実行の ID（言語を分けて撮ったならカンマ区切りで複数）を入れ、`screenshots` を外して流します。その実行の Artifact（`screenshots-APP_IPHONE_67`）に入っている言語のうち、`languages` の言語を書き出して配置します（空なら入っている言語すべて。`languages` は掲載文を登録する言語でもあります）。ほかの表示サイズの撮り直しと一緒に流すこともできます
- iPhone Duo は GitHub の標準イメージ `xcode-27`（actions/runner-images の xcode-27-arm64。org で用意するものは無い）で撮ります。イメージに iOS 27.1 のランタイムが無いので、撮影の前にダウンロードします（数分かかります）
- iPhone Duo は 1 言語に 20 分ほどかかるので、言語ごとに別のジョブで撮ります（screenshots.json の `jobPerLanguage`）
- 実行は 1 回ずつ流れ、次の回は前の回が終わるまで待ちます（待てるのは 1 回だけで、後から入れた回が待っている回を置き換えます）。`parallel` を入れた回だけは待たずに動くので、`languages` が実行中の回の言語と 1 つも重ならないときだけ使います。登録のジョブはどの回も `languages` の掲載文を書くので、表示サイズが違っても同じ言語の回を並べると、App Store Connect が HTTP 500 を返して止まることがあります
- 1 つの表示サイズ（言語ごとに分けたものは 1 つの言語）の撮影が失敗しても、撮れたぶんと掲載文は登録します。撮った画像は Artifact（`screenshots-<表示サイズ>`。言語ごとに分けたものは `screenshots-<表示サイズ>-<言語>`）にも残ります
- 指定したバージョンが無ければ、審査前のバージョンの番号を変えます（新規アプリに最初からある「1.0」など）。それも無ければ作ります
- サポート URL・プライバシーポリシー URL・著作権・App Review の連絡先・カテゴリ・年齢制限・価格・App のプライバシー・ビルドの選択は扱いません。App Store Connect の画面で入れてから審査に提出します（提出もこのワークフローでは行いません）
