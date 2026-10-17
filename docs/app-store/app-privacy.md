# 「App のプライバシー」の回答案

App Store Connect の「App のプライバシー」で答える内容の案。アプリのプライバシーマニフェスト（`OshiCon/PrivacyInfo.xcprivacy`）と食い違わないようにする。

## データの収集

**「いいえ、このアプリからデータを収集しません」** と答える。

根拠:
- 通信しない（ネットワークの API を使っていない。解析・広告・クラッシュレポートの SDK も入れていない）
- 推し・写真・予定・設定は端末の中（App Group のコンテナと UserDefaults）にだけ保存する。Apple の定義では、端末の外に送らないデータは「収集」に当たらない
- 写真は PhotosPicker で選んだものだけを読み込む（写真ライブラリの権限を求めない）

App Store の掲載では「データの収集なし」と表示される。

## トラッキング

しない。プライバシーマニフェストの `NSPrivacyTracking` は `false`、App Tracking Transparency のダイアログも出さない。

## プライバシーマニフェストとの対応

| 項目 | マニフェストの値 | 回答 |
| --- | --- | --- |
| 収集するデータ（`NSPrivacyCollectedDataTypes`） | 空 | データを収集しない |
| トラッキング（`NSPrivacyTracking`） | `false` | トラッキングしない |
| 理由の申告が要る API（`NSPrivacyAccessedAPITypes`） | UserDefaults（`CA92.1`） | 回答の対象外（マニフェストだけで申告する） |

ウィジェットと App Group の UserDefaults を共有する場合や、ファイルのタイムスタンプなどの API を使う場合は、マニフェスト（アプリと Widget Extension の両方）を見直す（epic/mvp のタスク 20）。

## 輸出コンプライアンス（暗号化）

Info.plist の `ITSAppUsesNonExemptEncryption` は `false`（独自の暗号化や、免除されない暗号化を使っていない）。App Store Connect で暗号化について聞かれたら「使用していない」と答える。
