# 審査用メモ（下書き）

App Store Connect の「App Review に関する情報」→「メモ」に貼る。デモ用のアカウントは不要（ログインが無い）。

推し活カウントダウン Plus（App 内課金）の段落と確認の手順の 7 は、Plus の入口を App Store 版で出すバージョン（1.3.0）を、課金の商品と一緒に審査に出すときのもの。
それより前のバージョン（App Store 版では課金画面の入口を出さない）を審査に出すときは、この 2 か所を外し、「課金・広告はありません。」に戻して登録する。
3 つの商品の productId・期間・お試しは [in-app-purchases.json](in-app-purchases.json) と同じにする。

```
本アプリは、推しのライブ・誕生日・発売日などの予定を登録し、その日まであと何日かを数えるカウントダウンアプリです。

・アカウントの登録・ログインはありません（デモ用アカウントは不要です）。
・インターネットを通じた通信は行いません（購入のときに iOS が App Store と通信するだけです）。データはすべて端末の中に保存します。
・広告はありません。有料の機能「推し活カウントダウン Plus」があります（下記）。
・通知は、登録した予定の前（30 日前・7 日前・前日・当日・開始の 1 時間前）に端末の中で予約するローカル通知だけです。許可は最初の予定を保存したときに求めます。設定タブの「通知」で切り替えられます。

【確認の手順】
1. 初めて起動すると、推しの登録（ステップ 1 / 2）と最初の予定の登録（ステップ 2 / 2）の画面が出ます。「あとで」で飛ばすこともできます。
2. ホームの「予定を追加」から予定を登録すると、ホームに「あと N 日」が表示されます。予定を押すと、秒単位のカウントダウンの画面が開きます。
3. 「推し」タブで推しの登録・編集・削除ができます。写真は iOS の写真の選択画面で選んだものだけを読み込みます（写真ライブラリへのアクセスの許可は求めません）。
   写真を選ぶと調整画面が開き、拡大・縮小・移動・回転で丸い枠に写す範囲を決めます。保存するのは切り抜いた画像だけで、端末の外には送りません。
4. ホーム画面のウィジェット（「カウントダウン」「推しカウント」）を追加できます。カウントダウンはウィジェットを編集して表示する予定を選びます。カウントダウンはロック画面（丸・長方形・1 行）にも置けます。
5. 通知を押すと、その予定のカウントダウンの画面が開きます。
6. 開始の時刻がある予定の当日は、開始の 3 時間前から 1 時間後まで、ロック画面と Dynamic Island のライブアクティビティで開始までの残り時間を表示します（端末の中だけで動き、プッシュ通知は使いません）。
7. 設定タブの「推し活カウントダウン Plus」の行を押すと、課金画面が開きます。サブスクリプション（年額・月額）と、その下に買い切りが並び、購入の復元・利用規約・プライバシーポリシーのリンクがあります。

【推し活カウントダウン Plus（App 内課金）】
推しの写真ウィジェットと、アプリの背景・飾りを推しの写真にする着せ替えを解放する有料の機能です。商品は次の 3 つです。
・Plus（年額） jp.shilokuma.OshiCon.plus.yearly：自動更新のサブスクリプション（1 年）。1 週間の無料のお試しがあります。
・Plus（月額） jp.shilokuma.OshiCon.plus.monthly：自動更新のサブスクリプション（1 か月）。
・Plus（買い切り） jp.shilokuma.OshiCon.plus.lifetime：非消耗型。一度の購入で、今後追加する Plus の機能も含めてずっと使えます。
年額と月額は同じサブスクリプショングループ（OshiCon Plus）です。サブスクリプションが有効な間（請求の猶予期間を含む）か、買い切りを購入したときに Plus が使えます。解約・期限切れのあとは見た目を標準に戻し、選んだ写真は端末の中に残します。
購入・復元は StoreKit だけで行い、購入の状態は端末の中で確かめます。自前のサーバー・解析は使いません。
利用規約は Apple の標準の使用許諾契約（EULA）です。サブスクリプション中に買い切りを購入する場合は、サブスクリプションが自動では止まらず自分で解約する必要があることを、購入の前と後にお知らせします。
今ある無料の機能（推しと予定の登録・カウントダウン・ホーム画面とロック画面のウィジェット・通知・ライブアクティビティ）は今後も無料のままで、有料に移しません。
サブスクリプションで使い続けていただけるよう、Plus の着せ替えのテーマや飾りを今後も定期的に追加していく予定です。

iPhone と iPad の両方に対応しています。
```

### 英語版

審査員向けの英語のメモ。スクリプト（`upload-app-store-metadata.rb`）はこのファイルの**最初の**コードブロックを読むので、今は上の日本語版が登録される。英語版を登録するなら、この英語版を上に移す。

```
This app lets fans add upcoming events for their "oshi" (a favorite idol, artist or character), such as concerts, birthdays and release days, and counts down the days until each one.

- There is no account registration or sign-in (no demo account is needed).
- The app does not communicate over the internet (only iOS talks to the App Store for purchases). All data is stored on the device.
- There are no ads. The app offers a paid feature, "Oshi Countdown Plus" (see below).
- The only notifications are local notifications scheduled on the device before each event (30 days, 7 days and 1 day before, on the day, and 1 hour before the start time). Permission is requested when the user saves an event, and they can be turned off in the Settings tab under "Notifications".

[How to review]
1. On first launch, the app shows a screen to add an oshi (Step 1 of 2) and then a screen to add the first event (Step 2 of 2). Both can be skipped.
2. Add an event from "Add Event" on the Home tab, and "N days left" appears on Home. Tap an event to open a countdown screen that counts down to the second.
3. On the "Oshi" tab you can add, edit and delete oshi. Photos are loaded only when the user picks them in the iOS photo picker (the app does not ask for photo library access).
   After a photo is picked, an adjustment screen opens where the user can zoom, move and rotate it to frame it in the circle. Only the cropped image is saved, and it never leaves the device.
4. You can add the Home Screen widgets "Countdown" and "Oshi Count". For the Countdown widget, edit the widget to choose which event to show. The Countdown widget can also be added to the Lock Screen (circular, rectangular and inline).
5. Tapping a notification opens the countdown screen for that event.
6. On the day of an event with a start time, a Live Activity on the Lock Screen and in the Dynamic Island shows the time left from 3 hours before until 1 hour after the start. It runs entirely on the device and does not use push notifications.
7. Tap "Oshi Countdown Plus" in the Settings tab to open the purchase screen. It shows the subscriptions (yearly and monthly) with the one-time purchase below them, and links to Restore Purchases, the Terms of Use and the Privacy Policy.

[Oshi Countdown Plus (in-app purchases)]
Plus is a paid feature that unlocks a photo widget with the user's own oshi photo and lets them decorate the app background and decorations with that photo. There are three products:
- Plus (Yearly), jp.shilokuma.OshiCon.plus.yearly: auto-renewable subscription (1 year) with a one-week free trial.
- Plus (Monthly), jp.shilokuma.OshiCon.plus.monthly: auto-renewable subscription (1 month).
- Plus (Lifetime), jp.shilokuma.OshiCon.plus.lifetime: non-consumable. One purchase unlocks Plus forever, including Plus features added later.
The yearly and monthly plans are in the same subscription group (OshiCon Plus). Plus is available while a subscription is active (including the billing grace period) or after the one-time purchase. When a subscription is canceled or expires, the app returns to the standard look and keeps the chosen photos on the device.
Purchases and restores use StoreKit only, and the purchase status is checked on the device. The app uses no server of its own and no analytics.
The Terms of Use are Apple's standard EULA. If a subscriber buys the one-time purchase, the app tells them before and after the purchase that the subscription does not stop automatically and that they need to cancel it themselves.
All existing free features (adding oshi and events, countdowns, Home Screen and Lock Screen widgets, notifications and Live Activities) stay free and will not be moved behind Plus.
To keep the subscription worthwhile, we plan to add new Plus themes and decorations regularly.

The app supports both iPhone and iPad.
```

## 審査で聞かれそうなこと

- **ユーザーが作る内容**: 推しの名前・写真・予定は本人の端末の中だけで、ほかの利用者に見せる機能は無い（通報・ブロックの仕組みは不要）
- **サブスクリプションの続く価値（ガイドライン 3.1.2(a)）**: Plus の着せ替えのテーマや飾りを定期的に足していく（メモに書いた予定を守る）。今ある無料の機能（数える・ウィジェット・通知・ライブアクティビティ・ロック画面）は Plus に移さない
- **メモの文字数**: App Store Connect のメモは 4,000 文字まで（`upload-app-store-metadata.rb` の `LIMITS`）。英語版は 4,000 文字に近いので、書き足すときは数える
- **他社の商標・人物**: アプリの中に実在のアーティスト名や画像は入れていない。見本のデータやスクリーンショット（タスク 21）でも、実在の人物・作品名・ロゴを使わない
