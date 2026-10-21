# テーマ案（Discussion #80）

推し活カウントダウンの見た目（地の配色・角の丸み・書体・装飾）を変える 5 つの案です。依頼は Issue #79、決定は Discussion #80 にあります。

**出荷するアプリは既定のテーマ（`AppTheme.standard`。今のデザイン）のままです。**
5 案は Preview・DEBUG のビルドの見本（`-previewTheme`）・テストの中だけで使い、どれを採用するか（採用の形・何案残すか）は人間が見て決めます（Q1）。

## 共通の決まり

- **推し色が主役**（Q4）: 推し色の役割（先頭のカードの塗り・写真が無いときの模様の色・残り日数の文字・印）と値（`OshiColor.rgb`）はどの案でも変えません。テーマが変えるのは地・形・装飾・書体と、推し色の文字を地に合わせて寄せる割合だけです
- **ライトとダーク**: どの案も両方を持ちます（`AdaptiveColor`）
- **書体**（Q5）: 日本語の本文だけ案ごとの書体にし、ほかの 11 言語はシステムの書体のまま。数字はどの案も Outfit（可変フォント）を太さを変えて使います
- **装飾**: SwiftUI の図形・`Canvas`・SF Symbols で描き、画像の素材は使いません。`accessibilityHidden(true)`・`allowsHitTesting(false)` で、読み上げ・押せる範囲・並びを変えません。カードの中の文字の上には重ねません
- **ウィジェット**: 配色と書体はテーマが効きます。装飾（縁取り・数字の光など）はアプリの画面だけで、ウィジェットには入れていません
- **コントラスト**: `PaletteContrastTests` が `AppTheme.all` のすべての案 × ライト / ダークで回ります（推し色 12 色の文字が画面の地・カードの地・入力欄の地で 4.5:1 以上、本文と補助テキストが模様を重ねた地でも 4.5:1 以上、brand の文字・選択中の印の地の本文が 4.5:1 以上、数字の光と数字が 3:1 以上 など）

## 見方

- **並べて比べる**: `OshiCon/Screens/ThemePreviews/ThemeComparisonBoard.swift` の Preview「テーマ案を並べる・ライト / ダーク」。既定のテーマと 5 案を横に並べ、ホームの先頭のカードとこれからの予定・ウィジェット 2 種を描きます
- **案ごと**: `OshiCon/Screens/ThemePreviews/<案>Previews.swift`（ホーム・予定の詳細・予定の追加・ウィジェット 2 種を、ライト / ダーク・大きな文字・横向きで）
- **実際の画面**: DEBUG のビルドを `-previewTheme <id>` で起動します（Xcode の Scheme の Run の Arguments）。日本語の書体を見るときは App Language を日本語にします
- **撮る**: README の「テーマの見本」（`scripts/theme-screenshots.sh <id> <UDID>`、並べた見本は `ThemeComparisonScreenshotTests`）

## 各案

| 案 | id | 方向性 | 本文の書体 | 数字 | 角の丸み（先頭のカード・まとまり・詳細・札） |
| --- | --- | --- | --- | --- | --- |
| 標準（今のデザイン） | `standard` | — | Zen Kaku Gothic New（Regular / Medium / Bold。出荷物に同梱） | Outfit Bold | 28・20・28・8 |
| ゆめかわパステル | `yumekawaPastel` | 薄いピンク・ラベンダー・水色の地、丸い角、星やハートの小さな装飾 | Kiwi Maru（Regular / Medium。太字は Medium に寄せる） | Outfit SemiBold | 36・28・36・12 |
| 量産型ガーリー | `ryosangataGirly` | ピンク × 白、リボン・レース風の縁取り、丸ゴシックの見出し | Zen Maru Gothic（Regular / Bold。Medium は Regular に寄せる） | Outfit Bold | 30・24・30・14 |
| 韓国風ミニマル | `koreanMinimal` | くすみカラー、余白多め、細い線と細めの数字 | Zen Kaku Gothic New を 1 段ずつ細く（Light / Regular / Medium） | Outfit Light | 20・16・24・6 |
| 地雷系・ゴシック | `jiraiGothic` | 黒 × ピンク、ダークが主役、ハートや十字の装飾 | Kaisei Decol（Regular / Bold。Medium は Regular に寄せる） | Outfit Heavy | 16・12・20・4 |
| アイドル・ペンライト | `idolPenlight` | 推し色を大きく光らせる、ネオンの数字、ライブ会場の高揚感 | Mochiy Pop One（太さは 1 つ。3 つの太さをすべてこれに寄せる） | Outfit Black | 32・24・32・12 |

### ゆめかわパステル（`yumekawaPastel`）

- 狙い: 夢の中のような淡い色で、やさしく応援する。上から下へピンク → ラベンダー → 水色に移る地に、星とハートを小さく散らす
- 装飾: ホームの地に星とハート（不透明度 0.4）・カードに 2pt の淡い縁・見出しの前に `sparkle`・写真が無いときは推し色の地にハートの模様
- PR: #99（5 案で共通の Preview の部品 `ThemePreviewCanvas` も含む）

| 役割 | ライト | ダーク |
| --- | --- | --- |
| background（地のグラデーション） | `#FFF5FA` → `#F8F2FF` → `#F1F8FF` | `#1C1726` → `#1A1830` → `#16192C` |
| 星とハート | `#F5B8D6` | `#7A5E9E` |
| surface / surfaceContainer / surfaceContainerHigh | `#FFFFFF` / `#F7EEF8` / `#EBDDF0` | `#272033` / `#221C2D` / `#3B3150` |
| onSurface / onSurfaceVariant / outlineVariant | `#3E2D4C` / `#66557A` / `#E3D0EC` | `#F4EAF7` / `#D5C6DE` / `#55486B` |
| brand / onBrand | `#B23D78` / `#FFFFFF` | `#FFB5D8` / `#5A1A3D` |
| brandContainer / onBrandContainer | `#FADCEC` / `#3E2D4C` | `#6B3868` / `#FFDDF0` |
| destructive | `#B3261E` | `#F2B8B5` |
| カードの縁 / 見出しの飾り | `#F6CFE4` / `#C48ADB` | `#5E4A7A` / `#D9B8F0` |

### 量産型ガーリー（`ryosangataGirly`）

- 狙い: ピンク × 白の甘い服のような、リボンとレースの世界観。丸ゴシックで見出しをやわらかく
- 装飾: 地の模様は置かない（地の色だけ）・カードにレース風の縁取り（縁の細い線と内側の小さな玉）・見出しの前にリボン・写真が無いときは推し色のギンガムチェック
- PR: #103

| 役割 | ライト | ダーク |
| --- | --- | --- |
| background | `#FFF0F5` | `#24141B` |
| surface / surfaceContainer / surfaceContainerHigh | `#FFFFFF` / `#FCE6EE` / `#F5D3E0` | `#33202A` / `#2C1A23` / `#4A3040` |
| onSurface / onSurfaceVariant / outlineVariant | `#4A2333` / `#7A4A5C` / `#F2C4D5` | `#FCE8F0` / `#E2C2D0` / `#6A4656` |
| brand / onBrand | `#C2306D` / `#FFFFFF` | `#FFADCB` / `#5C1131` |
| brandContainer / onBrandContainer | `#FFD6E5` / `#4A2333` | `#7A2E4E` / `#FFD9E6` |
| destructive | `#B3261E` | `#F2B8B5` |
| レースの縁 / リボン | `#F7B6CE` / `#E86A9A` | `#8A4D68` / `#FF9DC0` |

### 韓国風ミニマル（`koreanMinimal`）

- 狙い: くすんだベージュ・グレージュ・くすみピンクで、大人っぽく静かに。模様を置かず、細い線と細い書体で余白を広く見せる
- 装飾: 地は無地・カードに 1pt の線・見出しの後ろに 1 画素の線・写真が無いときは推し色の濃淡
- PR: #102

| 役割 | ライト | ダーク |
| --- | --- | --- |
| background | `#F6F1EC` | `#1A1817` |
| surface / surfaceContainer / surfaceContainerHigh | `#FDFBF8` / `#EFE8E1` / `#E2D9D0` | `#24211F` / `#1F1C1A` / `#3A3532` |
| onSurface / onSurfaceVariant / outlineVariant | `#2F2A27` / `#5E5650` / `#D8CEC5` | `#EDE6E0` / `#C9BFB7` / `#4A443F` |
| brand / onBrand | `#A0525F` / `#FFFFFF` | `#E5B5BC` / `#4A2128` |
| brandContainer / onBrandContainer | `#F0DCDD` / `#2F2A27` | `#5E3F44` / `#F8E1E4` |
| destructive | `#A8322B` | `#F2B8B5` |
| カードの線 / 見出しの線 | `#E2D9D0` / `#D8CEC5` | `#3A3532` / `#4A443F` |

### 地雷系・ゴシック（`jiraiGothic`）

- 狙い: 黒 × ピンクで、ダークが主役。ライトも薄いピンクの地に黒の文字・黒の縁取りで世界観が分かるようにする。装飾的な明朝でゴシックの雰囲気を出す
- 装飾: ホームの地に十字とハート（不透明度 0.35）・カードに二重の線（外 1.5pt・4pt 内側に 1pt）・見出しの前にハート・写真が無いときは推し色を黒に寄せた地に白い十字とハート
- PR: #105

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

### アイドル・ペンライト（`idolPenlight`）

- 狙い: ライブ会場の高揚感。推し色の数字をペンライトのように光らせる（光は推し色から作り、推し色は置き換えない）。ダークは開演前の会場のような深い紫、ライトは明るいステージ
- 装飾: ホームの地にグラデーションと照明の光の筋 3 本（不透明度 0.18 まで）・カードにネオンの縁（1.5pt の線と 8pt の光）・見出しの前に音符・残り日数の数字の下に光（先頭のカードは白 0.25、地の上は推し色 0.3）・写真が無いときは推し色の地にペンライトの光の玉
- PR: #107

| 役割 | ライト | ダーク |
| --- | --- | --- |
| background（地のグラデーション） | `#FBF7FF` → `#F6F0FF` → `#FDF3FA` | `#0E0B1A` → `#130E26` → `#1A0D24` |
| 照明の光の筋 | `#E9D5FF` | `#6B4BB8` |
| surface / surfaceContainer / surfaceContainerHigh | `#FFFFFF` / `#F2ECFA` / `#E2D9F0` | `#1A1530` / `#151126` / `#2E2650` |
| onSurface / onSurfaceVariant / outlineVariant | `#1E1530` / `#51466A` / `#D5CBE6` | `#F5F0FF` / `#CFC6E8` / `#3D3466` |
| brand / onBrand | `#9B2FC8` / `#FFFFFF` | `#FF8AD0` / `#3A0026` |
| brandContainer / onBrandContainer | `#EBD9F7` / `#1E1530` | `#5A2D7A` / `#FFE3F4` |
| destructive | `#B3261E` | `#F2B8B5` |
| ネオンの縁 / 見出しの音符 | `#C77DFF` / `#9B2FC8` | `#B57BFF` / `#FF8AD0` |

## 推し色の文字のコントラスト

色の付いた地では、ライトの推し色の文字を少し黒に寄せて 4.5:1 を保ちます（ダークはどの案も既定と同じ 45% 白に寄せる）。
下の最小値は、推し色 12 色の文字を画面の地（グラデーションの各色）・カードの地・入力欄の地に置いたときのいちばん小さい比です（`PaletteContrastTests` と同じ組み合わせ）。

| 案 | 黒に寄せる割合（地・カード / 入力欄） | ライトの最小 | ダークの最小 |
| --- | --- | --- | --- |
| ゆめかわパステル | 0.08 / 0.10 | 4.97（オレンジ・地） | 5.05（ブラック・カード） |
| 量産型ガーリー | 0.08 / 0.10 | 4.76（オレンジ・入力欄） | 4.90（ブラック・カード） |
| 韓国風ミニマル | 0.10 / 0.14 | 4.99（オレンジ・入力欄） | 5.16（ブラック・カード） |
| 地雷系・ゴシック | 0.08 / 0.12 | 4.85（オレンジ・入力欄） | 5.77（ブラック・カード） |
| アイドル・ペンライト | 0.08 / 0.12 | 4.89（オレンジ・地） | 5.67（ブラック・カード） |

## 書体

どれも [google/fonts](https://github.com/google/fonts) のコミット `47d54ca1ebb14fd864695f1d39dc734f39017c33` から取得し、改変せずに `OshiCon/Preview Content/Fonts/` に置いています（ライセンスはすべて SIL Open Font License 1.1。ライセンス文は同じフォルダの `<Family>-OFL.txt`）。
Preview と DEBUG のビルドだけで使い、Archive（出荷物）・Widget Extension には入りません（`Configs/Release.xcconfig` の `EXCLUDED_SOURCE_FILE_NAMES`）。

| 案 | 書体（google/fonts のフォルダ） | ファイルと大きさ（バイト） |
| --- | --- | --- |
| ゆめかわパステル | Kiwi Maru（`ofl/kiwimaru`） | `KiwiMaru-Regular.ttf`（5,065,572）・`KiwiMaru-Medium.ttf`（5,123,612） |
| 量産型ガーリー | Zen Maru Gothic（`ofl/zenmarugothic`） | `ZenMaruGothic-Regular.ttf`（3,832,756）・`ZenMaruGothic-Bold.ttf`（3,779,008） |
| 韓国風ミニマル | Zen Kaku Gothic New の Light（`ofl/zenkakugothicnew`） | `ZenKakuGothicNew-Light.ttf`（2,181,020）。Regular / Medium は出荷物に同梱済みのもの |
| 地雷系・ゴシック | Kaisei Decol（`ofl/kaiseidecol`） | `KaiseiDecol-Regular.ttf`（4,503,152）・`KaiseiDecol-Bold.ttf`（4,286,896） |
| アイドル・ペンライト | Mochiy Pop One（`ofl/mochiypopone`） | `MochiyPopOne-Regular.ttf`（5,163,948） |

## 採用するときに要る作業

この epic では出荷する見た目を変えていません。案を採用するときは、次を別の依頼として行います。

1. **採用の形を決める**（Q1）: 1 案で既定のデザインを置き換えるか、設定でテーマを選べるようにするか。何案残すか
2. **デザインキャンバス**（Q8）: 元のキャンバス「推し活カウントダウン 画面デザイン」は変えずに、採用案のキャンバスを別に足してから実装する（人間の作業）
3. **書体を出荷物へ移す**: 採用した案の書体を `OshiCon/Preview Content/Fonts/` から出荷物のフォルダ（`Shared/Resources/Fonts/` など）へ移し、アプリと Widget Extension の `UIAppFonts` に足し、
   `Configs/Release.xcconfig` の除外の名前と `PreviewFonts.fileNames` から外す。オープンソースライセンスの画面（`OpenSourceLicense.all`）にも足す。
   容量は 1 書体あたり 2〜10 MB 増える（ウィジェットにも入れるとその分も増える）
4. **設定で選べるようにする場合**（Q6）: テーマの選択を App Group の `UserDefaults(suiteName:)` でウィジェットと共有し、変えたら `WidgetCenter` で描き直す。
   アプリと Widget Extension の両方の `PrivacyInfo.xcprivacy` に UserDefaults の `1C8F.1` を足す（`PrivacyManifestTests` も直す）。設定の画面の文言は 12 言語ぶん訳す
5. **Android 版の SPEC**（Q2）: iOS の見た目を変えたら、`shariverse/oshikatsu-countdown-android` の `docs/SPEC.md`（§4「デザインからの読み替え」など）に iOS のテーマを書く
6. **不採用の案**: 狙い・配色・書体・装飾（この文書と各案の PR）を shilokuma-inc/design-knowledge に残してから、このリポジトリから片付ける
