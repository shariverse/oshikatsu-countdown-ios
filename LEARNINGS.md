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

## UI テスト

- iOS 26 のスライダーは、つまみが指に遅れて付いてくる。`adjust(toNormalizedSliderPosition:)` は速く引いてすぐ指を離すので、遅い CI の Simulator では途中（75〜95%）で止まる。途中から `adjust` で引き直しても、短く速いドラッグにつまみは付いてこず、右へ引き直した指は iOS 26 の「画面のどこからでも戻れるスワイプ」として効いて前の画面に戻る。つまみを押さえてゆっくり引き、端で止めてから離す（`press(forDuration:thenDragTo:withVelocity:thenHoldForDuration:)`）と、負荷をかけても端まで届く。つまみのまん中は、スライダーの両端から 19pt ほど内側を動く（2026-11-26）
- 一覧の並べ替えのドラッグも、着いた先で止めてから離す。着いてすぐ離すと、遅い CI の Simulator では、ほかの行がよける前に落ちて 1 つ手前の順位に入る（2026-11-26）
- 遅い CI の Simulator（起動した直後は特に）では、`tap()` が効かないことがある（タブバーは選択の印が動きかけて元のタブに戻り、スイッチは何も起きない）。手元では負荷をかけても再現しなかった。タブとスイッチは `OshiConUITests/UITestSupport.swift` の `selectTab(_:)`・`setSwitch(to:)` で押す（効いたことを確かめ、効いていなければ押し直す）（2026-11-26）
- 遅い Simulator では、`XCTWaiter` の待ちが、条件を満たしているのに時間切れで返ることがある（要素の読み取り 1 回に数秒かかるため）。待ちの結果ではなく、待った後に読んだ値で確かめる（2026-11-26）
- CI で落ちた UI テストは、成果物の `TestResults.xcresult` を取ってきて `xcrun xcresulttool get test-results activities --path <xcresult> --test-id '<クラス>/<テスト>()'` で落ちる直前の操作を、`xcrun xcresulttool export attachments` で録画・押した座標（`Synthesized Event` の plist）・画面の階層を読める。`gh api …/jobs/<id>/logs` は空で返るので、ログは `gh run view <id> --log` で取る（2026-11-26）
- 手元（macOS 27）の Xcode 26.6 では、負荷が低くても、iOS 26.5 の新しい Simulator で UI テストのランナーが `The test runner hung before establishing connection` で起動しなかった。Xcode 27.1（`DEVELOPER_DIR`）でビルドして同じ iOS 26.5 の Simulator に流すと、CI と同じ OS で確かめられる（2026-11-26）

## App Store Connect への提出

- ワークフロー「App Store Metadata」で新しく足した言語（1.3.0 の en-GB・es-MX）は、サポート URL（バージョンのページ）とプライバシーポリシー URL（「アプリのプライバシー」のページ）が空のままで、「審査用に追加」で止められる。ワークフローはこの 2 つを入れないので、言語を足したら画面でほかの言語と同じ URL を入れる（2026-11-25）
- 最初の自動更新サブスクリプションを出すときは、サブスクリプション（月額・年額）と買い切りのほかに、サブスクリプショングループ（OshiCon Plus）のページの「審査用に追加」でグループも同じ下書きに入れる。入れないと下書きに「自動更新サブスクリプションは、サブスクリプショングループとともに提出する必要があります」と出て「審査へ提出」が押せない（2026-11-25）
- `develop` へのマージのたびに TestFlight にビルドが上がる（`upload.yml`）。古いビルドを選んだまま「審査用に追加」を押すと「新しいビルドが使用可能」（キャンセル / 提出）が出るので、キャンセルして最新のビルドを選び直してから追加する。提出の直前に `develop` へマージすると、新しいビルドがまた増える（2026-11-25）
- 提出物の下書きに入れたバージョンは「審査準備完了」（API の `READY_FOR_REVIEW`）になり、API でスクリーンショットを消せず（HTTP 409「Can't Delete Screenshot while Ready For Review」）、画面でもビルドを選び直せない。差し替えるときは、下書きのパネルで iOS アプリの項目の赤い印を押してバージョンを外し（課金の項目は下書きに残る）、登録が終わったら「審査用に追加」し直す（2026-11-25）
