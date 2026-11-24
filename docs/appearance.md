# 着せ替え（推し活カウントダウン Plus。背景の写真と推しの写真の飾り）

推し活カウントダウン Plus（有料）で解放する着せ替え。次の 2 つを、それぞれ ON/OFF できる。

- **背景**: アプリ全体で 1 枚の写真を、iPhone の縦の比率（約 9:19.5）に調整して、ホームと予定の詳細の地に敷く
- **飾り**: 地に散らしているハートと十字の代わりに、選んだ推しの丸い写真を並べる。濃さと量はスライダーで変え、量をいちばん多くすると地を埋め尽くす（#266）

AskHub の epic（01M816HSS5D0CG3HJHHEF4XTB3）で作った。

> **Android 版の SPEC（`shariverse/oshikatsu-countdown-android` の `docs/SPEC.md`）には、まだこの仕様が書かれていない。**
> Android 版にも入れる前提なので、この epic が develop に入った後で、このファイルの「仕様」を SPEC に書き写す PR を出す。

## 仕様

### 敷く画面

- 背景の写真と飾りを効かせるのは**ホームと予定の詳細だけ**。課金画面・シェアのカード・テーマの見本・ウィジェット・ライブアクティビティの地は今のまま（`ThemeScreenBackground` は変えていない）
- 予定の詳細では、上の横長の写真の部分には敷かず、その下の地にだけ敷く。上の写真はスクロールで動くので、その下端を測って追う
- カード・推し色の役割・書体・テーマ（`AppTheme.jiraiGothic`）は変えない
- 背景と飾りの両方を ON にしたときは、暗幕とぼかしを掛けた写真の上に飾りを重ねる
- 背景と飾りは `accessibilityHidden(true)`・`allowsHitTesting(false)` で、読み上げ・押せる範囲・並びを変えず、文字の上に重ねない
- 背景の写真か飾りを描いているとき（`AppearanceRendering.drawsPhotosOnGround`）は、ホームの地の上に直接描く文字（「これからの予定」などの見出し・「この推しの予定はまだありません」・予定が無いときの案内）の後ろに、
  カードの地の色（`surface`）の板を敷く（`AppearanceTextPlate`）。予定の詳細は地の上に文字を置いていない（中身はカードの上）
  - 飾りだけで、出す推しに写真のある推しがいない（テーマの模様のまま）ときも敷く（出す推しを切り替えるたびに見出しが変わらないように）
- ホームでは、背景の写真か飾りを描いているとき、いちばん上（飾りの上）で上の端（110pt）を幕の色のグラデーションで覆う（上の半分は不透明度 0.85、そこから消す。`AppearanceStatusBarFade`）。
  幕が薄く、飾りは濃くできるので、写真の色によらずステータスバーの文字（時刻・電池）を読めるようにするため。予定の詳細は上が推しの写真の帯で、スクロールすると素材のバーになるので掛けない

### 背景の写真

- 写真を選ぶ（`PhotosPicker`）と、推しの写真の調整画面を使い回した**約 9:19.5 の縦長の枠**（角の丸い長方形）で範囲を決め、切り抜いた画像だけを保存する（長い辺 2560px まで。詳しくは [photo-crop.md](photo-crop.md) の「長方形の枠」）
- 写真に**ぼかし**と**暗幕**を掛ける。幕の色はライトの外観では地の色（`palette.background`）、ダークの外観では黒
- **暗幕の濃さ**（薄い〜濃い）と**ぼかしの強さ**（なし〜強い）を、それぞれスライダー（0〜100%。5% ずつ）で別々に変える（#268。`AppearanceBackgroundStyle`）。
  背景の推しが見えるよう、いちばん濃く・強くしても幕は 0.6（ライト・飾り OFF）、ぼかしは 10pt までにする（#264）
  - 幕の不透明度（ライト・飾り OFF）= 0.6 × 暗幕の濃さ。ダークは地を暗く保つため 0.1、飾り（推しの丸い写真）を重ねるときは写真の上でも丸い写真が見分けられるよう 0.2 濃くする
  - ぼかしの半径 = 10pt × ぼかしの強さ。0% ならぼかさない

  | 暗幕の濃さ | 幕（ライト・飾り OFF） | 幕（ダーク・飾り OFF） | 幕（ライト・飾り ON） | 幕（ダーク・飾り ON） |
  | --- | --- | --- | --- | --- |
  | 0%（薄い） | 0（幕なし） | 0.10 | 0.20 | 0.30 |
  | 25% | 0.15 | 0.25 | 0.35 | 0.45 |
  | 50%（既定） | 0.30 | 0.40 | 0.50 | 0.60 |
  | 75% | 0.45 | 0.55 | 0.65 | 0.75 |
  | 100%（濃い） | 0.60 | 0.70 | 0.80 | 0.90 |

  | ぼかしの強さ | 0%（なし） | 40%（既定） | 100%（強い） |
  | --- | --- | --- | --- |
  | ぼかしの半径 | 0pt | 4pt | 10pt |

  - 初めは暗幕とぼかしを一緒に変える 3 段階（弱・中・強）だった。今の値はそれと重なるようにしてあり、弱は暗幕 25%・ぼかし 0%、中は暗幕 50%・ぼかし 40%（既定）、強は暗幕 75%・ぼかし 100% と同じ見た目になる
  - 文字の読みやすさは幕では守らない。幕が薄いので、写真が真っ白・真っ黒だと地の上の文字は 4.5:1 を保てない。
    そこで背景の写真か飾りを描いているときは、地の上に直接描く文字の後ろにカードの地の色の板を敷く（「敷く画面」）。本文の色（`onSurface`・`onSurfaceVariant`）は
    カードの地の上で 4.5:1 以上なので（`PaletteContrastTests`）、写真の色や幕の濃さによらず読める。推し色の文字はカードの上に描くので数えない
  - 初めの版（epic）は、板を敷かずに幕だけで 4.5:1 を守っていたため、幕が 0.70〜0.96・ぼかしが 12〜30pt と濃く、弱でも写真がほとんど見えなかった（#264 で今の値にした）
- 縦向きの iPhone では写真で地を覆って中央に置く。地のほうが横に広いとき（iPad・横向きの iPhone）は、写真を画面の高さに合わせて中央に置き、
  左右の余りは同じ写真の強いぼかし（60pt）で埋める。左右の余りが 1pt 未満なら覆う側にする
- 写真は画面の大きさ × 画面の倍率（上限 2560px）に縮めて、メインアクターの外で読む。回転・iPad の分割で読む大きさが変わったら読み直し、その間は今の写真を出したままにする

### 飾り（推しの丸い写真）

- 丸い写真を、行ごとに間隔の半分ずつずらした**互い違いの並び**（六角形の詰め方）で地に並べる（`OshiPhotoDecorationLayout`）。
  一定の大きさで並べるので、iPad の広い画面では丸が増え、大きさは変わらない。丸どうしは重ならない
- **量**（0〜100%。既定は 25%）で、丸の直径と間隔を変える。直径は 32pt から 64pt、同じ行のとなりの丸との間隔は 128pt から 64pt に、量に比例して変える

  | 量 | 直径 | 間隔 | 地を覆う割合（およそ） |
  | --- | --- | --- | --- |
  | 0%（少なめ） | 32pt | 128pt | 6% |
  | 25%（既定） | 40pt | 112pt | 12% |
  | 50% | 48pt | 96pt | 23% |
  | 75% | 56pt | 80pt | 44% |
  | 100%（埋め尽くす） | 64pt | 64pt | 91%（丸どうしが接する） |

  - 初めの版は十字とハートの位置に置いていた（直径 25〜40pt、地のおよそ 9%）。量を変えられるよう、今の並びにした
- **濃さ**（丸い写真の不透明度。10〜100%。既定は 40%）。初めの版は 0.15 で薄すぎたので濃くした。どの濃さでも地の上の文字は板の上に描く（「敷く画面」）
- スライダーの値は 5% ずつに丸める（`Slider` の `step` は目盛りの点が騒がしいので使わない）。値は百分率で出し、読み上げの値も百分率
- **出す推し**: 推しごとに選べる。既定はすべての推し（新しく登録した推しも出す）。選んだ推しのうち、写真を登録した推しを、推しの並び（推しの一覧の順）で**順にくり返して**割り当てる。
  斜めにずらして割り当てるので、推しが 3 人以上なら、となり合う丸はどれも別の推しになる（2 人なら同じ行の左右だけが別の推し）
  - 写真の無い推しも選んでおける（写真を登録すると飾りに出る）。着せ替えの画面では「写真がありません」を添える
  - 出す推しに写真のある推しが 1 人もいなければ、テーマの模様（ハート・十字）のまま。読めなかった写真の推しは飛ばす
- 写真はいちばん大きい丸（64pt）× 画面の倍率に縮め、丸の外を透明にした画像にしてメインアクターの外で読む（量 100% の iPad では丸が数百になるので、描くたびに丸で切らない）

### 設定と保存

- 設定はアプリ全体で 1 つ。アプリだけの UserDefaults（`AppStorageKey`。`PrivacyInfo.xcprivacy` の CA92.1）に置く

  | キー | 中身 | 既定 |
  | --- | --- | --- |
  | `appearanceBackgroundEnabled` | 背景の写真を敷く | ON |
  | `appearanceDecorationEnabled` | 飾りを推しの丸い写真にする | OFF |
  | `appearanceBackgroundScrim` | 暗幕の濃さ（0〜1） | 0.5 |
  | `appearanceBackgroundBlur` | ぼかしの強さ（0〜1） | 0.4 |
  | `appearanceBackgroundPhoto` | 背景の写真のファイル名 | 無し |
  | `appearanceDecorationOpacity` | 飾りの濃さ（0.1〜1） | 0.4 |
  | `appearanceDecorationAmount` | 飾りの量（0〜1） | 0.25 |
  | `appearanceDecorationExcludedOshis` | 飾りに出さない推しの id（UUID の文字列の配列） | 空（すべての推しを出す） |

- 範囲の外の暗幕・ぼかし・濃さ・量は範囲に収め、UUID でない id は読まない。出さない推しの id は、推しを切り替えたときに、もういない推しの分を外す
- 前の版（TestFlight）の強さ `appearanceIntensity`（`weak`・`medium`・`strong`）が残っていて、暗幕とぼかしのキーが無ければ、同じ見た目になる位置に読み替える
  （弱: 暗幕 0.25・ぼかし 0、中: 0.5・0.4、強: 0.75・1）。設定を書くときに `appearanceIntensity` を消す

- 背景の写真のファイルは推しの写真と同じ置き場所（`OshiPhotoLibrary`。App Group のコンテナ）に置く。**SwiftData のスキーマは変えていない**
- 背景の写真を差し替える・外すときは、前のファイルを消す。推しの写真の差し替え・推しの削除では背景の写真を消さない
- Plus でない人も、写真を選んで設定を保存できる（試着）。Plus を買ったらそのまま使う
- 解約・期限切れで Plus が使えなくなったら、標準の見た目に戻す。選んだ写真と設定は消さない（また使えるようになったら戻る）

### 設定画面の「着せ替え」の行と、着せ替えの画面

- 設定画面の Plus の行の下に「着せ替え」の行を置き、押すと着せ替えの画面を開く。
  Plus の行と同じく `PlusEntryPolicy.showsEntry(in:)` で出す。1.3.0 から App Store 版でも出す（それまでは開発版と TestFlight だけ。#284）
- 着せ替えの画面は上から次の順。2 の見本だけはスクロールする Form の外に置き、どの設定を変えているときも見えるようにする（下の「見本の置き方」。#269）
  1. Plus の案内: Plus でない人は案内の文と「Plus で使う」（`openPlusPaywall` で課金画面を開く）、Plus の人は「Plus をお使いいただけます」
  2. 見本: ホームの部品で組んだホームの見本（390 × 845pt で組み、画面の大きさに合わせて縮める）。選んだ写真・ON/OFF・暗幕とぼかし・飾りを、Plus によらずその場で映す（試着）。
     予定があれば先頭の予定を、無ければ見本の推しと予定を出す
  3. 背景の写真: 写真を選ぶ／変える・写真を外す・背景の ON/OFF、暗幕の濃さ（薄い〜濃い）とぼかしの強さ（なし〜強い）のスライダー。写真を選び直したら背景を ON にする。
     背景が OFF のときもスライダーの値は見せ、押せなくする
  4. 飾り: 飾りの ON/OFF、濃さ（薄い〜濃い）と量（少なめ〜埋め尽くす）のスライダー。飾りが OFF のときも値は見せ、押せなくする
  5. 飾りに出す推し: 推しごとのスイッチ（推しのアバター・名前、写真の無い推しは「写真がありません」）。推しがいなければ出さない。飾りが OFF のときは押せない
- スライダー（暗幕・ぼかし・飾りの濃さ・量）は同じ部品（`AppearanceSlider`）。値は 5% ずつに丸め、百分率で出す。アクセシビリティの大きな文字では、両端の言葉をスライダーの下に置く
- 見本の置き方。並べ方と見本の大きさは `AppearancePreviewLayout` が、ナビゲーションバーとタブバーを除いた中身の大きさから決める
  - 幅の狭い画面（縦向きの iPhone、iPad の狭い分割・スライドオーバー）: 見本を上に固定し、その下で設定の Form をスクロールする。
    見本の帯は画面の高さの 45% まで（見本の高さは 120〜340pt）で、いちばん小さい iPhone（SE）でも設定に半分より多く残す。「見本」と説明の文（「選んだ写真と設定を、その場でホームの見本に映します」）は見本の右に置く
  - 幅の広い画面（幅 700pt 以上か、横長で幅 480pt 以上。iPad・横向きの iPhone）: 見本を左の列、設定の Form を右に並べる。見本は列の高さに収め、幅は 280pt・画面の幅の 40% まで。「見本」と説明の文は見本の下に置く
  - アクセシビリティの大きな文字: 見本は隠さず、上に固定する帯を画面の高さの 30% までに小さくして、行が高くなった設定に場所を譲る。左の列では見本の下の文に広く空ける。
    決めた高さに収まらない「見本」と説明の文は縮めて収め（`minimumScaleFactor`）、設定を押し下げない
  - 見本と設定の境目に細い線（`outlineVariant`）を引く。上に固定するときは、送った設定がこの線の下に隠れる
  - 回転などで並べ方が変わっても、見本と Form は作り直さない（`AnyLayout`。スクロールの位置と読んだ写真を保つ）
  - 見本は押せず（`allowsHitTesting(false)`）、スクロールの邪魔をしない。読み上げでは見本を 1 つの要素にし（名前「ホームの見本」、値は映しているもの）、説明の文はそのヒントにする。
    見える「見本」と説明の文は、同じことを 2 度読まないよう読み上げから外す
  - スライダーは動かしている間も、値が変わるたび（5% ごと）に見本に映す。暗幕・ぼかし・飾りの濃さ・量だけが変わったときは写真を読み直さず、
    背景の写真の ON/OFF でも飾りの推しの写真を読み直さない（模様に戻ってちらつかない）
- 文言は 12 言語（`Shared/Resources/Localizable.xcstrings`）

### シェアのカード

- Plus の人で背景の写真を ON にしていて写真があれば、予定の詳細から開くシェアのプレビューに `ShareCardStyle(theme: .shipping, background: .photo(fileName:))` を渡す（`ShareCardStyle.appearance(_:)`）。
  それ以外は `.shipping`。暗幕・ぼかしと飾りはカードに関わらない（[share-card.md](share-card.md) の「Plus の着せ替えで差し替える口」）

### 作らないもの

- 推しごとの背景の写真（SwiftData のスキーマの変更）
- 課金画面・シェアのカード・テーマの見本・ウィジェット・ライブアクティビティの地を写真や推しの写真の飾りにすること
- 新しいテーマや飾り、通信・解析・自前のサーバー、権限・プライバシーマニフェストの追加、外部ライブラリ

## コードの場所

| 役割 | 場所 |
| --- | --- |
| 設定（読み書き・前の版の強さの読み替え）・暗幕とぼかし（幕の不透明度・ぼかしの半径・幕の色）・何を描くかの規則（Plus と設定から） | `OshiCon/Appearance/AppearanceSettings.swift`（`AppearanceSettings`・`AppearanceBackgroundStyle`・`AppearanceRendering`） |
| 背景の写真の上で、地の上の文字の後ろに敷く板（色と、敷くかの Environment `isOverAppearancePhoto`） | `OshiCon/Appearance/AppearanceTextPlate.swift`（`AppearanceTextPlate`・`appearanceTextPlate()`・`appearanceBlockPlate()`） |
| 設定と背景の写真のファイルを持つストア（差し替え・外す・メモリ上のストアの置き場所） | `OshiCon/Appearance/AppearanceStore.swift`（`AppearanceStore`。`OshiCon.swift` で environment に入れる） |
| 背景の写真の置き方（覆う・中央に置いて左右を埋める・読む画素数・詳細で上を除く範囲） | `OshiCon/Appearance/AppearanceBackgroundLayout.swift` |
| 背景の写真を敷く View（読み込み・ぼかし・幕・左右の埋め）・上の端のグラデーション | `OshiCon/Appearance/AppearanceBackgroundPhoto.swift`（`AppearanceBackgroundPhotoView`・`AppearanceBackgroundPhotoLayers`・`AppearanceStatusBarFade`） |
| 飾りの濃さ・量・出す推し、並べる推しの写真、丸の並べ方（量ごとの大きさと間隔・どの丸にどの推し）、丸い写真の作り方・読む画素数 | `OshiCon/Appearance/OshiPhotoDecoration.swift`（`OshiPhotoDecorationStyle`・`OshiPhotoDecoration`・`OshiPhotoDecorationLayout`） |
| 飾りの View | `OshiCon/Appearance/OshiPhotoDecorationView.swift`（`OshiPhotoDecorationLayer`・`OshiPhotoDecorationMarks`） |
| 十字とハートの並び（写真のある推しがいないときの飾り） | `Shared/Design/ThemeOrnaments+Gothic.swift`（`CrossesAndHeartsPattern`） |
| ホームの地 | `OshiCon/Appearance/AppearanceScreenBackground.swift`（`HomeScreen` と見本で使う） |
| 予定の詳細の地と、上の写真の下端 | `OshiCon/Appearance/AppearanceDetailBackground.swift`（`AppearanceDetailBackground`・`AppearanceDetailHeaderPosition`） |
| 試着の規則（見本の大きさ・中身・読み上げの値・調整画面で読む画素数・百分率の文字） | `OshiCon/Appearance/AppearancePreview.swift` |
| 着せ替えの画面の並べ方（見本を上に固定する・左に並べる）と、見本を見せる大きさ | `OshiCon/Appearance/AppearancePreviewLayout.swift`（`AppearancePreviewLayout`） |
| UI テストから描いているものを読む口 | `OshiCon/Appearance/AppearanceUITestMarker.swift` |
| 着せ替えの画面・飾りのまとまり（スライダー・出す推し）・スライダーの部品・見本の帯と列・ホームの見本 | `OshiCon/Screens/Appearance/AppearanceSettingsScreen.swift`・`AppearanceDecorationSettings.swift`・`AppearanceSlider.swift`・`AppearancePreviewPane.swift`・`AppearanceHomePreview.swift` |
| 設定の「着せ替え」の行 | `OshiCon/Screens/Settings/SettingsScreen.swift`（`PlusSettingsSection`） |
| 縦長の枠の調整と切り抜き | `OshiCon/Photo/`（[photo-crop.md](photo-crop.md)） |
| シェアのカードの地を選ぶ規則 | `OshiCon/Share/ShareCardStyle.swift`（`ShareCardStyle.appearance(_:)`） |

画面は `@Environment(AppearanceStore.self)` でストアを、`@Environment(\.isPlusUnlocked)` で Plus の状態を引き、`store.rendering(isPlusUnlocked:)` で描くものを決める。
背景の写真は必ず `store.photos` から読む（メモリ上のストアでは置き場所が `OshiPhotoLibrary.shared` と違う）。推しの写真は今までどおり `OshiPhotoLibrary.shared` から読む。
#Preview では `.environment(AppearanceStore.volatile(…))` を入れる。

## テスト

- Unit（Swift Testing）: `OshiConTests/Appearance/`
  - `AppearanceSettingsTests`: 設定の読み書き・不正な値（範囲の外の暗幕・ぼかし・濃さ・量・型の違う値・UUID でない id）・前の版の強さの読み替え、Plus と設定から決まる描くもの（暗幕とぼかし・飾りの濃さ・量・出す推し、板と覆いを掛けるか）、
    飾りの濃さ・量を範囲に収めること（`OshiPhotoDecorationStyleTests`）、暗幕とぼかし（`AppearanceBackgroundStyleTests`。範囲に収めること・前の版の弱・中・強とちょうど同じ値になること・位置を上げるほど濃く強いこと・暗幕とぼかしが別々に効くこと・ダークと飾りの分だけ幕が濃いこと・
    写真が見える薄さ（いちばん濃くて幕 0.6・ぼかし 10pt））、幕の色、板の上の本文と上の端のステータスバーの文字のコントラスト（出荷するテーマと 12 色で染めたテーマ、ライトとダークで 4.5:1 以上）
  - `AppearanceStoreTests`: 永続化（暗幕とぼかし・前の版の強さからの読み替え・飾りの濃さ・量・出す推しと、もういない推しの分を外すこと）・取り込みの大きさ・差し替えと外すときの削除・読めない写真・Plus でないときも設定と写真が残ること・メモリ上のストア
  - `AppearanceBackgroundLayoutTests`: 縦向き・細長い地・iPad と横向き・余りが 1pt 未満・読む画素数・詳細で上を除く範囲・写真を読む前のコントラスト
  - `OshiPhotoDecorationTests`: 十字とハートの置き方、並べる推し（写真の無い推し・出さない推し・写真のある推しがいないとき・重なり）、読む画素数、丸い写真（丸の外が透明）
  - `OshiPhotoDecorationLayoutTests`: 量ごとの直径と間隔、量を増やすほど覆う割合が増えて量 100% で 9 割ほどになること、どの量でも丸が重ならないこと、となり合う丸が別の推しになること
  - `AppearancePreviewTests`: 試着は Plus によらず設定のとおり・実際の画面は Plus でなければ標準、見本の中身と大きさ、読み上げの値（暗幕の濃さ・ぼかしの強さ・飾りの濃さ・量の百分率を含む）
  - `AppearancePreviewLayoutTests`: 縦向きの iPhone（SE〜Pro Max）は上に固定して設定に半分より多く残すこと、大きな文字では見本を小さくすること、
    iPad と横向きの iPhone は左右に並べて見本と下の文を高さに、左の列を幅の 4 割に収めること、iPad の狭い分割は上に固定すること、測れていない大きさ
  - `AppearanceUITestMarkerTests`: UI テストに見せる値
  - ほかに `OshiConTests/Photo/OshiEditingTests`（推しの写真の差し替え・削除で背景の写真が消えない）、`PhotoCropRectangleTests`・`PhotoResizerRectangleCropTests`（縦長の枠）、
    `OshiConTests/Share/ShareCardAppearanceStyleTests`（シェアのカードの地を選ぶ規則）
- UI（XCTest）: `OshiConUITests/AppearanceUITests`。起動引数 `-useInMemoryStore -useTestPhoto` と日本語で起動する
  - `-plusLocked`: 設定の「着せ替え」の行（`settings.appearance`）→ 写真を選ぶ（`appearance.selectPhoto`。`-useTestPhoto` で生成した画像）→ 縦長の調整（`photoCrop.done`）→
    見本（`appearance.preview` の読み上げの値）に映る → 暗幕とぼかしのスライダー（`appearance.backgroundScrim`・`appearance.backgroundBlur`。背景が OFF なら押せない）・背景と飾りの ON/OFF（`appearance.backgroundToggle`・`appearance.decorationToggle`）・
    写真を変える・外す（`appearance.removePhoto`）→ 課金画面を開く（`appearance.openPaywall`）。ホームと詳細は標準のまま
  - `-plusUnlocked`: 使えていることを示し（`appearance.plusActive`）、ホームと詳細に写真と飾りが効く。背景を OFF にすると、その場で飾りだけになる
  - `-plusUnlocked -seedSampleData`: 飾りが OFF のときはスライダーを押せない → 飾りを ON にして、濃さ・量のスライダー（`appearance.decorationOpacity`・`appearance.decorationAmount`）をいちばん右にすると見本に映る →
    見本の推しのスイッチ（`appearance.decorationOshi.<並びの番号>`）で外せる → ホームに飾りが効く。
    スライダーと推しのスイッチを動かすときも、見本が画面の中にあって設定と重ならないことを確かめる
  - 見本は Form の外に固定しているので、行を探して送るときは Form（`appearance.form`）の上で指を動かす（見本の上では送れない）
  - `-simulateAppStoreDistribution`: App Store 版でも「着せ替え」の行が出る
  - ホームと詳細の地は読み上げから外しているので、メモリ上のストアのときだけ 1pt の透明な要素（`home.appearance`・`eventDetail.appearance`。`AppearanceUITestMarker`）を置き、
    そのラベル（`standard`・`photo`・`decoration` を `,` でつないだもの）で描いているものを確かめる（暗幕とぼかしの値は見本の読み上げの値で確かめる）。端末のストアで動くアプリには置かない
  - メモリ上のストアでは、着せ替えの設定は別の UserDefaults（`jp.shilokuma.OshiCon.InMemoryAppearance`）、写真は一時ディレクトリに置き、起動のたびに空にする。
    そのため 1 回の起動の中で写真を選んでから確かめる
- iPad Pro 13-inch (M5) でビルドし、横向き・大きな文字・ダークは #Preview（着せ替えの画面・見本の帯と列・背景の写真・飾り・詳細の地）で見る

## 実機で確かめること

- **大きな写真の取り込み**: 4800 万画素（ProRAW・HEIF）の写真を背景に選んで、調整画面が開くまでと「完了」から見本に映るまでの速さ、メモリ（推しの写真の #135 と同じ観点。背景は上限が 2560px で、狭く切り抜くと元の大きさで読む）
- **ぼかしの重さ**: ホームと予定の詳細のスクロール、iPad と横向きの左右の強いぼかし（60pt）、回転・Split View で大きさが変わったときに、引っかかり・発熱が無いか。古い端末（iOS 17 の最も古い対応端末）でも見る
- 暗幕とぼかしの見え方（既定の暗幕 50%・ぼかし 40% で推しの写真がはっきり見えるか、スライダーの範囲が足りるか。飾りの ON/OFF で幕の濃さが変わるのが不自然でないか）、ダークの外観、ダイナミックタイプの大きな文字で崩れないか
- **ぼかしの重さ（スライダー）**: ぼかしのスライダーを動かしている間、ホームの見本の追従に引っかかりが無いか
- **飾りの描画の重さ**: 量 100%・濃さ 100% で、iPad（横向き・Split View）のホームと予定の詳細のスクロール、着せ替えの画面でスライダーを動かしたときの見本の追従に、引っかかりが無いか
- **着せ替えの画面の見本**: いちばん小さい iPhone（SE・17e）で、上に固定した見本が小さすぎないか、設定を操作しやすいか（大きな文字を含む）。
  iPad の Split View・Stage Manager で窓の大きさを変えたときに、並べ方が切り替わっても崩れないか
- 飾りの見え方（既定の濃さ 40%・量 25% が好みに合うか、埋め尽くしたときに推しの顔が分かるか、推しが 2 人のときに上下の行で同じ推しが並ぶのが気にならないか）
- 幕を薄くしたので、明るい写真・暗い写真の上で、iOS 17・18 の透けたバー（ナビゲーションバーの ＋・いちばん下までスクロールしたときのタブバー）が読めるか。上の端のグラデーションが不自然でないか（iPad・横向きを含む）。見出しの板が大きな文字で崩れないか
- 購入・解約・期限切れ（Xcode の StoreKit の Manage Transactions）で、ホームと詳細がその場で切り替わり、写真と設定が残ること
- VoiceOver で、ホームと詳細の読み上げ・並びが変わらないこと
