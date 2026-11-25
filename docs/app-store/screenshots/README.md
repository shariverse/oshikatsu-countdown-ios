# App Store 用スクリーンショット

見本の推しと予定で、App Store に載せるスクリーンショット 10 枚を、見出しと端末の枠を付けて書き出します。表示サイズを 1 つ選び、言語ごとに次の 3 つを流して `build/app-store-screenshots/<表示サイズ>/<言語>/01.png〜10.png` に書き出します（Google Chrome が要ります）。

1. 撮る: UI テスト（`AppStoreScreenshotTests`）で、アプリの画面と、ホーム画面・ロック画面を撮る（`raw/`）
2. 描き出す: Unit テスト（`AppStoreSurfaceRenderingTests`）で、ウィジェットとロック画面のアクセサリを出荷する View から、通知を実際の文面から PNG に描き出す（`surfaces/`）
3. 重ねる: [docs/app-store/screenshots/screenshots.html](screenshots.html) で、見出し・地・端末の枠を付ける（`scripts/render-app-store-screenshots.sh`）

```bash
scripts/app-store-screenshots.sh APP_IPHONE_67 ja,en
# 撮り直さずに見出しだけ直す
scripts/render-app-store-screenshots.sh build/app-store-screenshots/APP_IPHONE_67/ja APP_IPHONE_67 ja
```

| 枚 | 画面 | 撮り方 |
| --- | --- | --- |
| 1 | ホーム画面のウィジェット＋ Dynamic Island のライブアクティビティ | ホーム画面は撮影、ライブアクティビティは実物（`-sampleLiveActivity`）、ウィジェットは描き出して重ねる |
| 2 | ロック画面のアクセサリ＋ライブアクティビティ | ロック画面とライブアクティビティは実物、アクセサリは描き出して重ねる |
| 3 | 予定の詳細（当日の配信。秒まで進む） | 実物（`-sampleStreamStartsSoon` で開始を 40 分ほど先にする） |
| 4 | 推し色のテーマ（3 色） | 実物（`-sampleTopOshi <役どころ>` で 1 位の推しを替える。地の色がわかるようライトの外観） |
| 5 | Plus の着せ替え | 実物（`-plusUnlocked -sampleAppearance`） |
| 6 | Plus の推しの写真ウィジェット | ホーム画面は撮影、ウィジェットは描き出して重ねる |
| 7 | 画像でシェア | 実物 |
| 8 | 通知 | ロック画面は撮影、通知はアプリが予約する計画の近い 3 件を実際の文面（`ReminderContent`）で描き出して重ねる（iOS 27 の Simulator では通知を安定して出せないため） |
| 9 | 推しの一覧 | 実物 |
| 10 | ライトの外観のホーム | 実物（`-colorScheme light`） |

- アプリの中の画面は Simulator で動かした実物をそのまま使い、HTML で描き直しません（審査ガイドライン 2.3）。ウィジェットはホーム画面・ロック画面に置けない（メモリ上のストアでは共有データも作られない）ので、出荷する View を描き出して、アイコンの並び（UI テストが `home-screen-layout` に残す）に合わせて重ねます
- 見出しと小見出しは [docs/app-store/screenshots/copy.js](copy.js) に、App Store に載せる 14 言語（en-GB・es-MX を含む）で書きます。用語は掲載文にそろえ、価格・実在の人物・作品の名前は入れません。地・模様・枚ごとの色・Plus の印は screenshots.html の `SLIDES` で決めます
- 表示サイズ（6.9 インチ・6.3 インチの iPhone、13 インチの iPad、iPhone Duo の外側の画面）と機種は [docs/app-store/screenshots.json](../screenshots.json)、言語は [docs/app-store/languages.json](../languages.json) で決めます。言語を省くと全言語を撮ります
- 機種はその都度新しく作り、1 回ビルドしたものを言語ごとに使い回します。iPhone Duo は Xcode 27 と iOS 27.1 のランタイムが要ります
- 見本のデータは起動引数 `-useInMemoryStore -seedSampleData` でメモリ上のストアにだけ入ります（端末のデータは書き換えません）。撮影用の起動引数（`-sample…`・`-colorScheme`）も、メモリ上のストアのときだけ効きます。日付は今日から数えるので、いつ撮っても同じ残り日数になります
- 見本の推しには、フリー素材を加工した写真を付けます。画像は UI テストのバンドル（`OshiConUITests/SampleOshiPhotos/`）にあり、アプリには入りません。出典・ライセンスと、差し替えるときに守ることは [docs/app-store/sample-oshi-photos.md](../sample-oshi-photos.md) にあります
- iPhone Duo（外側の画面）は UI テストからロックできず（ロックのボタンが無く、ホームボタンも効かない）、ホーム画面へは下の端からの速いスワイプで戻ります。そのため 2 枚目はライブアクティビティが右の帯に出ているホーム画面に、8 枚目はホーム画面の上の通知のバナー 1 つにします（screenshots.html の `SLIDES` と copy.js の `duo`）
- 要素は言語によらないアクセシビリティ ID（`home.featuredEvent`・`home.eventRow` など）で探します。ロックは XCUIDevice の公開の API に無いので、ボタンを押す口（`pressLockButton`）を使います
- ステータスバーは電池満タン・電波は最大、外観はダークにそろえます。時刻は上書きしません（上書きするとロック画面の日付が 1 月 1 日になり、9:41 ではライブアクティビティの開始の時刻とも合わないため）。ホーム画面のアプリ名・ロック画面の日付もその言語にするため、言語ごとに Simulator の言語・地域を変えて起動し直します。ふだんのテスト（CI を含む）では、撮影と描き出しのテストは飛ばされます
