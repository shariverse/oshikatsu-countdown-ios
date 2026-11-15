# 審査用メモ（下書き）

App Store Connect の「App Review に関する情報」→「メモ」に貼る。デモ用のアカウントは不要（ログインが無い）。

```
本アプリは、推しのライブ・誕生日・発売日などの予定を登録し、その日まであと何日かを数えるカウントダウンアプリです。

・アカウントの登録・ログインはありません（デモ用アカウントは不要です）。
・インターネットを通じた通信は行いません。データはすべて端末の中に保存します。
・課金・広告はありません。
・通知は、登録した予定の前（30 日前・7 日前・前日・当日・開始の 1 時間前）に端末の中で予約するローカル通知だけです。許可は最初の予定を保存したときに求めます。設定タブの「通知」で切り替えられます。

【確認の手順】
1. 初めて起動すると、推しの登録（ステップ 1 / 2）と最初の予定の登録（ステップ 2 / 2）の画面が出ます。「あとで」で飛ばすこともできます。
2. ホームの「予定を追加」から予定を登録すると、ホームに「あと N 日」が表示されます。予定を押すと、秒単位のカウントダウンの画面が開きます。
3. 「推し」タブで推しの登録・編集・削除ができます。写真は iOS の写真の選択画面で選んだものだけを読み込みます（写真ライブラリへのアクセスの許可は求めません）。
   写真を選ぶと調整画面が開き、拡大・縮小・移動・回転で丸い枠に写す範囲を決めます。保存するのは切り抜いた画像だけで、端末の外には送りません。
4. ホーム画面のウィジェット（「カウントダウン」「推しカウント」）を追加できます。カウントダウンはウィジェットを編集して表示する予定を選びます。
5. 通知を押すと、その予定のカウントダウンの画面が開きます。

iPhone と iPad の両方に対応しています。
```

### 英語版

審査員向けの英語のメモ。スクリプト（`upload-app-store-metadata.rb`）はこのファイルの**最初の**コードブロックを読むので、今は上の日本語版が登録される。英語版を登録するなら、この英語版を上に移す。

```
This app lets fans add upcoming events for their "oshi" (a favorite idol, artist or character), such as concerts, birthdays and release days, and counts down the days until each one.

- There is no account registration or sign-in (no demo account is needed).
- The app does not communicate over the internet. All data is stored on the device.
- There are no in-app purchases or ads.
- The only notifications are local notifications scheduled on the device before each event (30 days, 7 days and 1 day before, on the day, and 1 hour before the start time). Permission is requested when the user saves an event, and they can be turned off in the Settings tab under "Notifications".

[How to review]
1. On first launch, the app shows a screen to add an oshi (Step 1 of 2) and then a screen to add the first event (Step 2 of 2). Both can be skipped.
2. Add an event from "Add Event" on the Home tab, and "N days left" appears on Home. Tap an event to open a countdown screen that counts down to the second.
3. On the "Oshi" tab you can add, edit and delete oshi. Photos are loaded only when the user picks them in the iOS photo picker (the app does not ask for photo library access).
   After a photo is picked, an adjustment screen opens where the user can zoom, move and rotate it to frame it in the circle. Only the cropped image is saved, and it never leaves the device.
4. You can add the Home Screen widgets "Countdown" and "Oshi Count". For the Countdown widget, edit the widget to choose which event to show.
5. Tapping a notification opens the countdown screen for that event.

The app supports both iPhone and iPad.
```

## 審査で聞かれそうなこと

- **ユーザーが作る内容**: 推しの名前・写真・予定は本人の端末の中だけで、ほかの利用者に見せる機能は無い（通報・ブロックの仕組みは不要）
- **他社の商標・人物**: アプリの中に実在のアーティスト名や画像は入れていない。見本のデータやスクリーンショット（タスク 21）でも、実在の人物・作品名・ロゴを使わない
