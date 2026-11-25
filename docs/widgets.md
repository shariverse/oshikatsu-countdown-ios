# ウィジェット

ホーム画面のウィジェットは 3 種です。Widget と TimelineProvider は `OshiConWidget/`、中身の規則と View は `Shared/Widget/` にあります（View はアプリの Preview でも描きます）。

| ウィジェット | 大きさ | 中身 | 料金 |
| --- | --- | --- | --- |
| カウントダウン | 小・ロック画面（丸・長方形・1 行） | 設定で選んだ予定 1 件のあと何日 | 無料 |
| 推しカウント | 中 | これからの予定の一覧 | 無料 |
| 推しの写真 | 小・中 | 設定で選んだ予定の推しの写真を背景に、あと何日 | Plus |

- **推しの写真のコード**: Widget と `PhotoProvider` は `OshiConWidget/PhotoWidget.swift`。中身の型 `PhotoWidgetContent`・View `PhotoWidgetView`・描き分けの規則 `PhotoWidgetAppearance`・タイムライン `PhotoWidgetTimeline`・写真の読み込み `WidgetPhotoLoader` は `Shared/Widget/` にあります
- **中身**: 予定はカウントダウンと同じ `SelectEventIntent` で選びます。小は写真の全面に日数と予定名、中は左に写真、右に推し名・予定名・日数・日付を出します。写真の上の文字は黒の暗幕の上に白で出し、写真の無い推しは推し色の模様（`ThemePhotoPlaceholder`）にします。予定を選んでいない・削除された・読めないときは、カウントダウンと同じ表示です
- **写真の読み込み**: App Group の写真を ImageIO のサムネイルでウィジェットの枠の大きさに縮めて読みます（一辺 720 px まで）
- **tinted の描き方**: フルカラーでない描き方では、暗幕を敷かず、写真を `widgetAccentedRenderingMode(.accentedDesaturated)`（iOS 18 から）と `grayscale` で白黒にして薄く描き、色合いを乗せます。写真は地では外されるので中身に置き、`.contentMarginsDisabled()` で余白を View が付けます
- **Plus の判定**: アプリ（`PlusStore`）が App Group に、Plus が使えるかと期限（サブスクリプションの期限と猶予期間の終わりの遅いほう。買い切りは無し）を書き、変わったらウィジェットを描き直します。
  Widget Extension は `Shared/Purchase/PlusWidgetStatus.swift` で、期限の前ならそのまま使え、期限を過ぎていたら StoreKit 2 の今の権利（`Transaction.currentEntitlements`）で確かめ直します（通信しません。App Group には書き戻しません）
- **タイムライン**: 今と 0:00 にエントリを置き、Plus の期限がその範囲にあれば期限の時刻にもエントリを置いて、その時刻に作り直します
- **Plus でないとき**: 選んだ予定と写真を薄くして「Plus で使えます」を重ねます。押すと課金画面を開きます（リンクは `oshicon://plus/<UUID>`）。課金画面の入口を出さない配り方（`PlusEntryPolicy`。1.3.0 からは無し）では、課金画面を出さずに予定の詳細に移ります
- **描き直し**: 予定・推し・写真の保存と削除、時刻・タイムゾーンの変更、アプリが前面に来たときは `WidgetRefresher` が、Plus の状態や期限の変化は `PlusStore` が、すべてのウィジェットを描き直します
- テスト: Unit は `OshiConTests/Widget/`（`PhotoWidgetContentTests`・`PhotoWidgetAppearanceTests`・`PhotoWidgetTimelineTests`・`WidgetPhotoLoaderTests` など）と `OshiConTests/Purchase/PlusWidgetStatusTests`、UI は `OshiConUITests/PlusPaywallUITests`（課金画面のリンクで開く・開かない）
