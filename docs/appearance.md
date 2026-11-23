# 着せ替え（推し活カウントダウン Plus。背景の写真と推しの写真の飾り）

推し活カウントダウン Plus（有料）で解放する着せ替え。次の 2 つを、それぞれ ON/OFF できる。

- **背景**: アプリ全体で 1 枚の写真を、iPhone の縦の比率（約 9:19.5）に調整して、ホームと予定の詳細の地に敷く
- **飾り**: 地に散らしているハートと十字を、写真を登録した推しの丸い写真に替える

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
- 背景の写真を敷いているときは、ホームの地の上に直接描く文字（「これからの予定」などの見出し・「この推しの予定はまだありません」・予定が無いときの案内）の後ろに、
  カードの地の色（`surface`）の板を敷く（`AppearanceTextPlate`）。予定の詳細は地の上に文字を置いていない（中身はカードの上）
- ホームでは、背景の写真の上の端（110pt）を幕の色のグラデーションで覆う（上の半分は不透明度 0.85、そこから消す。`AppearanceStatusBarFade`）。
  幕が薄いので、写真の色によらずステータスバーの文字（時刻・電池）を読めるようにするため。予定の詳細は上が推しの写真の帯で、スクロールすると素材のバーになるので掛けない

### 背景の写真

- 写真を選ぶ（`PhotosPicker`）と、推しの写真の調整画面を使い回した**約 9:19.5 の縦長の枠**（角の丸い長方形）で範囲を決め、切り抜いた画像だけを保存する（長い辺 2560px まで。詳しくは [photo-crop.md](photo-crop.md) の「長方形の枠」）
- 写真に**ぼかし**と**暗幕**を掛ける。幕の色はライトの外観では地の色（`palette.background`）、ダークの外観では黒
- 強さは **弱・中・強** の 3 段階（既定は中）。背景の推しが見えるよう、幕は薄く、ぼかしは小さくする（弱はぼかさない。#264）

  幕の不透明度は、飾り（推しの丸い写真）を重ねるかどうかで変える。飾りが ON のときは、写真の上でも丸い写真が見分けられるよう 0.2 濃くする。

  | 強さ | 幕（ライト・飾り OFF） | 幕（ダーク・飾り OFF） | 幕（ライト・飾り ON） | 幕（ダーク・飾り ON） | ぼかしの半径 |
  | --- | --- | --- | --- | --- | --- |
  | 弱 | 0.15 | 0.25 | 0.35 | 0.45 | なし（0pt） |
  | 中 | 0.30 | 0.40 | 0.50 | 0.60 | 4pt |
  | 強 | 0.45 | 0.55 | 0.65 | 0.75 | 10pt |

  - 弱・中・強の違いが分かるよう 0.15 ずつ離した。ダークは地を暗く保つため、ライトより 0.1 濃くした
  - 文字の読みやすさは幕では守らない。幕が薄いので、写真が真っ白・真っ黒だと地の上の文字は 4.5:1 を保てない。
    そこで背景の写真を敷いているときは、地の上に直接描く文字の後ろにカードの地の色の板を敷く（「敷く画面」）。本文の色（`onSurface`・`onSurfaceVariant`）は
    カードの地の上で 4.5:1 以上なので（`PaletteContrastTests`）、写真の色や幕の濃さによらず読める。推し色の文字はカードの上に描くので数えない
  - 初めの版（epic）は、板を敷かずに幕だけで 4.5:1 を守っていたため、幕が 0.70〜0.96・ぼかしが 12〜30pt と濃く、弱でも写真がほとんど見えなかった（#264 で今の値にした）
- 縦向きの iPhone では写真で地を覆って中央に置く。地のほうが横に広いとき（iPad・横向きの iPhone）は、写真を画面の高さに合わせて中央に置き、
  左右の余りは同じ写真の強いぼかし（60pt）で埋める。左右の余りが 1pt 未満なら覆う側にする
- 写真は画面の大きさ × 画面の倍率（上限 2560px）に縮めて、メインアクターの外で読む。回転・iPad の分割で読む大きさが変わったら読み直し、その間は今の写真を出したままにする

### 飾り（推しの丸い写真）

- 今の十字とハートの位置（左上のタイルから行ごとに通し番号）に、写真を登録した推しを**順にくり返して**割り当て、その推しの丸い写真を置く。
  推しの順はホームの推しの並び（登録した時刻 → 名前）
- 写真の無い推しのところは今の模様（ハート・十字）のまま。写真のある推しが 1 人もいなければ、すべて今の模様のまま
- 丸の直径は模様の高さの 2.5 倍（25〜40pt）、不透明度 0.15。丸どうしは重ならない。写真は丸の大きさ × 画面の倍率に縮めて読む

### 設定と保存

- 設定はアプリ全体で 1 つ。アプリだけの UserDefaults（`AppStorageKey`。`PrivacyInfo.xcprivacy` の CA92.1）に置く

  | キー | 中身 | 既定 |
  | --- | --- | --- |
  | `appearanceBackgroundEnabled` | 背景の写真を敷く | ON |
  | `appearanceDecorationEnabled` | 飾りを推しの丸い写真にする | OFF |
  | `appearanceIntensity` | 強さ（`weak`・`medium`・`strong`） | `medium` |
  | `appearanceBackgroundPhoto` | 背景の写真のファイル名 | 無し |

- 背景の写真のファイルは推しの写真と同じ置き場所（`OshiPhotoLibrary`。App Group のコンテナ）に置く。**SwiftData のスキーマは変えていない**
- 背景の写真を差し替える・外すときは、前のファイルを消す。推しの写真の差し替え・推しの削除では背景の写真を消さない
- Plus でない人も、写真を選んで設定を保存できる（試着）。Plus を買ったらそのまま使う
- 解約・期限切れで Plus が使えなくなったら、標準の見た目に戻す。選んだ写真と設定は消さない（また使えるようになったら戻る）

### 設定画面の「着せ替え」の行と、着せ替えの画面

- 設定画面の Plus の行の下に「着せ替え」の行を置き、押すと着せ替えの画面を開く。
  **今は Plus の行と同じく、開発版（DEBUG）と TestFlight だけに出す**（`PlusEntryPolicy.showsEntry(in:)`。`PlusEntryPolicy` は変えていない）。
  App Store 版で出すのは、推しの写真ウィジェットとそろって develop に入ってから別に行う
- 着せ替えの画面は上から次の順
  1. Plus の案内: Plus でない人は案内の文と「Plus で使う」（`openPlusPaywall` で課金画面を開く）、Plus の人は「Plus をお使いいただけます」
  2. 見本: ホームの部品で組んだホームの見本（390 × 845pt を幅 180pt に縮める）。選んだ写真・ON/OFF・強さ・飾りを、Plus によらずその場で映す（試着）。
     予定があれば先頭の予定を、無ければ見本の推しと予定を出す
  3. 背景の写真: 写真を選ぶ／変える・写真を外す・背景の ON/OFF・強さ（分割したボタン。アクセシビリティの大きな文字ではメニュー）。写真を選び直したら背景を ON にする
  4. 飾り: 飾りの ON/OFF
- 文言は 12 言語（`Shared/Resources/Localizable.xcstrings`）

### シェアのカード

- Plus の人で背景の写真を ON にしていて写真があれば、予定の詳細から開くシェアのプレビューに `ShareCardStyle(theme: .shipping, background: .photo(fileName:))` を渡す（`ShareCardStyle.appearance(_:)`）。
  それ以外は `.shipping`。強さと飾りはカードに関わらない（[share-card.md](share-card.md) の「Plus の着せ替えで差し替える口」）

### 作らないもの

- 推しごとの背景の写真（SwiftData のスキーマの変更）
- App Store 版で課金画面と着せ替えの入口を出すこと（`PlusEntryPolicy` の変更）
- 課金画面・シェアのカード・テーマの見本・ウィジェット・ライブアクティビティの地を写真や推しの写真の飾りにすること
- 新しいテーマや飾り、通信・解析・自前のサーバー、権限・プライバシーマニフェストの追加、外部ライブラリ

## コードの場所

| 役割 | 場所 |
| --- | --- |
| 設定（読み書き）・強さ（幕の不透明度・ぼかし・幕の色）・何を描くかの規則（Plus と設定から） | `OshiCon/Appearance/AppearanceSettings.swift`（`AppearanceSettings`・`AppearanceIntensity`・`AppearanceRendering`） |
| 背景の写真の上で、地の上の文字の後ろに敷く板（色と、敷くかの Environment `isOverAppearancePhoto`） | `OshiCon/Appearance/AppearanceTextPlate.swift`（`AppearanceTextPlate`・`appearanceTextPlate()`・`appearanceBlockPlate()`） |
| 設定と背景の写真のファイルを持つストア（差し替え・外す・メモリ上のストアの置き場所） | `OshiCon/Appearance/AppearanceStore.swift`（`AppearanceStore`。`OshiCon.swift` で environment に入れる） |
| 背景の写真の置き方（覆う・中央に置いて左右を埋める・読む画素数・詳細で上を除く範囲） | `OshiCon/Appearance/AppearanceBackgroundLayout.swift` |
| 背景の写真を敷く View（読み込み・ぼかし・幕・左右の埋め）・上の端のグラデーション | `OshiCon/Appearance/AppearanceBackgroundPhoto.swift`（`AppearanceBackgroundPhotoView`・`AppearanceBackgroundPhotoLayers`・`AppearanceStatusBarFade`） |
| 飾りの並べ方（どの位置にどの推しの写真を置くか・丸の大きさ・読む画素数） | `OshiCon/Appearance/OshiPhotoDecoration.swift` |
| 飾りの View | `OshiCon/Appearance/OshiPhotoDecorationView.swift`（`OshiPhotoDecorationLayer`・`OshiPhotoDecorationMarks`・`OshiPhotoDecorationBackground`） |
| 十字とハートの並び（飾りと同じ位置を使う） | `Shared/Design/ThemeOrnaments+Gothic.swift`（`CrossesAndHeartsPattern`） |
| ホームの地 | `OshiCon/Appearance/AppearanceScreenBackground.swift`（`HomeScreen` と見本で使う） |
| 予定の詳細の地と、上の写真の下端 | `OshiCon/Appearance/AppearanceDetailBackground.swift`（`AppearanceDetailBackground`・`AppearanceDetailHeaderPosition`） |
| 試着の規則（見本の大きさ・中身・読み上げの値・調整画面で読む画素数・強さの名前） | `OshiCon/Appearance/AppearancePreview.swift` |
| UI テストから描いているものを読む口 | `OshiCon/Appearance/AppearanceUITestMarker.swift` |
| 着せ替えの画面・ホームの見本 | `OshiCon/Screens/Appearance/AppearanceSettingsScreen.swift`・`AppearanceHomePreview.swift` |
| 設定の「着せ替え」の行 | `OshiCon/Screens/Settings/SettingsScreen.swift`（`PlusSettingsSection`） |
| 縦長の枠の調整と切り抜き | `OshiCon/Photo/`（[photo-crop.md](photo-crop.md)） |
| シェアのカードの地を選ぶ規則 | `OshiCon/Share/ShareCardStyle.swift`（`ShareCardStyle.appearance(_:)`） |

画面は `@Environment(AppearanceStore.self)` でストアを、`@Environment(\.isPlusUnlocked)` で Plus の状態を引き、`store.rendering(isPlusUnlocked:)` で描くものを決める。
背景の写真は必ず `store.photos` から読む（メモリ上のストアでは置き場所が `OshiPhotoLibrary.shared` と違う）。推しの写真は今までどおり `OshiPhotoLibrary.shared` から読む。
#Preview では `.environment(AppearanceStore.volatile(…))` を入れる。

## テスト

- Unit（Swift Testing）: `OshiConTests/Appearance/`
  - `AppearanceSettingsTests`: 設定の読み書き・不正な値、Plus と設定から決まる描くもの、強さの並び（飾りの ON/OFF ごと）、飾りを重ねるときだけ幕が濃いこと、
    写真が見える薄さ（弱は幕 0.15・ぼかしなし）、幕の色、板の上の本文と上の端のステータスバーの文字のコントラスト（出荷するテーマと 12 色で染めたテーマ、ライトとダークで 4.5:1 以上）
  - `AppearanceStoreTests`: 永続化・取り込みの大きさ・差し替えと外すときの削除・読めない写真・Plus でないときも設定と写真が残ること・メモリ上のストア
  - `AppearanceBackgroundLayoutTests`: 縦向き・細長い地・iPad と横向き・余りが 1pt 未満・読む画素数・詳細で上を除く範囲・写真を読む前のコントラスト
  - `OshiPhotoDecorationTests`: 模様の置き方と通し番号、推しのくり返し、写真の無い推し・写真のある推しがいないとき、丸の大きさと重なり、
    背景の写真が無いときの丸い写真の上の本文のコントラスト（背景の写真の上では板を敷く）
  - `AppearancePreviewTests`: 試着は Plus によらず設定のとおり・実際の画面は Plus でなければ標準、見本の中身と大きさ、読み上げの値
  - `AppearanceUITestMarkerTests`: UI テストに見せる値
  - ほかに `OshiConTests/Photo/OshiEditingTests`（推しの写真の差し替え・削除で背景の写真が消えない）、`PhotoCropRectangleTests`・`PhotoResizerRectangleCropTests`（縦長の枠）、
    `OshiConTests/Share/ShareCardAppearanceStyleTests`（シェアのカードの地を選ぶ規則）
- UI（XCTest）: `OshiConUITests/AppearanceUITests`。起動引数 `-useInMemoryStore -useTestPhoto` と日本語で起動する
  - `-plusLocked`: 設定の「着せ替え」の行（`settings.appearance`）→ 写真を選ぶ（`appearance.selectPhoto`。`-useTestPhoto` で生成した画像）→ 縦長の調整（`photoCrop.done`）→
    見本（`appearance.preview` の読み上げの値）に映る → 強さ（`appearance.intensity`）・背景と飾りの ON/OFF（`appearance.backgroundToggle`・`appearance.decorationToggle`）・
    写真を変える・外す（`appearance.removePhoto`）→ 課金画面を開く（`appearance.openPaywall`）。ホームと詳細は標準のまま
  - `-plusUnlocked`: 使えていることを示し（`appearance.plusActive`）、ホームと詳細に写真と飾りが効く。背景を OFF にすると、その場で飾りだけになる
  - `-simulateAppStoreDistribution`: 「着せ替え」の行が出ない
  - ホームと詳細の地は読み上げから外しているので、メモリ上のストアのときだけ 1pt の透明な要素（`home.appearance`・`eventDetail.appearance`。`AppearanceUITestMarker`）を置き、
    そのラベル（`standard`・`photo:<強さ>`・`decoration` を `,` でつないだもの）で描いているものを確かめる。端末のストアで動くアプリには置かない
  - メモリ上のストアでは、着せ替えの設定は別の UserDefaults（`jp.shilokuma.OshiCon.InMemoryAppearance`）、写真は一時ディレクトリに置き、起動のたびに空にする。
    そのため 1 回の起動の中で写真を選んでから確かめる
- iPad Pro 13-inch (M5) でビルドし、横向き・大きな文字・ダークは #Preview（着せ替えの画面・背景の写真・飾り・詳細の地）で見る

## 実機で確かめること

- **大きな写真の取り込み**: 4800 万画素（ProRAW・HEIF）の写真を背景に選んで、調整画面が開くまでと「完了」から見本に映るまでの速さ、メモリ（推しの写真の #135 と同じ観点。背景は上限が 2560px で、狭く切り抜くと元の大きさで読む）
- **ぼかしの重さ**: ホームと予定の詳細のスクロール、iPad と横向きの左右の強いぼかし（60pt）、回転・Split View で大きさが変わったときに、引っかかり・発熱が無いか。古い端末（iOS 17 の最も古い対応端末）でも見る
- 暗幕の濃さと強さの差の見え方（推しの写真がはっきり見え、弱・中・強の違いが分かるか。飾りの ON/OFF で幕の濃さが変わるのが不自然でないか）、ダークの外観、ダイナミックタイプの大きな文字で崩れないか
- 幕を薄くしたので、明るい写真・暗い写真の上で、iOS 17・18 の透けたバー（ナビゲーションバーの ＋・いちばん下までスクロールしたときのタブバー）が読めるか。上の端のグラデーションが不自然でないか（iPad・横向きを含む）。見出しの板が大きな文字で崩れないか
- 購入・解約・期限切れ（Xcode の StoreKit の Manage Transactions）で、ホームと詳細がその場で切り替わり、写真と設定が残ること
- VoiceOver で、ホームと詳細の読み上げ・並びが変わらないこと
