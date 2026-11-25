# OshiCon

iOS Application Template (SwiftUI)

iOS アプリのリポジトリを新規作成するときの GitHub テンプレートリポジトリです。
SwiftUI のプロジェクト一式と、ビルド・テスト・Archive・TestFlight 配信までの GitHub Actions ワークフローを含みます。

## Environment

- Xcode 26.6
- iOS 17.0 以上
- Swift 6（Swift 6 言語モード / Strict Concurrency）
- SwiftUI / Swift Testing / XCTest（UI テスト）
- SwiftLint 0.65.1（Build Tool Plugin。バイナリだけを配布する [SwiftLintPlugins](https://github.com/SimplyDanny/SwiftLintPlugins) 経由）

## Status

<div style="margin:0px;padding:0px;">
  <table width="98%" style="border-collapse: collapse;border:2px double #000080;text-align:center;margin:auto;">
    <tbody>
      <tr>
        <td style="border:2px double #000080;">branch \ workflow</td>
        <td style="border:2px double #000080;">Build</td>
        <td style="border:2px double #000080;">Upload</td>
      </tr>
      <tr>
        <td style="border:2px double #000080;text-align:left;">main</td>
        <td style="border:2px double #000080;text-align:center;">
          <a href="https://github.com/shariverse/oshikatsu-countdown-ios/actions/workflows/build.yml?query=branch%3Amain">
            <img src="https://github.com/shariverse/oshikatsu-countdown-ios/actions/workflows/build.yml/badge.svg?branch=main" alt="Build">
          </a>
        </td>
        <td style="border:2px double #000080;text-align:center;">
        </td>
      </tr>
      <tr>
        <td style="border:2px double #000080;text-align:left;">develop</td>
        <td style="border:2px double #000080;text-align:center;">
          <a href="https://github.com/shariverse/oshikatsu-countdown-ios/actions/workflows/build.yml?query=branch%3Adevelop">
            <img src="https://github.com/shariverse/oshikatsu-countdown-ios/actions/workflows/build.yml/badge.svg?branch=develop" alt="Build">
          </a>
        </td>
        <td style="border:2px double #000080;text-align:center;">
          <a href="https://github.com/shariverse/oshikatsu-countdown-ios/actions/workflows/upload.yml?query=branch%3Adevelop">
            <img src="https://github.com/shariverse/oshikatsu-countdown-ios/actions/workflows/upload.yml/badge.svg?branch=develop" alt="Upload">
          </a>
        </td>
      </tr>
    </tbody>
  </table>
</div>

## テンプレートの使い方

### 15. ウィジェット

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

## 仕様

仕様の正は、iOS・Android 共通の仕様リポジトリ [shariverse/app-specs](https://github.com/shariverse/app-specs) です。
このリポジトリの [`docs/spec/`](docs/spec/README.md) は、そこから iOS 版として生成したものです（共通の仕様と、iOS だけの決定 [`platform.md`](docs/spec/platform.md)）。

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
├── docs/                    # ExportOptions.plist のサンプル・App Store の掲載文・テーマ（design/themes.md）・写真の調整の仕様（photo-crop.md）・画像でシェアの仕様（share-card.md）・着せ替えの仕様（appearance.md）
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
- SwiftLint は Build Tool Plugin として全ターゲットに適用され、CI では `swiftlint lint --strict` としても実行されます。ルールは [.swiftlint.yml](.swiftlint.yml) で管理します
- CI のワークフローは `*.xcodeproj` の名前と同名の共有スキームが存在することを前提にしています
- [OshiCon/PrivacyInfo.xcprivacy](OshiCon/PrivacyInfo.xcprivacy) と [OshiConWidget/PrivacyInfo.xcprivacy](OshiConWidget/PrivacyInfo.xcprivacy) はプライバシーマニフェストです。アプリは UserDefaults の利用（`CA92.1`・`1C8F.1`）を、Widget Extension は App Group の UserDefaults の利用（`1C8F.1`。Plus の判定の結果と期限を読む）を申告しています。データの収集・トラッキング・ほかの理由の申告が必要な API を足したら、ここと App Store Connect の「App のプライバシー」を更新してください

## License

[MIT License](LICENSE)
