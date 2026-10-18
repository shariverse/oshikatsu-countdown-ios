# App Store の掲載情報（下書き）

## 掲載文（言語ごと）

アプリ名・サブタイトル・プロモーションテキスト・説明文・キーワードは、言語ごとに [metadata/](metadata/) の `<language>.md` に書く。

| ファイル | 言語 |
| --- | --- |
| [en.md](metadata/en.md) | 英語（既定の言語） |
| [ja.md](metadata/ja.md) | 日本語 |
| [zh-Hans.md](metadata/zh-Hans.md) | 中国語（簡体字） |
| [zh-Hant.md](metadata/zh-Hant.md) | 中国語（繁体字） |
| [ko.md](metadata/ko.md) | 韓国語 |
| [fr.md](metadata/fr.md) | フランス語 |
| [de.md](metadata/de.md) | ドイツ語 |
| [es.md](metadata/es.md) | スペイン語 |
| [pt-BR.md](metadata/pt-BR.md) | ポルトガル語（ブラジル） |
| [it.md](metadata/it.md) | イタリア語 |
| [th.md](metadata/th.md) | タイ語 |
| [id.md](metadata/id.md) | インドネシア語 |

どのファイルも「## アプリ名」「## サブタイトル」「## プロモーションテキスト」「## 説明文」「## キーワード」の見出しの下に、文面のコードブロックを 1 つ置く（見出しはスクリプトが探すので、どの言語でも日本語のまま）。
文字数の上限は App Store Connect の制限（アプリ名 30 文字、サブタイトル 30 文字、プロモーションテキスト 170 文字、キーワード 100 文字、説明文 4,000 文字）。
キーワードはカンマ区切りで空白を入れず、アプリ名とサブタイトルに入っている語は外す（入れなくても検索の対象になる）。

## カテゴリ（案）

- プライマリ: ライフスタイル
- セカンダリ: エンターテインメント（ほかの候補: 仕事効率化。人間が決める）

## 年齢制限の回答（案）

すべての項目に「なし」と答える見込み（暴力・性的な内容・ギャンブル・ユーザーが作る内容の共有・Web の閲覧などは無い。ユーザーが入力した文字と写真は端末の中だけで、ほかの人に見せる機能は無い）。

## スクリーンショット

`scripts/app-store-screenshots.sh` で撮る（見本のデータで UI テストを流す。6.9 インチの iPhone と 13 インチの iPad）。README の「App Store 用スクリーンショット」を参照。

掲載文（[metadata/](metadata/) の各ファイルの、見出しの下のコードブロック）とスクリーンショットは、ワークフロー「App Store Metadata」で App Store Connect に登録する（README の「App Store の掲載文とスクリーンショットの登録」）。
