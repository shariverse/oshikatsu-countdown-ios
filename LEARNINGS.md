# LEARNINGS — oshikatsu-countdown-ios の知見

このリポジトリだけで通じる知見を溜める。全リポジトリ共通の知見は `~/.agents/LEARNINGS.md` に書く。

- PC 固有の値（ローカルパス・Simulator の UDID・ユーザー名）と秘密情報は書かない
- 1 項目 = 1 つの箇条書き。見出しの下に追記し、日付（YYYY-MM-DD）を括弧で添える

## 文言（Localizable.xcstrings）

- `Shared/Resources/Localizable.xcstrings` は、1 か所だけ項目を 1 行に詰めて書いている（「推し活カウントダウン Plus」）。スクリプトで文言を足すときに JSON として読み込んで `json.dump` で書き直すと、その項目まで展開されて差分が出る。新しい項目は、既存の書き方（2 スペースの字下げ・`"key" : value`）のテキストとして、並びの位置に差し込む（2026-11-23）

## App Store 用スクリーンショット

- `xcrun simctl status_bar --time 9:41` はロック画面の時計にも効き、日付が「1 月 1 日（土）」になる。ISO 8601 で日時を渡しても（受け付けるのは小数の秒と `Z` の付いた `date -u +%Y-%m-%dT%H:%M:%S.000Z` の形だけ）、iOS 27 のロック画面の日付は 1 月 1 日のままだったので、ロック画面を撮るなら `--time` は上書きしない。ステータスバーの「Carrier」は `--operatorName ""` で消える（2026-11-24）
- iOS 27 の Simulator は、通知の許可のダイアログが SpringBoard ではなくアプリの要素（`app.alerts`）として見える。アプリのライブアクティビティを初めて出すとき、ロック画面のライブアクティビティの上で許可を求める（許可するまで Dynamic Island に出ない）。UI テストでは、画面の下半分で横に並んだボタンの右を押す。iOS 27 の新しい Simulator は、ホーム画面に既定のウィジェット（マップ・カレンダー）や「Apple Intelligence の準備ができました」の通知が出ることがある（2026-11-24）
- UI テストでロック中に `XCUIApplication.launch()` すると、アプリはロック画面の裏で起動して前面に来ない（通知の許可も求められない）。ロック画面を撮ったら、ホームボタンを押してロックを解いてから次に進む。解くと前のアプリに戻るので、ホーム画面を撮るならもう 1 回ホームボタンを押す（2026-11-24）
- 手元の Mac が重い（load average が 100 を超える）とき、Xcode 26.6 と iOS 26.5 の新しい Simulator で、UI テストのランナーも Unit テストのホストも起動されず、`The test runner hung before establishing connection` で止まることがあった。Xcode 27.1（`DEVELOPER_DIR=/Applications/Xcode-27.1.app/Contents/Developer`）と iOS 27.0 の Simulator では流れた。iOS 27.1 のランタイムで作れるのは iPhone Duo だけ（2026-11-24）
