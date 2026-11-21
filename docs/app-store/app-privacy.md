# 「App のプライバシー」の回答案

App Store Connect の「App のプライバシー」で答える内容の案。アプリと Widget Extension のプライバシーマニフェスト（`OshiCon/PrivacyInfo.xcprivacy`・`OshiConWidget/PrivacyInfo.xcprivacy`）と食い違わないようにする。

## データの収集

**「いいえ、このアプリからデータを収集しません」** と答える。

根拠:
- 通信しない（ネットワークの API を使っていない。解析・広告・クラッシュレポートの SDK も入れていない）
- 推し・写真・予定・設定は端末の中（App Group のコンテナと UserDefaults）にだけ保存する。Apple の定義では、端末の外に送らないデータは「収集」に当たらない
- 写真は PhotosPicker で選んだものだけを読み込む（写真ライブラリの権限を求めない）
- 推し活カウントダウン Plus の課金（StoreKit 2）を入れても、答えは変わらない（下の「課金（StoreKit）について」）

App Store の掲載では「データの収集なし」と表示される。

## 課金（StoreKit）について

推し活カウントダウン Plus（月額・年額のサブスクリプションと買い切り）の課金は StoreKit 2 だけで行い、「データの収集なし」のまま答える。根拠:

- 購入・支払い・解約・返金は Apple（App Store）が処理する。アプリと開発者は、氏名・Apple Account・支払いの情報を受け取らない。購入の情報は Apple が自分の規約で扱うもので、アプリの「App のプライバシー」で答える対象ではない（Apple の「購入履歴」の定義は、デベロッパが収集する場合に当たる）
- 購入したかは、端末の中で `Transaction.currentEntitlements`・`Transaction.updates` の検証済みの取引から決める。自前のサーバー・App Store Server Notifications・レシートのサーバー検証・解析は使わない。アプリのコードから通信はしない（購入・復元のときに通信するのは iOS の StoreKit）
- 判定の結果（Plus が使えるかの真偽値だけ）は、App Group（`group.jp.shilokuma.OshiCon`）の UserDefaults に書き、Widget Extension が読む。端末の外には出ない。取引の ID・日時・金額は保存しない
- 開発者が App Store Connect で見られるのは、個人を特定できない売上・登録の集計だけ

課金を変えるとき（サーバーでの検証・解析・アカウントを足すなど）は、この回答とプライバシーポリシー（[privacy-policy.md](privacy-policy.md) の「4. 有料の機能の購入について」）を見直す。

## トラッキング

しない。プライバシーマニフェストの `NSPrivacyTracking` は `false`、App Tracking Transparency のダイアログも出さない。

## プライバシーマニフェストとの対応

| 項目 | マニフェストの値 | 回答 |
| --- | --- | --- |
| 収集するデータ（`NSPrivacyCollectedDataTypes`） | 空 | データを収集しない |
| トラッキング（`NSPrivacyTracking`） | `false` | トラッキングしない |
| 理由の申告が要る API（`NSPrivacyAccessedAPITypes`） | アプリ: UserDefaults（`CA92.1`・`1C8F.1`）。Widget Extension: UserDefaults（`1C8F.1`） | 回答の対象外（マニフェストだけで申告する） |

UserDefaults は 2 つに分けて使っている。

- アプリだけの UserDefaults（`CA92.1`）: `@AppStorage`（初回の導線を終えたか・終わった予定を出すか・通知の設定）。ウィジェットとは共有しない
- App Group の UserDefaults（`1C8F.1`）: Plus が使えるかの判定の結果（キーは `plusUnlocked`）。アプリが書き、Widget Extension が読む。同じ App Group の中だけで共有し、ほかのアプリや端末の外には渡さない。アプリと Widget Extension の両方のマニフェストで申告する

ファイルは App Group のコンテナでフォルダを作る・写真を消すだけで、タイムスタンプ・空き容量などの API は使っていない。
App Group の UserDefaults に置くものを増やす場合や、ファイルのタイムスタンプなどの API を使う場合は、マニフェスト（アプリと Widget Extension の両方）を見直す。中身は `OshiConTests/App/PrivacyManifestTests.swift` で確かめている。

## 輸出コンプライアンス（暗号化）

Info.plist の `ITSAppUsesNonExemptEncryption` は `false`（独自の暗号化や、免除されない暗号化を使っていない）。App Store Connect で暗号化について聞かれたら「使用していない」と答える。
