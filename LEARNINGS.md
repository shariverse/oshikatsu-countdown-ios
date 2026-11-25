# LEARNINGS — oshikatsu-countdown-ios の知見

このリポジトリだけで通じる知見を溜める。全リポジトリ共通の知見は `~/.agents/LEARNINGS.md` に書く。

- PC 固有の値（ローカルパス・Simulator の UDID・ユーザー名）と秘密情報は書かない
- 1 項目 = 1 つの箇条書き。見出しの下に追記し、日付（YYYY-MM-DD）を括弧で添える

## 文言（Localizable.xcstrings）

- `Shared/Resources/Localizable.xcstrings` は、1 か所だけ項目を 1 行に詰めて書いている（「推し活カウントダウン Plus」）。スクリプトで文言を足すときに JSON として読み込んで `json.dump` で書き直すと、その項目まで展開されて差分が出る。新しい項目は、既存の書き方（2 スペースの字下げ・`"key" : value`）のテキストとして、並びの位置に差し込む（2026-11-23）

## App Store 用スクリーンショット

- `xcrun simctl status_bar --time 9:41` はロック画面の時計にも効き、日付が「1 月 1 日（土）」になる。ISO 8601 で日時を渡しても（受け付けるのは小数の秒と `Z` の付いた `date -u +%Y-%m-%dT%H:%M:%S.000Z` の形だけ）、iOS 27 のロック画面の日付は 1 月 1 日のままだったので、ロック画面を撮るなら `--time` は上書きしない。ステータスバーの「Carrier」は `--operatorName ""` で消える（2026-11-24）
- iOS 27 の Simulator は、アプリのライブアクティビティを初めて出すとき、ロック画面のライブアクティビティの上で許可を求める（許可するまで Dynamic Island に出ない）。UI テストでは、画面の下半分で横に並んだボタンの右を押す。iOS 27 の新しい Simulator は、ホーム画面に既定のウィジェット（マップ・カレンダー）や「Apple Intelligence の準備ができました」の通知が出ることがある（2026-11-24）
- iOS 27.0 の Simulator（新しく作ったもの・重い Mac）で、`UNUserNotificationCenter.notificationSettings()` が返らず（ログは `Getting notification settings (async)` で止まる）、通知の許可も求められず通知も出せないことがあった。スクリーンショットの通知は、実物を出さず `ReminderContent` の文面から描き出して重ねている（2026-11-24）
- UI テストでロック中に `XCUIApplication.launch()` すると、アプリはロック画面の裏で起動して前面に来ない（通知の許可も求められない）。ロック画面を撮ったら、ホームボタンを押してロックを解いてから次に進む。解くと前のアプリに戻るので、ホーム画面を撮るならもう 1 回ホームボタンを押す（2026-11-24）
- 手元の Mac が重い（load average が 100 を超える）とき、Xcode 26.6 と iOS 26.5 の新しい Simulator で、UI テストのランナーも Unit テストのホストも起動されず、`The test runner hung before establishing connection` で止まることがあった。Xcode 27.1（`DEVELOPER_DIR=/Applications/Xcode-27.1.app/Contents/Developer`）と iOS 27.0 の Simulator では流れた。iOS 27.1 のランタイムで作れるのは iPhone Duo だけ（2026-11-24）
- iPhone Duo（iOS 27.1 の Simulator、外側の画面）は、`XCUIDevice` のボタンがホームとアクションだけで（`hasHardwareButton:` で確かめた）、`pressLockButton` もホームボタンも効かない。ホーム画面へは下の端から速く払うスワイプ（`press(forDuration:thenDragTo:withVelocity: .fast, thenHoldForDuration: 0)`）で戻る。ゆっくり払うと App スイッチャーが出る。ホーム画面の `springboard.icons` には、ほかのページの縮んだアイコンや右側のドックのアイコンも入る（2026-11-25）
- iOS 26 の iPad の Simulator は、ホーム画面の 1 ページ目に既定のウィジェット（ニュース・リマインダー・カレンダー）がある。ニュースのウィジェットは、実在の記事の見出し・媒体名・写真を出すので、そのまま App Store のスクリーンショットに写さない。`springboard.icons` では、どの言語でもラベルが「News」の大きい枠（ラベルのぶん縦に長い）として入る（2026-11-25）
- iOS 26 の iPad で、ロック画面にライブアクティビティを出してからホーム画面に出てロックし直すと、まれに帯が消えていた（14 言語のうち 1 つ）。ロック画面の帯の中身は springboard の `activity-content-view` の要素として見えるので、撮る前に確かめる（帯を包む `ListCell` は何も出ていないロック画面にもある）。iOS 27.0 の iPad の Simulator では、ライブアクティビティがロック画面に出なかった（2026-11-25）

## App Store Connect への提出

- ワークフロー「App Store Metadata」で新しく足した言語（1.3.0 の en-GB・es-MX）は、サポート URL（バージョンのページ）とプライバシーポリシー URL（「アプリのプライバシー」のページ）が空のままで、「審査用に追加」で止められる。ワークフローはこの 2 つを入れないので、言語を足したら画面でほかの言語と同じ URL を入れる（2026-11-25）
- 最初の自動更新サブスクリプションを出すときは、サブスクリプション（月額・年額）と買い切りのほかに、サブスクリプショングループ（OshiCon Plus）のページの「審査用に追加」でグループも同じ下書きに入れる。入れないと下書きに「自動更新サブスクリプションは、サブスクリプショングループとともに提出する必要があります」と出て「審査へ提出」が押せない（2026-11-25）
- `develop` へのマージのたびに TestFlight にビルドが上がる（`upload.yml`）。古いビルドを選んだまま「審査用に追加」を押すと「新しいビルドが使用可能」（キャンセル / 提出）が出るので、キャンセルして最新のビルドを選び直してから追加する。提出の直前に `develop` へマージすると、新しいビルドがまた増える（2026-11-25）
