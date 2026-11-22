# LEARNINGS — oshikatsu-countdown-ios の知見

このリポジトリだけで通じる知見を溜める。全リポジトリ共通の知見は `~/.agents/LEARNINGS.md` に書く。

- PC 固有の値（ローカルパス・Simulator の UDID・ユーザー名）と秘密情報は書かない
- 1 項目 = 1 つの箇条書き。見出しの下に追記し、日付（YYYY-MM-DD）を括弧で添える

## 文言（Localizable.xcstrings）

- `Shared/Resources/Localizable.xcstrings` は、1 か所だけ項目を 1 行に詰めて書いている（「推し活カウントダウン Plus」）。スクリプトで文言を足すときに JSON として読み込んで `json.dump` で書き直すと、その項目まで展開されて差分が出る。新しい項目は、既存の書き方（2 スペースの字下げ・`"key" : value`）のテキストとして、並びの位置に差し込む（2026-11-23）
