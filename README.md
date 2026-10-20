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
        <td style="border:2px double #000080;">Archive</td>
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
          <a href="https://github.com/shariverse/oshikatsu-countdown-ios/actions/workflows/archive.yml?query=branch%3Amain">
            <img src="https://github.com/shariverse/oshikatsu-countdown-ios/actions/workflows/archive.yml/badge.svg?branch=main" alt="Archive">
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

### 1. リポジトリを作成する

GitHub の「Use this template」からリポジトリを作成し、clone します。

### 2. プロジェクト名を変更する

`OshiCon` を新しいアプリ名に一括変更するスクリプトを用意しています。
ディレクトリ・`.xcodeproj`・スキーム・ソース内の識別子・README のバッジ URL をまとめて置換します。

```bash
scripts/rename.sh MyApp
```

- アプリ名は英字で始まる英数字のみです（Swift のモジュール名になります）
- README のバッジ URL に使うリポジトリ名は `origin` から推定します。別のものを使う場合は第 2 引数で `owner/repo` を渡します
- 作業ツリーがクリーンな状態で実行し、実行後に `git diff` で差分を確認してコミットしてください

### 3. 署名情報を設定する

署名情報やバージョンは pbxproj ではなく [Configs/Project.xcconfig](Configs/Project.xcconfig) に集約しています。
リポジトリ作成後、まず以下を書き換えてください。

| 設定 | 内容 |
|---|---|
| `DEVELOPMENT_TEAM` | Apple Developer Program の Team ID |
| `APP_BUNDLE_IDENTIFIER` | アプリ本体の Bundle Identifier。テストターゲットは `.Tests` / `.UITests` を付けて自動で派生します |
| `MARKETING_VERSION` | アプリのバージョン。ビルド番号（`CURRENT_PROJECT_VERSION`）は Upload のときに App Store Connect の最新ビルドを見て Xcode が自動で増やすため、手で上げる必要はありません |
| `IPHONEOS_DEPLOYMENT_TARGET` | 最低サポート OS |

### 4. GitHub Secrets を設定する

Archive / Upload ワークフローは App Store Connect API Key で認証します。
リポジトリの Settings → Secrets and variables → Actions に以下を登録してください。

| Secret | 内容 |
|---|---|
| `EXPORT_OPTIONS` | `ExportOptions.plist` の内容。[docs/ExportOptions.sample.plist](docs/ExportOptions.sample.plist) の `teamID` を書き換えて、ファイルの中身をそのまま登録します |
| `APPLE_API_KEY_BASE64` | App Store Connect の API Key（`AuthKey_XXXXXXXXXX.p8`）を `base64 -i AuthKey_XXXXXXXXXX.p8` でエンコードした文字列 |
| `APPLE_API_KEY_ID` | API Key の Key ID |
| `APPLE_API_ISSUER_ID` | API Key の Issuer ID |

API Key は App Store Connect の「ユーザとアクセス → 統合 → App Store Connect API」で、App Manager 以上の権限で発行します。
### 5. App Store Connect にアプリを作成する

Bundle ID・証明書・プロビジョニングプロファイルは、Export のときに API Key で自動的に作成されます（`-allowProvisioningUpdates`）。
アプリと Widget Extension の 2 つの Bundle ID が登録されます。Archive は署名せずに作るため、Export の前に各ターゲットの Entitlements（App Group）をアドホック署名で埋め込み（[.github/scripts/embed-entitlements.rb](.github/scripts/embed-entitlements.rb)）、Export した IPA に残っていることを確かめてからアップロードします。
「Check entitlements in IPA」で App Group が無いと止まったときは、Export の自動署名が App Group を登録・割り当てできていません。Apple Developer の Identifiers で App Group（`group.<アプリの Bundle ID>`）を作り、アプリと Widget Extension の両方の App ID に割り当ててから、ワークフローを再実行してください。
App Store Connect でのアプリ作成だけは API で行えないため、Web 画面で行います。

アプリを作らずに `develop` へ push しても問題ありません。Upload ワークフローがアップロードの前にアプリの有無を確認し（[.github/scripts/check-app-store-app.rb](.github/scripts/check-app-store-app.rb)）、アプリが無ければ「新規アプリ」画面に入力する値（名前・バンドル ID・SKU など）を Job Summary に表示して止まります。表示された値でアプリを作成してから、ワークフローを再実行してください。

SKU は Bundle ID と同じ値にします。SKU はユーザーには見えない社内用の ID で、後から変更できないため、迷わないようにルールを固定しています。

### 6. ブランチ運用と CI

| ブランチ | Build（ビルド + テスト + SwiftLint） | Archive（IPA Export） | Upload（App Store Connect） |
|---|:-:|:-:|:-:|
| `main` | ✅ | ✅ | |
| `develop` | ✅ | | ✅ |
| `release/**` | ✅ | | ✅ |
| その他の作業ブランチ | ✅（Unit テストのみ） | | |
| Pull Request の作成時（opened / reopened / ready_for_review） | ✅ | | |
| Fork からの Pull Request | ✅ | | |

- Upload は Archive → IPA Export を含むため、`develop` / `release/**` では Archive を別途実行しません
- Archive / Upload は Actions タブから手動でも実行できます（Run workflow）。作業ブランチを TestFlight で確認したいときは、Upload を手動実行してそのブランチを選びます
- リポジトリ変数（Settings → Secrets and variables → Actions → Variables）に `ENABLE_DELIVERY=false` を設定すると Upload をスキップします（Archive は App Store Connect にアプリが無くても通るため止めません）。テンプレートリポジトリ自身はこの設定でアップロードを止めています。テンプレートから作成したリポジトリには引き継がれないため、何もしなければ従来どおり実行されます
- ドキュメントだけの変更（`**/*.md`、`docs/**`）では Build を実行しません。Upload（`develop` / `release/**` への push）と Archive（`main` への push）は、ドキュメントだけの変更でも実行します
- 作業ブランチへの push では、時間のかかる UI テスト（`<プロジェクト名>UITests`）を省いて Unit テストだけ実行します。UI テストは Pull Request の作成時と `main` / `develop` / `release/**` への push で実行します。Fork からの Pull Request は push で実行されないため、更新（synchronize）を含むすべてのイベントで UI テストまで実行します
- Xcode のバージョンは [.github/workflows/_build.yml](.github/workflows/_build.yml) と [.github/workflows/_archive.yml](.github/workflows/_archive.yml) の `xcode-version` で固定しています。Environment の更新時はあわせて変更してください

### 7. PR 本文のスクリーンショット

UI の見た目が変わる変更では、Before / After のスクリーンショットを PR 本文に添付します。

- 画像は GitHub の添付ファイルとしてアップロードします。git の履歴やブランチには含まれず、マージ後も表示され続けます
  - ブラウザで PR を作る場合は、本文の入力欄に画像をドラッグ & ドロップします
  - CLI（エージェントを含む）では `gh` の `--attach`（gh v2.99.0 以上）を使います。本文に Markdown の表と `![Before](./before.png)` の形でローカルのパスを書き、同じファイルを `--attach` で渡すと、gh がその場でアップロード先の URL に書き換えます
  - HTML の `<img src="./before.png">` や `<table>` の中のパスは書き換わりません。表は Markdown で書き、幅をそろえたいときは作成後に `<img width="300">` へ置き換えます（下の例）
- アップロードした画像は削除できません。個人情報やトークンなどが写っていないか確認してから添付してください
- Before / After は表で横に並べ、同一条件（同じ端末・OS・外観モード・データ状態）で撮影します
- 影響する画面が複数ある場合は画面ごとに用意します。新規画面で Before が無い場合は「なし」と書きます

```bash
# body.md の表に ![Before](./before.png) と ![After](./after.png) を書いておく
gh pr create --title "..." --body-file body.md --assignee @me \
  --attach ./before.png --attach ./after.png

# 本文の画像を幅 300 の <img> に置き換える（本文を取得できたときだけ更新する）
body=$(gh pr view <番号> --json body -q .body) &&
  printf '%s\n' "$body" \
  | perl -pe 's{!\[([^\]]*)\]\((https://github\.com/user-attachments/assets/[^)\s]+)\)}{<img src="$2" alt="$1" width="300">}g' \
  | gh pr edit <番号> --body-file -
```

### 8. App Store 用スクリーンショット

見本の推しと予定で、App Store に載せるスクリーンショットを撮ります。表示サイズを 1 つ選んで UI テスト（`AppStoreScreenshotTests`）を言語ごとに流し、画像を `build/app-store-screenshots/<表示サイズ>/<言語>/` に書き出します。

```bash
scripts/app-store-screenshots.sh APP_IPHONE_67 ja,en
```

- 表示サイズ（6.9 インチ・6.3 インチの iPhone、13 インチの iPad、iPhone Duo）と機種は [docs/app-store/screenshots.json](docs/app-store/screenshots.json)、言語は [docs/app-store/languages.json](docs/app-store/languages.json) で決めます。言語を省くと全言語を撮ります
- 機種はその都度新しく作り、1 回ビルドしたものを言語ごとに使い回します。iPhone Duo は Xcode 27 と iOS 27.1 のランタイムが要ります
- 見本のデータは起動引数 `-useInMemoryStore -seedSampleData` でメモリ上のストアにだけ入ります（端末のデータは書き換えません）。日付は今日から数えるので、いつ撮っても同じ残り日数になります
- 撮る画面はホーム・予定の詳細・予定の追加・推しの一覧です。画面の名前は書き出した `manifest.json` にあります。要素は言語によらないアクセシビリティ ID（`home.featuredEvent` など）で探します
- ステータスバーは 9:41・電池満タンにそろえます。iPad はステータスバーに日付も出るので、言語ごとに Simulator の言語・地域を変えて起動し直します。ふだんのテスト（CI を含む）では、このテストは飛ばされます

### 9. App Store の掲載文とスクリーンショットの登録

Actions タブの「App Store Metadata」を手動実行すると、言語ごとの掲載文（[docs/app-store/metadata/](docs/app-store/metadata/) の `<言語>.md` のアプリ名・サブタイトル・プロモーションテキスト・説明文・キーワード）と、[docs/app-store/review-notes.md](docs/app-store/review-notes.md) の審査用メモを、App Store Connect API で App Store バージョン（既定は `MARKETING_VERSION`）に登録します。スクリーンショットは表示サイズごとに別のジョブで並行して上の `scripts/app-store-screenshots.sh` で撮り、表示サイズ × 言語ぶんを差し替えます。

```bash
gh workflow run app-store-metadata.yml --ref develop
# 一部だけ撮る・撮るだけで登録しない
gh workflow run app-store-metadata.yml --ref develop -f display_types=APP_IPHONE_67 -f languages=ja,en -f upload=false
```

- 文面は各見出しの下のコードブロックから読みます。文字数の上限を超えていたら何も登録せずに止まります。`metadata/<言語>.md` が無い言語は飛ばします（ja は無ければ `listing.md` を読みます）
- アプリの主要言語は languages.json の先頭の言語（en-US）にそろえます
- 6.9 インチを撮ったときは、そのスクリーンショットからクリエイティブアセット（プロダクトページのヘッダー 3840x1646・検索結果 3840x2560）を [docs/app-store/creative/creative.html](docs/app-store/creative/creative.html) と `scripts/render-creative-assets.sh` で言語ごとに書き出し、App Asset Library に上げて各言語のローカリゼーションに配置します（`creative_assets` を外すと飛ばします）。文言は creative.html の `copy` に言語ごとに書きます
- iPhone Duo は GitHub の標準イメージ `xcode-27`（actions/runner-images の xcode-27-arm64。org で用意するものは無い）で撮ります。イメージに iOS 27.1 のランタイムが無いので、撮影の前にダウンロードします（数分かかります）
- 1 つの表示サイズの撮影が失敗しても、撮れたぶんと掲載文は登録します。撮った画像は Artifact（`screenshots-<表示サイズ>`）にも残ります
- 指定したバージョンが無ければ、審査前のバージョンの番号を変えます（新規アプリに最初からある「1.0」など）。それも無ければ作ります
- サポート URL・プライバシーポリシー URL・著作権・App Review の連絡先・カテゴリ・年齢制限・価格・App のプライバシー・ビルドの選択は扱いません。App Store Connect の画面で入れてから審査に提出します（提出もこのワークフローでは行いません）

### 10. テーマの見本

テーマ案（`Shared/Design/AppTheme.swift` の `AppTheme.all`）は、Preview・DEBUG のビルドの見本・テストの中だけで使います。出荷するアプリは既定のテーマ（`AppTheme.standard`）だけです。

- **Preview**: ウィジェット 2 種は `OshiCon/Screens/WidgetPreviews/WidgetPreviewFrame.swift` の `WidgetPreview.countdown(_:theme:)`・`upcoming(_:theme:)` で、ウィジェットの大きさの枠に入れて描けます。
  テーマ案の日本語の書体を使う Preview では、先に `PreviewFonts.registerIfNeeded()` を呼びます
- **DEBUG の見本**: DEBUG のビルドを起動引数 `-previewTheme <テーマの id>` で起動すると、アプリ全体にそのテーマを当て、テーマ案の書体を登録します（知らない id は既定のテーマ。リリースのビルドでは効きません）。
  Xcode では Scheme の Run の Arguments に `-previewTheme yumekawaPastel` のように足します
- **撮影**: 見本の推しと予定で、アプリの画面（ホーム・予定の詳細・予定の追加）とウィジェット 2 種を、ライトとダークで撮って `build/theme-screenshots/<テーマの id>/<light|dark>/` に書き出します。
  Simulator は言語を日本語にしたものを使います（ウィジェットの文言は Simulator の言語で出ます）

```bash
scripts/theme-screenshots.sh yumekawaPastel <Simulator の UDID>
```

- 画面は UI テスト `ThemeScreenshotTests`、ウィジェットは Unit テスト `ThemeWidgetScreenshotTests`（`ImageRenderer` で 3 倍の PNG）が撮ります。どちらも環境変数 `THEME_SCREENSHOTS=1` のときだけ流れ、ふだんのテスト（CI を含む）では飛ばされます。テーマは `THEME_ID` で選びます
- テーマ案の書体（Kiwi Maru・Zen Maru Gothic・Zen Kaku Gothic New の Light・Kaisei Decol・Mochiy Pop One。どれも SIL OFL 1.1）は google/fonts から取得したものを改変せずに `OshiCon/Preview Content/Fonts/` に置いています。
  `DEVELOPMENT_ASSET_PATHS` なので Archive（出荷物）には入らず、Widget Extension にも入りません。`UIAppFonts` とオープンソースライセンスの画面には足していません（採用したら出荷物へ移して足します）

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
├── Configs/                 # xcconfig（署名情報・バージョン・Deployment Target）
├── OshiCon/          # アプリ本体（SwiftUI）
├── OshiConTests/     # Unit テスト（Swift Testing）
├── OshiConUITests/   # UI テスト（XCTest）
├── OshiCon.xcodeproj # 共有スキーム OshiCon を含む
├── docs/                    # ExportOptions.plist のサンプル
├── scripts/                 # rename.sh・app-store-screenshots.sh（App Store 用スクリーンショット）・render-creative-assets.sh（クリエイティブアセット）
├── .swiftlint.yml           # SwiftLint 設定
└── .github/
    ├── ISSUE_TEMPLATE/      # Issue テンプレート
    ├── pull_request_template.md
    ├── scripts/             # check-app-store-app.rb（App Store Connect のアプリの有無を確認）・embed-entitlements.rb（Archive に Entitlements を埋め込む）・app-store-metadata/（掲載文とスクリーンショットの登録）・creative-assets/（クリエイティブアセットの配置）
    └── workflows/
        ├── _build.yml       # 共通処理: ビルド + テスト + SwiftLint（workflow_call）
        ├── _archive.yml     # 共通処理: Archive → Export（→ Upload）（workflow_call）
        ├── build.yml        # 全ブランチの push / Fork からの PR
        ├── archive.yml      # main の push
        ├── upload.yml       # develop / release/** の push
        └── app-store-metadata.yml # 掲載文とスクリーンショットの登録（手動実行）
```

- プロジェクトはフォルダ同期グループ（Xcode 16 以降の形式）で管理しているため、ファイルの追加・削除で pbxproj は変わりません
- SwiftLint は Build Tool Plugin として全ターゲットに適用され、CI では `swiftlint lint --strict` としても実行されます。ルールは [.swiftlint.yml](.swiftlint.yml) で管理します
- CI のワークフローは `*.xcodeproj` の名前と同名の共有スキームが存在することを前提にしています
- [OshiCon/PrivacyInfo.xcprivacy](OshiCon/PrivacyInfo.xcprivacy) と [OshiConWidget/PrivacyInfo.xcprivacy](OshiConWidget/PrivacyInfo.xcprivacy) はプライバシーマニフェストです。アプリは UserDefaults（`@AppStorage`）の利用だけを申告し、Widget Extension は何も申告していません。データの収集・トラッキング・ほかの理由の申告が必要な API を足したら、ここと App Store Connect の「App のプライバシー」を更新してください

## License

[MIT License](LICENSE)
