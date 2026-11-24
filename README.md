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
| `MARKETING_VERSION` | アプリのバージョン。ビルド番号（`CURRENT_PROJECT_VERSION`）は Upload のときに Upload ワークフローの実行番号（`github.run_number`）で上書きするため、手で上げる必要はありません |
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

- 作業は `develop` から作業ブランチを切ります。AskHub の epic は、ワーカーが作業ブランチ `askhub/<epic の id>` を `develop` から作り、子 PR をそこに集め、最終 PR で `develop` に取り込みます
- `develop`・`main`・`release/**` は、ルールセットで PR 必須・`build / build` 必須・force push と削除の禁止にしています。管理者にも効くので、直接 push はできません

| ブランチ | Build（ビルド + テスト + SwiftLint） | Archive（IPA Export） | Upload（App Store Connect） |
|---|:-:|:-:|:-:|
| `main` | ✅ | | |
| `develop` | ✅ | | ✅ |
| `release/**` | ✅ | | ✅ |
| その他の作業ブランチ | ✅（Unit テストのみ） | | |
| Pull Request の作成時（opened / reopened / ready_for_review） | ✅ | | |
| AskHub の子 PR（作業ブランチ `askhub/**` 宛て） | PR では実行しない（push の Unit テストだけ） | | |
| AskHub の最終 PR（`askhub/**` → `develop`） | ✅（更新のたびに UI テストまで） | | |
| Fork からの Pull Request | ✅ | | |
| 手動実行（Actions タブの Run workflow） | | ✅ | ✅ |

- `main` への push で動くのは Build だけです。Archive は動かしません
- Upload は Archive → IPA Export を含むため、`develop` / `release/**` では Archive を別途実行しません
- Archive は Actions タブからの手動実行（Run workflow）だけで動きます。署名と IPA Export が通ることを確かめたいときに、ブランチを選んで実行します
- Upload も Actions タブから手動で実行できます。作業ブランチを TestFlight で確認したいときは、Upload を手動実行してそのブランチを選びます
- リポジトリ変数（Settings → Secrets and variables → Actions → Variables）に `ENABLE_DELIVERY=false` を設定すると Upload をスキップします（Archive は App Store Connect にアプリが無くても通るため止めません）。テンプレートリポジトリ自身はこの設定でアップロードを止めています。テンプレートから作成したリポジトリには引き継がれないため、何もしなければ従来どおり実行されます
- Build はドキュメントだけの変更でも実行します。ルールセットで `build / build` を必須にしているため、飛ばすとチェックが出ず、PR をマージできなくなります
- 作業ブランチへの push では、時間のかかる UI テスト（`<プロジェクト名>UITests`）を省いて Unit テストだけ実行します。UI テストは Pull Request の作成時と `main` / `develop` / `release/**` への push で実行します。AskHub の子 PR（`askhub/**` 宛て）は PR のイベントでは実行せず（ワーカーが手元でテストを流してから出すため）、作業ブランチ → `develop` の最終 PR は更新（synchronize）でも UI テストまで実行します。Fork からの Pull Request は push で実行されないため、更新（synchronize）を含むすべてのイベントで UI テストまで実行します
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
- 見本の推しには、フリー素材を加工した写真を付けます。画像は UI テストのバンドル（`OshiConUITests/SampleOshiPhotos/`）にあり、アプリには入りません。出典・ライセンスと、差し替えるときに守ることは [docs/app-store/sample-oshi-photos.md](docs/app-store/sample-oshi-photos.md) にあります
- 撮る画面はホーム・予定の詳細・予定の追加・推しの一覧です。画面の名前は書き出した `manifest.json` にあります。要素は言語によらないアクセシビリティ ID（`home.featuredEvent` など）で探します
- ステータスバーは 9:41・電池満タンにそろえます。iPad はステータスバーに日付も出るので、言語ごとに Simulator の言語・地域を変えて起動し直します。ふだんのテスト（CI を含む）では、このテストは飛ばされます

### 9. App Store の掲載文とスクリーンショットの登録

Actions タブの「App Store Metadata」を手動実行すると、言語ごとの掲載文（[docs/app-store/metadata/](docs/app-store/metadata/) の `<言語>.md` のアプリ名・サブタイトル・プロモーションテキスト・説明文・キーワード）・マーケティング URL と、このバージョンの新機能（[docs/app-store/whats-new/](docs/app-store/whats-new/) の `<バージョン>.md`）、[docs/app-store/review-notes.md](docs/app-store/review-notes.md) の審査用メモを、App Store Connect API で App Store バージョン（既定は `MARKETING_VERSION`）に登録します。スクリーンショットは表示サイズごとに別のジョブで並行して上の `scripts/app-store-screenshots.sh` で撮り、表示サイズ × 言語ぶんを差し替えます。

```bash
gh workflow run app-store-metadata.yml --ref develop
# 一部だけ撮る・撮るだけで登録しない
gh workflow run app-store-metadata.yml --ref develop -f display_types=APP_IPHONE_67 -f languages=ja,en -f upload=false
```

- 文面は各見出しの下のコードブロックから読みます。文字数の上限を超えていたら何も登録せずに止まります。`metadata/<言語>.md` が無い言語は飛ばします（ja は無ければ `listing.md` を読みます）
- アプリの主要言語は languages.json の先頭の言語（en-US）にそろえます
- マーケティング URL は全言語で同じで、[docs/app-store/listing.md](docs/app-store/listing.md) の「マーケティング URL」のコードブロックから読み、登録するたびに全言語に入れます。App Store Connect は新しいバージョンに前のバージョンの値を写すので、URL を変えたら画面ではなくこのファイルを直して登録し直します。https の URL でなければ、何も登録せずに止まります
- このバージョンの新機能は、登録するバージョンと同じ名前のファイル（`docs/app-store/whats-new/1.1.0.md` など）の `## <言語>` の下のコードブロックから読みます。アップデートを出すたびに新しいファイルを足します。ファイルが無ければ新機能は触りません（最初のバージョンには入れられないため）。ファイルがあるのに登録する言語の見出しが無いときは、何も登録せずに止まります
- 6.9 インチを撮ったときは、そのスクリーンショットからクリエイティブアセット（プロダクトページのヘッダー 3840x1646・検索結果 3840x2560）を [docs/app-store/creative/creative.html](docs/app-store/creative/creative.html) と `scripts/render-creative-assets.sh` で言語ごとに書き出し、App Asset Library に上げて各言語のローカリゼーションに配置します（`creative_assets` を外すと飛ばします）。文言は creative.html の `copy` に言語ごとに書きます
- iPhone Duo は GitHub の標準イメージ `xcode-27`（actions/runner-images の xcode-27-arm64。org で用意するものは無い）で撮ります。イメージに iOS 27.1 のランタイムが無いので、撮影の前にダウンロードします（数分かかります）
- 1 つの表示サイズの撮影が失敗しても、撮れたぶんと掲載文は登録します。撮った画像は Artifact（`screenshots-<表示サイズ>`）にも残ります
- 指定したバージョンが無ければ、審査前のバージョンの番号を変えます（新規アプリに最初からある「1.0」など）。それも無ければ作ります
- サポート URL・プライバシーポリシー URL・著作権・App Review の連絡先・カテゴリ・年齢制限・価格・App のプライバシー・ビルドの選択は扱いません。App Store Connect の画面で入れてから審査に提出します（提出もこのワークフローでは行いません）

### 10. 課金の商品の登録

Actions タブの「App Store In-App Purchases」を手動実行すると、[docs/app-store/in-app-purchases.json](docs/app-store/in-app-purchases.json) の課金の商品（推し活カウントダウン Plus の月額・年額のサブスクリプションと、買い切りの非消耗型）を App Store Connect API で登録します。
既定は確認だけで、何も作りません。**productId は一度作ると変えられず、消しても同じ ID は使えない**ので、確認の結果（Job Summary）を見てから `apply` を付けて作ります。

```bash
# 確認だけ（作るもの・入れるものを表示する）
gh workflow run app-store-purchases.yml --ref develop
# 作る
gh workflow run app-store-purchases.yml --ref develop -f apply=true
```

- サブスクリプショングループは `referenceName`、商品は `productId` で探し、無ければ作ります。何度流しても二重には作りません。途中で失敗したら、直してから流し直すと続きから入れます
- 表示名と説明は 12 言語（[docs/app-store/languages.json](docs/app-store/languages.json)）ぶん入れます。言語が足りない・文字数（表示名 30 文字・説明 45 文字）を超えるときは、何も登録せずに止まります
- 価格は `baseTerritory`（日本）の税込みの価格で、ほかの国・地域は App Store Connect の換算に合わせます。その価格が日本の価格の刻みに無ければ、近い価格を出して止まります
- 販売地域はすべての国・地域と、新しく増える国・地域です。年額には 1 週間の無料のお試しを付けます。ファミリー共有は OFF です（一度 ON にすると戻せません）
- サブスクリプションの販売地域・価格・お試しは、すでに入っているものを変えません（価格の変更は App Store Connect の画面で行います）。非消耗型の価格は毎回入れ直します（同じ価格なら変わりません）
- 審査用のスクリーンショット（課金画面）と審査への提出は扱いません。課金画面ができてから App Store Connect の画面で入れます。最初の課金の商品は、アプリの新しいバージョンと一緒に審査に出します

#### 手元での課金の確かめ方

- [Configs/OshiCon.storekit](Configs/OshiCon.storekit) は、`in-app-purchases.json` と同じ商品（サブスクリプショングループ OshiCon Plus の年額 1,980 円・1 週間の無料のお試し、月額 280 円、非消耗型の買い切り 4,800 円。ファミリー共有は OFF、表示名と説明は 12 言語）を入れた StoreKit Configuration ファイルです。
  ストアフロントは日本です。共有スキーム OshiCon の Run（Options の StoreKit Configuration）と Test（テストプラン [OshiCon.xctestplan](OshiCon.xctestplan) の StoreKit Configuration）に設定してあり、Simulator では App Store Connect に繋がずに購入・復元・期限切れを試せます（Xcode の Debug → StoreKit → Manage Transactions）
- 商品を変えたら `in-app-purchases.json` と `.storekit` の両方を直します（`StoreKitConfigurationTests` が食い違いを見つけます）
- UI テストとスクリーンショット（`-useInMemoryStore` のとき）は StoreKit に問い合わせず、Plus は使えない状態に固定します。起動引数 `-plusUnlocked` で使える状態に、`-plusLocked` で使えない状態にします（`LaunchOptions.unlocksPlus`。両方渡したときは `-plusLocked` を優先します）
- 課金画面の入口（設定の Plus の行）は、1.3.0 から App Store 版を含むどの配り方でも出します（`PlusEntryPolicy`。それまでは開発版と TestFlight だけ。配り方は `AppTransaction` の環境で端末の中で見分けます）。
  起動引数 `-simulateAppStoreDistribution`（`-useInMemoryStore` のときだけ効く）で App Store 版として動かします。App Store 用スクリーンショットはこれを渡します

### 11. テーマ

出荷するアプリとウィジェットは、Discussion #80 のテーマ案から採用した「地雷系・ゴシック」（`AppTheme.shipping` = `AppTheme.jiraiGothic`）だけを使います。
採用しなかった案は片付け、アイデアは shilokuma-inc/design-knowledge に残しました。配色・書体・コントラストと、採用でしたこと・残っていることは [docs/design/themes.md](docs/design/themes.md) にまとめています。

- **Preview**: `OshiCon/Screens/ThemePreviews/JiraiGothicPreviews.swift` にあります（ホーム・予定の詳細・予定の追加・ウィジェット 2 種を、ライトとダーク・大きな文字・横向きで）。
  どれも `ThemePreviewCanvas(<テーマ>, <画面>, <外観>)` で描き、日本語の見本の推しと予定をメモリ上のストアに入れます。
  テーマの日本語の書体はアプリの言語が日本語のときだけ使われるので、Scheme の Run の Options の App Language を日本語にして見ます。
  ウィジェット 3 種は `OshiCon/Screens/WidgetPreviews/WidgetPreviewFrame.swift` の `WidgetPreview.countdown(_:theme:)`・`upcoming(_:theme:)`・`photo(_:family:photo:renderingMode:theme:)` で、ウィジェットの大きさの枠に入れて描けます（推しの写真は tinted の描き方も渡せます）
- **書体**: Kaisei Decol（SIL OFL 1.1）は google/fonts から取得したものを改変せずに `Shared/Resources/Fonts/` に置き、アプリと Widget Extension の `UIAppFonts`・オープンソースライセンスの画面に載せています
- **ナビゲーションバーのタイトル**: 日本語のときだけ Kaisei Decol の太字にし、ほかの言語はシステムの書体のままです（バーの外観で書体だけを替える。`OshiCon/App/NavigationBarAppearance.swift`）。ホームのバーにはタイトルの文字を出しません（Discussion #148。決まりは [docs/design/themes.md](docs/design/themes.md)）

### 12. 推しの写真の調整

推しの登録・編集で写真を選ぶと、調整画面（拡大・縮小・移動・回転）で丸の枠に写す範囲を決めてから取り込みます（Discussion #128）。仕様とコードの場所は [docs/photo-crop.md](docs/photo-crop.md) にまとめています。

- 正方形に切り抜いた画像（一辺 1440px まで）だけを保存します。予定の詳細の横長の写真は、その正方形の中央の帯を出します
- 拡大は、切り抜く範囲の一辺が元の写真の 360px を下回らないところまで。回転しても枠の隅が空かないよう補正します
- この機能より前に登録した写真はそのまま残します。保存してある写真は「位置を調整」で、さらに狭める調整だけができます
- 仕様の正は [docs/spec/features/07-photo-crop.md](docs/spec/features/07-photo-crop.md)（仕様リポジトリ app-specs から生成したもの）です
- UI テストでは、起動引数 `-useTestPhoto`（`-useInMemoryStore` のときだけ効く）で「写真を選ぶ」を生成した画像を選ぶボタンに替えます（`PhotosPicker` は UI テストから操作できないため）

### 13. 画像でシェア

予定の詳細のツールバーの「画像でシェア」から、予定の「あと○日」を正方形のカードの画像（1080 × 1080 px の PNG）にして共有シートで渡します（1.3.0 から。無料）。仕様とコードの場所は [docs/share-card.md](docs/share-card.md) にまとめています。

- コードは `OshiCon/Share/` にあります（中身の規則 `ShareCardContent`・見た目の差し替え口 `ShareCardStyle`・カード `ShareCardView`・書き出し `ShareCardRenderer`・プレビュー画面 `ShareCardPreviewScreen`）
- プレビュー画面で会場（既定で載せない）と推しの写真（既定で載せる）を切り替えてからシェアします。推しの名前は載せず、透かしに言語ごとのブランド名（App Store の名前のコロンより前）を入れます
- 画像は端末の中で作り、通信しません。共有シートの「画像を保存」のため、Info.plist に `NSPhotoLibraryAddUsageDescription`（写真への追加の説明）を置いています
- Plus の人で着せ替えの背景の写真を ON にしていると、`ShareCardStyle` の `background` を `.photo(fileName:)` にしてカードの地をその写真に替えます（`ShareCardStyle.appearance(_:)`）
- テスト: Unit は `OshiConTests/Share/`（`ShareCardContentTests`・`ShareCardRendererTests`・`ShareCardSharingTests`）、UI は `OshiConUITests/ShareCardUITests`（`-useInMemoryStore -useTestPhoto`。識別子は `eventDetail.share`・`shareCard.preview`・`shareCard.includesVenue`・`shareCard.includesPhoto`・`shareCard.share`）。共有シートそのものは UI テストから開けません

### 14. 着せ替え（Plus）

推し活カウントダウン Plus で、ホームと予定の詳細の地を着せ替えます（1.3.0 から）。仕様・コードの場所・テストの口・実機で確かめることは [docs/appearance.md](docs/appearance.md) にまとめています。

- **背景**: アプリ全体で 1 枚の写真を約 9:19.5 の縦長の枠で調整して保存し、暗幕とぼかし（それぞれスライダーで調整）を掛けて地に敷きます。幕の色はライトでは地の色、ダークでは黒です。iPad と横向きでは写真を中央に置き、左右を同じ写真の強いぼかしで埋めます
- **飾り**: 地のハートと十字を、写真を登録した推しの丸い写真に順に替えます（写真の無い推しのところは今の模様のまま）
- コードは `OshiCon/Appearance/`（規則・ストア・地の View）と `OshiCon/Screens/Appearance/`（着せ替えの画面・ホームの見本）にあります。
  設定は UserDefaults（`AppStorageKey.appearance*`）、背景の写真は推しの写真と同じ App Group の置き場所に置き、SwiftData のスキーマは変えていません
- 設定画面の「着せ替え」の行は、Plus の行と同じく 1.3.0 から App Store 版でも出します（`PlusEntryPolicy`）。Plus でない人も写真を選んで試着・保存でき、Plus でなければホームと詳細は標準の見た目のままです（写真と設定は残します）
- テスト: Unit は `OshiConTests/Appearance/`、UI は `OshiConUITests/AppearanceUITests`（`-useInMemoryStore -useTestPhoto` と `-plusLocked`・`-plusUnlocked`・`-simulateAppStoreDistribution`）。
  ホームと詳細に効いたかは、メモリ上のストアのときだけ置く `home.appearance`・`eventDetail.appearance` のラベルで確かめます

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
