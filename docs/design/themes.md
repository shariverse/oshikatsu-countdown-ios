# テーマ（Discussion #80）

推し活カウントダウンの見た目（地の配色・角の丸み・書体・装飾）は、テーマ `AppTheme`（`Shared/Design/AppTheme.swift`）にまとめています。依頼は Issue #79、決定は Discussion #80 にあります。

**5 つの案から「地雷系・ゴシック」（`jiraiGothic`）を採用し、出荷するアプリとウィジェットの見た目にしました（Issue #114）。**
採用の形は「1 案で既定のデザインを置き換える」で、設定でテーマを選ぶ仕組みは作っていません。出荷するテーマは `AppTheme.shipping`（= `jiraiGothic`）です。

採用しなかった案（採用前のデザインの標準のテーマと、ゆめかわパステル・量産型ガーリー・韓国風ミニマル・アイドル・ペンライト）は、このリポジトリから片付けました（Issue #117）。
狙い・配色・書体・装飾・仮決めは [shilokuma-inc/design-knowledge](https://github.com/shilokuma-inc/design-knowledge/pull/4) に残しています。
片付ける前の 5 案のコードと、この文書の 5 案の一覧は、[2e2fb4b の時点のもの](https://github.com/shariverse/oshikatsu-countdown-ios/blob/2e2fb4bee9bd93fcb072d2df6acbd659162de504/docs/design/themes.md)にあります。

## 共通の決まり

- **推し色が主役**（Q4）: 推し色の役割（先頭のカードの塗り・写真が無いときの模様の色・残り日数の文字・印）と値（`OshiColor.rgb`）はテーマで変えません。テーマが変えるのは地・形・装飾・書体と、推し色の文字を地に合わせて寄せる割合だけです
- **テーマカラー**（#209）: テーマのピンク（地・装飾・アクセント）は、1 位の推しの推し色で染めます（下の「テーマカラー」）
- **ライトとダーク**: 両方を持ちます（`AdaptiveColor`）
- **書体**（Q5）: 日本語の本文だけテーマの書体にし、ほかの 11 言語はシステムの書体のまま。数字は Outfit（可変フォント）を太さを変えて使います
- **ナビゲーションバーのタイトル**（Discussion #148 の Q2〜Q4）: 日本語のときだけテーマの書体の太字（Kaisei Decol Bold）にし、ほかの 11 言語はシステムの書体のまま。
  バーの外観（`UINavigationBar.appearance()` の `titleTextAttributes`・`largeTitleTextAttributes` の `.font`）で書体だけを替え、アプリの起動時に 1 か所で設定します（`OshiCon/App/NavigationBarAppearance.swift`。書体を決めるのは `Shared/Design/BarTitleFace.swift`）。
  大きいタイトル（推し・設定）・スクロールで小さくなる動き・戻るボタン・Liquid Glass のバー・地は標準のまま。大きさは iOS の標準のタイトルにそろえ、大きいタイトルはダイナミックタイプの文字の大きさに合わせて大きくし（起動時の大きさ）、inline（シート・ライセンスなど）は文字の大きさに関わらず 17pt のままにします（標準の inline タイトルも大きくならず、高さの決まったバーの中で大きくすると切れるため。Issue #158）。タイトルにハートなどの装飾は付けません。バーのボタン・戻るボタン・タブバーの文字はシステムの書体のままです
- **ホームの見出し**（Discussion #148 の Q1・Q5）: iOS ではホームのバーにタイトル（「推し活カウントダウン」）の文字を出さず、右上の ＋ だけにします（大きいタイトルの帯も無くし、先頭のカードを上に詰める）。
  タブバーの「ホーム」で場所は分かるため。VoiceOver の画面の名前・UI テスト・戻り先の名前のために `.navigationTitle` は残し、見た目だけ消しています（iOS 18 以降は `toolbar(removing: .title)`、iOS 17 は `.principal` の見えない要素）。
  iPad のサイドバーの見出し「推し活カウントダウン」はアプリ名として残します。Android 版でも同じ形にするかは、仕様リポジトリ app-specs のロードマップで検討中にしてあります
- **装飾**: SwiftUI の図形・`Canvas`・SF Symbols で描き、画像の素材は使いません。`accessibilityHidden(true)`・`allowsHitTesting(false)` で、読み上げ・押せる範囲・並びを変えません。カードの中の文字の上には重ねません
- **ウィジェット**: 配色と書体はテーマが効きます。装飾（縁取りなど）はアプリの画面だけで、ウィジェットには入れていません
- **コントラスト**: `PaletteContrastTests` が出荷するテーマ（と 12 色で染めたテーマ）のライト / ダークで回ります（推し色 12 色の文字が画面の地・カードの地・入力欄の地で 4.5:1 以上、本文と補助テキストが模様を重ねた地でも 4.5:1 以上、brand の文字・選択中の印の地の本文が 4.5:1 以上 など）

## 見方

- **Preview**: `OshiCon/Screens/ThemePreviews/JiraiGothicPreviews.swift`（ホーム・予定の詳細・予定の追加・ウィジェット 2 種を、ライト / ダーク・大きな文字・横向きで）。日本語の書体を見るときは、Scheme の Run の Options の App Language を日本語にします
  - どれも `ThemePreviewCanvas(<テーマ>, <画面>, <外観>)` で描き、日本語の見本の推しと予定をメモリ上のストアに入れます
  - ウィジェット 3 種は `OshiCon/Screens/WidgetPreviews/WidgetPreviewFrame.swift` の `WidgetPreview.countdown(_:theme:)`・`upcoming(_:theme:)`・`photo(_:family:photo:renderingMode:theme:)` で、ウィジェットの大きさの枠に入れて描けます（推しの写真は tinted の描き方も渡せます）

## 地雷系・ゴシック（`jiraiGothic`）

- 狙い: 黒 × ピンクで、ダークが主役。ライトも薄いピンクの地に黒の文字・黒の縁取りで世界観が分かるようにする。装飾的な明朝でゴシックの雰囲気を出す
- 本文の書体: Kaisei Decol（Regular / Bold。Medium は Regular に寄せる）。数字: Outfit Heavy
- 角の丸み（先頭のカード・まとまり・詳細・札）: 16・12・20・4
- 装飾: ホームの地に十字とハート（不透明度 0.35）・カードに二重の線（外 1.5pt・4pt 内側に 1pt）・見出しの前にハート・写真が無いときは推し色を黒に寄せた地に白い十字とハート
- PR: #105（案）・#115（採用。Issue #114）
- 画面: 設定・予定と推しの編集・ライセンスの一覧の Form / List の行の地も、カードの地（`surface`）にそろえています（`themeRowBackground()`）。採用前はシステムの既定の地で、ダークでは灰色でした

| 役割 | ライト | ダーク |
| --- | --- | --- |
| background | `#FFF0F5` | `#120D12` |
| 十字・ハート | `#F2B6CF` | `#4A2A3C` |
| surface / surfaceContainer / surfaceContainerHigh | `#FFFFFF` / `#FBE4EE` / `#F0C9DA` | `#1E141C` / `#180F16` / `#3A2533` |
| onSurface / onSurfaceVariant / outlineVariant | `#1A0F16` / `#5A3A4C` / `#E8B9CF` | `#F6E6EE` / `#D6B9C8` / `#5C3A4E` |
| brand / onBrand | `#C2185B` / `#FFFFFF` | `#FF7EB3` / `#3A0A20` |
| brandContainer / onBrandContainer | `#F8C8DC` / `#1A0F16` | `#6E1E45` / `#FFD9E8` |
| destructive | `#B3261E` | `#F2B8B5` |
| 二重の線 / 見出しのハート | `#1A0F16` / `#C2185B` | `#FF7EB3` / `#FF7EB3` |

## テーマカラー（1 位の推しの推し色。#209）

推しの一覧のいちばん上の推し（1 位の推し。並べ替えは #208）の推し色で、テーマのピンクを染めます（`AppTheme.shipping(themeColor:)`。`Shared/Design/AppTheme+ThemeColor.swift`）。
地雷系・ゴシックの「黒 × ピンク」が「黒 × 1 位の推しの推し色」になります。無料の機能です（Plus にしない）。

- 染めるもの: 地（background・surfaceContainer・surfaceContainerHigh。ライトの surface の白はそのまま）・本文と補助テキストのわずかな色み・区切り線・アクセント（brand・onBrand・brandContainer・onBrandContainer）・装飾の色（十字とハート・二重の線・見出しのハート）
- 変えないもの: 削除の文字（destructive）・推し色の役割と値・推し色の文字を地に合わせる割合・角の丸み・書体・装飾の形
- 推しがいないときと、1 位の推しがピンクのときは、今までの配色とまったく同じ
- 効く場所: アプリの画面（`RootView` が 1 位の推しを読み、`appTheme` に入れる）と、ホーム画面のウィジェット（エントリが 1 位の推しの推し色を持つ）。ロック画面のウィジェットは端末が単色で描くので変わらない。ライブアクティビティはテーマの色を使っていない（推し色と書体だけ）ので変わらない
- 描き直し: 並べ替え・推し色の変更・推しの削除は保存のきっかけ（`ModelContext.didSave`）でウィジェットを描き直す

### 染め方

テーマの色ごとに、基準のピンク（推し色のピンク `#C8326A`）をどれだけ含むかを求め、その分だけ 1 位の推しの推し色との差を足します（`RGBColor.retinted(from:to:)`）。
含む割合は、その色の R・G・B を基準のピンクの R・G・B に直線で当てはめたときの傾きです（白・黒・灰色は 0、ピンクそのものは 1、ピンクを薄めた色はその間）。
地雷系・ゴシックのピンクは推し色のピンクに合わせてあるので、ピンクで染めると元の配色に戻ります。色ごとに手で値を決めず、1 つの計算で 12 色を作ります。

下の表は染めた色の目安（ライト / ダーク）です。

| 1 位の推しの推し色 | background | brand | brandContainer | 十字・ハート |
| --- | --- | --- | --- | --- |
| ピンク（推しがいないときも） | `#FFF0F5` / `#120D12` | `#C2185B` / `#FF7EB3` | `#F8C8DC` / `#6E1E45` | `#F2B6CF` / `#4A2A3C` |
| レッド | `#FFF0EF` / `#120D10` | `#CB1B14` / `#FF817D` | `#FBC9C8` / `#722024` | `#F5B7B6` / `#4C2B2F` |
| オレンジ | `#FDF4EC` / `#110E0F` | `#AB4500` / `#EEA064` | `#F2D5BF` / `#643315` | `#EAC6AA` / `#463229` |
| イエロー | `#F9F6EA` / `#100F0F` | `#7C5B00` / `#CAB058` | `#E4DBBA` / `#4E3D0E` | `#D9CDA5` / `#3D3626` |
| グリーン | `#EDF7F2` / `#0D0F11` | `#00693E` / `#6ABC9D` | `#C1DFD4` / `#134437` | `#ADD3C5` / `#263937` |
| ミント | `#ECF7F8` / `#0C0F13` | `#006C7B` / `#60BDCB` | `#BDE0E5` / `#0D4554` | `#A8D3DA` / `#243942` |
| ブルー | `#F0F6FF` / `#0D0F15` | `#155DD5` / `#7CB2FF` | `#C7DBFE` / `#1E3E7E` | `#B5CEFA` / `#2A3752` |
| ネイビー | `#F1F3FD` / `#0E0E14` | `#2334B3` / `#8693F6` | `#CBD0F5` / `#242B6E` | `#BAC0EE` / `#2D2F4C` |
| パープル | `#F7F3FF` / `#100E15` | `#6A34CE` / `#BC93FF` | `#DFD0FC` / `#452B7A` | `#D3C0F8` / `#3A2F51` |
| ラベンダー | `#FBF1FC` / `#110D14` | `#9727AA` / `#DF89EF` | `#ECCCF2` / `#5A256A` | `#E3BBEB` / `#422D4A` |
| ブラウン | `#F6F4F2` / `#0F0E11` | `#594638` / `#B0A199` | `#DAD5D2` / `#3D3335` | `#CDC6C3` / `#373236` |
| ブラック | `#F1F1F1` / `#0E0D11` | `#221F2E` / `#868391` | `#CBCACF` / `#242130` | `#BAB8BF` / `#2D2B34` |

### コントラスト

`PaletteContrastTests` は、推しがいないときのテーマと 12 色で染めたテーマの 13 通りで回ります。12 色のどれが 1 位でも、ほかの推しの推し色の文字を含め、今までと同じ組み合わせで 4.5:1 以上です。
いちばん小さいのは、1 位がブラックのとき、オレンジの推し色の文字を入力欄の地（ライト）に置いた 4.65 です（染めないときは 4.85）。

## 推し色の文字のコントラスト

ライトの地が薄いピンクなので、ライトの推し色の文字を少し黒に寄せて 4.5:1 を保ちます（ダークは 45% 白に寄せる）。
下の最小値は、推し色 12 色の文字を画面の地・カードの地・入力欄の地に置いたときのいちばん小さい比です（`PaletteContrastTests` と同じ組み合わせ）。

| 黒に寄せる割合（地・カード / 入力欄） | ライトの最小 | ダークの最小 |
| --- | --- | --- |
| 0.08 / 0.12 | 4.85（オレンジ・入力欄） | 5.77（ブラック・カード） |

## 書体

[google/fonts](https://github.com/google/fonts) のコミット `47d54ca1ebb14fd864695f1d39dc734f39017c33` から取得し、改変せずに置いています（SIL Open Font License 1.1。ライセンス文は書体と同じフォルダの `KaiseiDecol-OFL.txt`）。
`Shared/Resources/Fonts/` に置き、アプリと Widget Extension の両方に入れて `UIAppFonts` で登録します。オープンソースライセンスの画面にも載せています。

| 書体（google/fonts のフォルダ） | ファイルと大きさ（バイト） |
| --- | --- |
| Kaisei Decol（`ofl/kaiseidecol`） | `KaiseiDecol-Regular.ttf`（4,503,152）・`KaiseiDecol-Bold.ttf`（4,286,896） |

採用前の本文の書体 Zen Kaku Gothic New は、出荷するテーマで使わないので外しました（Issue #117。アプリと Widget Extension でそれぞれ約 7 MB 減る）。

## 採用でしたこと・残っていること

1. **採用の形**（Q1）: 地雷系・ゴシックの 1 案で既定のデザインを置き換えた（Issue #114）。設定でテーマを選ぶ仕組み（Q6 の App Group での共有・`1C8F.1` の申告）は作っていない
2. **書体を出荷物へ移す**: Kaisei Decol を `Shared/Resources/Fonts/` へ移し、アプリと Widget Extension の `UIAppFonts`・オープンソースライセンスの画面に足した（Issue #114）。
   容量はアプリと Widget Extension でそれぞれ約 8.8 MB 増える
3. **デザインキャンバス**（Q8）: 元のキャンバス「推し活カウントダウン 画面デザイン」は変えずに、地雷系・ゴシックのキャンバスを別に足す（人間の作業。未）
4. **仕様**（Q2）: テーマの仕様の正は、仕様リポジトリ `shariverse/app-specs` の `design/jirai-gothic.md`（このリポジトリでは [`docs/spec/design/jirai-gothic.md`](../spec/design/jirai-gothic.md)）。Android 版に入れるかは app-specs のロードマップで検討中
5. **App Store 用スクリーンショット**: 見た目が変わったので撮り直す（Issue #116）。Discussion #148 でホームのタイトルが無くなり、バーのタイトルの書体も変わった
6. **不採用の案**: 標準のテーマと残りの 4 案を [shilokuma-inc/design-knowledge](https://github.com/shilokuma-inc/design-knowledge/pull/4) に残し、このリポジトリから片付けた（Issue #117）。
   値・Preview・装飾・案を比べる見本・DEBUG の `-previewTheme`・撮影の仕組み・Preview 用の書体と、出荷するテーマで使っていない Zen Kaku Gothic New を消した
7. **バーのタイトルの実機での確認**（Discussion #148）: iOS 17〜18 での効き方・ホームのタイトルの隠れ方・実機の VoiceOver・動いている途中に文字の大きさを変えたときの大きいタイトルの大きさは、Simulator で確かめられず Issue #152 に残している
