# 開発ガイド

開発環境・仕様の扱い・多言語対応・リポジトリの構成をまとめています。

## 開発環境

- Xcode 26.6
- iOS 17.0 以上
- Swift 6（Swift 6 言語モード / Strict Concurrency）
- SwiftUI / Swift Testing / XCTest（UI テスト）
- SwiftLint 0.65.1（Build Tool Plugin。バイナリだけを配布する [SwiftLintPlugins](https://github.com/SimplyDanny/SwiftLintPlugins) 経由）

## 仕様

仕様の正は、iOS・Android 共通の仕様リポジトリ [shariverse/app-specs](https://github.com/shariverse/app-specs) です。
このリポジトリの [`docs/spec/`](spec/README.md) は、そこから iOS 版として生成したものです（共通の仕様と、iOS だけの決定 [`platform.md`](spec/platform.md)）。

- `docs/spec/` は直接編集しません。変えるときは app-specs に PR を出します
- app-specs の main が変わると、Bot が `spec-sync` ブランチの PR「【DOCS】仕様を app-specs に合わせる」を出します。iOS では、届いたらすぐマージします
- 実装しながら仕様（使う人から見える振る舞い・文言・規則・配色）を決めた・変えたときは、実装の PR と並行して app-specs に仕様の PR を出し、実装の PR の本文にリンクを書きます
- コードの場所・テストの口・iOS だけの実装の参考は、これまでどおり `docs/`（`docs/photo-crop.md`・`docs/share-card.md`・`docs/design/themes.md`）に置きます

## 多言語対応

アプリと Widget Extension は 12 言語に対応しています（英語が既定。対応していない言語の端末では英語で出ます）。

| 言語 | コード |
| --- | --- |
| 英語（既定） | `en` |
| 日本語 | `ja` |
| 中国語（簡体字・繁体字） | `zh-Hans`・`zh-Hant` |
| 韓国語 | `ko` |
| フランス語・ドイツ語・スペイン語・イタリア語 | `fr`・`de`・`es`・`it` |
| ポルトガル語（ブラジル） | `pt-BR` |
| タイ語・インドネシア語 | `th`・`id` |

- 文言は `Shared/Resources/Localizable.xcstrings`、ホーム画面の表示名は `OshiCon/InfoPlist.xcstrings`・`OshiConWidget/InfoPlist.xcstrings` にあります。文言を足したら 12 言語ぶん訳を入れてください
- 別の言語で確かめるときは、Xcode のスキームの「Run」→「Options」→「App Language」を変えるか、起動引数に `-AppleLanguages (zh-Hant)` を付けます
- UI テストは文言で要素を探すので、`-AppleLanguages (ja)` を付けて日本語で起動します

## 構成

```
.
├── Configs/                 # xcconfig（署名情報・バージョン・Deployment Target）・OshiCon.storekit（StoreKit Configuration）
├── OshiCon/          # アプリ本体（SwiftUI）
├── OshiConTests/     # Unit テスト（Swift Testing）
├── OshiConUITests/   # UI テスト（XCTest）
├── OshiCon.xcodeproj # 共有スキーム OshiCon を含む
├── OshiCon.xctestplan # 共有スキーム OshiCon のテストプラン（Unit テスト・UI テスト・StoreKit Configuration）
├── docs/                    # 開発の手引き（development.md・setup.md・ci.md・pr-screenshots.md）・ExportOptions.plist のサンプル・App Store の掲載文と運用（app-store/）・テーマ（design/themes.md）・写真の調整の仕様（photo-crop.md）・画像でシェアの仕様（share-card.md）・着せ替えの仕様（appearance.md）・ウィジェット（widgets.md）
├── scripts/                 # rename.sh・app-store-screenshots.sh（App Store 用スクリーンショット）・render-creative-assets.sh（クリエイティブアセット）
├── .swiftlint.yml           # SwiftLint 設定
└── .github/
    ├── ISSUE_TEMPLATE/      # Issue テンプレート
    ├── pull_request_template.md
    ├── scripts/             # check-app-store-app.rb（App Store Connect のアプリの有無を確認）・embed-entitlements.rb（Archive に Entitlements を埋め込む）・app-store-metadata/（掲載文とスクリーンショットの登録）・creative-assets/（クリエイティブアセットの配置）・app-store-purchases/（課金の商品の登録）
    └── workflows/
        ├── _build.yml       # 共通処理: ビルド + テスト + SwiftLint（workflow_call）
        ├── _archive.yml     # 共通処理: Archive → Export（→ Upload）（workflow_call）
        ├── build.yml        # 全ブランチの push / Fork からの PR
        ├── archive.yml      # Archive → Export（手動実行）
        ├── upload.yml       # develop / release/** の push
        ├── app-store-metadata.yml # 掲載文とスクリーンショットの登録（手動実行）
        └── app-store-purchases.yml # 課金の商品の登録（手動実行）
```

- プロジェクトはフォルダ同期グループ（Xcode 16 以降の形式）で管理しているため、ファイルの追加・削除で pbxproj は変わりません
- SwiftLint は Build Tool Plugin として全ターゲットに適用され、CI では `swiftlint lint --strict` としても実行されます。ルールは [.swiftlint.yml](../.swiftlint.yml) で管理します
- CI のワークフローは `*.xcodeproj` の名前と同名の共有スキームが存在することを前提にしています
- [OshiCon/PrivacyInfo.xcprivacy](../OshiCon/PrivacyInfo.xcprivacy) と [OshiConWidget/PrivacyInfo.xcprivacy](../OshiConWidget/PrivacyInfo.xcprivacy) はプライバシーマニフェストです。アプリは UserDefaults の利用（`CA92.1`・`1C8F.1`）を、Widget Extension は App Group の UserDefaults の利用（`1C8F.1`。Plus の判定の結果と期限を読む）を申告しています。データの収集・トラッキング・ほかの理由の申告が必要な API を足したら、ここと App Store Connect の「App のプライバシー」を更新してください
