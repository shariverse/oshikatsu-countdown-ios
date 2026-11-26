# 画像でシェア（予定の「あと○日」を正方形のカードの画像にして渡す）

予定の詳細のツールバーから、予定の「あと○日」を正方形（1:1）のカードの画像にして、共有シート（`ShareLink`）で渡す。1.3.0 から。**無料の機能**（Plus に含めない）。
実装は AskHub の epic `01M7YB98BHCBT2K8PEFNR58THM`（t1〜t4）。決まったこと（q1〜q12）はこのファイルの「仕様」にまとめた。

> **仕様の正は [`docs/spec/features/13-share.md`](spec/features/13-share.md)**（仕様リポジトリ `shariverse/app-specs` から生成したもの。Android 版にも同じ仕様が届く）。
> このファイルの「仕様」は実装したときの記録で、食い違ったら `docs/spec/` が正。仕様を変えるときは app-specs に PR を出す。
> コードの場所・テストの口は、このファイルに残す。

## 仕様

### 入口と流れ

1. 予定の詳細のツールバーの「画像でシェア」（SF Symbols の `square.and.arrow.up`）を押す。**入口は詳細のツールバーだけ**（q1）。ホームの行・ウィジェット・ロック画面などには置かない
2. シートでプレビュー画面が開く（q3）。書き出す画像そのものを縮めて見本に出し、その下で載せる項目を切り替える
3. 「シェアする」で共有シートを開く。渡すのは**正方形の PNG の画像だけ**で、文やリンクは添えない（q9）。今の中身で書き出し終えるまでは押せない
4. 「閉じる」で詳細に戻る。ウィジェットのリンクで画面を切り替えるとき（`router.sheetDismissal`）と、予定が消えたときも閉じる

### カード

- 大きさは**正方形だけ**（q2）。一辺 360pt を 3 倍で書き出し、**1080 × 1080 px** の PNG にする。ストーリーズ向けの縦長などの選択肢は作らない
- ダイナミックタイプ・端末の外観（ライト・ダーク）に左右されない（書体は固定の大きさ、外観はカードの側で決める）。同じ中身なら同じ画像になる
- 見た目は出荷するテーマ（地雷系・ゴシック、`AppTheme.shipping`）の地・装飾・書体・角の丸み。テーマの地（十字とハート）の上に、上が推しの写真、下が推し色の塗りのカードを 1 枚の角丸（`heroCard`）につないで置き、`themeCardBorder` で縁取る
- 推し色の役割はテーマで置き換えない（塗りのカード・写真が無いときの模様の色）。推しなしの予定は、ホームと同じ無彩色
- 文字（予定名・日付・会場・日数）は推し色の塗りの上にだけ白で置き、写真の上には重ねない。予定名は 2 行まで
- 本文の書体は日本語のときだけ Kaisei Decol、ほかの言語はシステムの書体。数字はどの言語でも Outfit

### 載せる項目と既定値

| 項目 | 載せるか | 切り替え |
| --- | --- | --- |
| 予定名 | いつも | なし |
| 日付 | いつも（毎年くり返す予定は次の回の日付） | なし |
| 日数 | いつも（下の「日数の見せ方」） | なし |
| 推し色 | いつも | なし |
| 推しの写真 | **既定で載せる** | プレビューで切り替える（写真の無い推し・推しなしの予定では切り替えを出さない） |
| 会場 | **既定で載せない** | プレビューで切り替える（会場の無い予定では切り替えを出さない） |
| 透かし | いつも（全員に小さく入れる） | なし（消す・小さくする選択肢は作らない） |
| 推しの名前 | **載せない**（q7） | なし |

- 写真を外したとき・写真が無いとき・読めないときは、推し色のテーマの模様（`ThemePhotoPlaceholder`。出荷するテーマは十字とハート）にする（q10）
- 切り替えをどちらも出せない予定では、「載せる項目」の欄ごと出さない
- 切り替えを変えたり日付が変わったりしたら、書き出し直す

### 日数の見せ方

日数は暦の日数（`EventCountdown.daysUntil`）で数える。`now` と `Calendar`（タイムゾーン）で決まり、プレビュー画面は端末の今のタイムゾーン（`Calendar.autoupdatingCurrent`）で数える。

| 予定 | カード（ja の例） | 決まり |
| --- | --- | --- |
| 先の予定 | `あと 3 日` | 数字は Outfit。日数は catalog の複数形 |
| 当日・開演の時刻あり | `今日！ 開演 17:00` | 残り日数の代わりに「今日」（q6）。時刻の呼び名は予定の種類による（詳細と同じ `EventText.startTime`） |
| 当日・開演の時刻なし | `今日！` | 「今日」だけ |
| 終わった予定 | `3 日前` | 経った日数（q4）。終わった予定もシェアできる |
| 毎年くり返す予定 | 次の回の日付と `あと N 日` | 次の回（`EventCountdown.occurrenceDay`）だけを出し、くり返しの印や回数は載せない（q5）。2/29 の予定は平年は 2/28 |

- 当日は、開演の時刻の前でも後でも「今日」にする（詳細の秒のカウントダウンと違い、日の単位で見せる）
- 日付は詳細と同じ書き方（`EventText.fullDate`。ja `2026年10月18日(日)`）

### 透かし

- App Store の名前（`docs/app-store/metadata/<言語>.md` のアプリ名）の、コロン（全角を含む）より前のブランド名だけを、アプリの表示言語で入れる（q8・q12）

  | 言語 | 透かし |
  | --- | --- |
  | ja | 推し活カウントダウン |
  | zh-Hans | 追星倒计时 |
  | zh-Hant | 推活倒數 |
  | ko | 최애 디데이 |
  | en・fr・de・es・pt-BR・it・th・id | Oshi Countdown |

- 文言は `Shared/Resources/Localizable.xcstrings` のキー「推し活カウントダウン」（ホームのバーの読み上げ用のタイトルと同じ）。App Store の名前を変えたら、この訳もそろえる
- カードの外の地に右寄せで小さく（11pt）出し、文字に重ねない。読み上げでは読まない

### 読み上げ

見本は画像 1 つにまとめ、予定名・日付・日数・会場（載せるときだけ）を読む（`ShareCardContent.accessibilityLabel`）。透かしは読まない。

### 通信しないこと・権限・プライバシー

- 画像は端末の中で `ImageRenderer` で作り、通信しない。サーバー・解析も使わない。どこに渡すかは利用者が共有シートで選ぶ
- 共有シートの「画像を保存」で写真に追加できるよう、`OshiCon/Info.plist` に `NSPhotoLibraryAddUsageDescription`（写真への追加の説明）を置き、`OshiCon/InfoPlist.xcstrings` に 12 言語の訳を入れた（q11）。
  写真ライブラリを読む `NSPhotoLibraryUsageDescription` は足さない（推しの写真は今までどおり `PhotosPicker` で選ぶ）
- プライバシーマニフェストの申告は変えていない。App のプライバシーは「データの収集なし」のまま（`docs/app-store/app-privacy.md`）

### Plus の着せ替えで差し替える口

カードの見た目は `ShareCardStyle` を通して引く。Plus の着せ替えは、この口に背景の写真の地を渡すだけで、カードの地を差し替える。

```swift
// 出荷するテーマ（既定）
ShareCardPreviewScreen(event: event, oshi: oshi)
// Plus の着せ替え: 地を背景の写真にする（fileName は OshiPhotoLibrary のファイル名）
ShareCardPreviewScreen(event: event, oshi: oshi, style: ShareCardStyle(theme: .shipping, background: .photo(fileName: fileName)))
// 予定の詳細の今の呼び方（Plus と着せ替えの設定から選ぶ）
ShareCardPreviewScreen(event: event, oshi: oshi, style: .appearance(rendering), backgroundPhotos: appearance.photos)
```

- `ShareCardStyle` の値
  - `theme`: 地・装飾・書体・角の丸みを引くテーマ。既定は `AppTheme.shipping`
  - `background`: カードの地。`.theme`（既定。テーマの地）か `.photo(fileName:)`（取り込んだ画像を地にし、透かしを読めるよう黒を重ねて透かしを白にする）。画像が読めないときはテーマの地にする
  - `colorScheme`: 書き出す外観。既定は `.dark`
- 差し替えても変えないもの: 推し色の役割（塗りのカード・模様の色）・載せる項目・日数の見せ方・透かし・正方形の大きさ
- 詳細の画面（`EventDetailScreen`）は、Plus が使えるか（`@Environment(\.isPlusUnlocked)`）と着せ替えの設定（`AppearanceStore`）から描くもの（`AppearanceRendering`）を決め、
  `ShareCardStyle.appearance(_:)` で選んだ `style` を渡す
  - Plus が使え、背景の写真を ON にしていて写真がある: `ShareCardStyle(theme: .shipping, background: .photo(fileName:))`（着せ替えの背景の写真。暗幕・ぼかしと飾りはカードに関わらない）
  - それ以外（Plus でない・解約・期限切れ・背景が OFF・写真が無い・飾りだけ）: `.shipping`。選んだ画像は消さない
  - 着せ替えの背景の写真は推しの写真と別の置き場所（`AppearanceStore.photos`。メモリ上のストアでは一時ディレクトリ）から読むので、`ShareCardPreviewScreen` の `backgroundPhotos` にその置き場所を渡す（`ShareCardImages.load` の `backgroundPhotos`。nil なら `photos`）
  - 規則のテストは `OshiConTests/Share/ShareCardAppearanceStyleTests`
  - 着せ替えそのもの（背景の写真・飾り・設定・着せ替えの画面）の仕様は [appearance.md](appearance.md)

### 作らないもの

- 詳細のツールバー以外からのシェア、正方形以外の大きさ
- 推しの名前・文・リンクを載せる・添えること
- 透かしを消す・小さくする選択肢
- 通信・サーバー・解析、SwiftData のスキーマの変更

## コードの場所

| 役割 | 場所 |
| --- | --- |
| カードの中身の規則（予定名・日付・日数・会場・推し色・写真・透かし、切り替えを出せるか） | `OshiCon/Share/ShareCardContent.swift`（`nonisolated struct ShareCardContent`・`Options`・`Days`） |
| 経った日数の文言（`3 日前`） | `Shared/Domain/EventText.swift`（`daysAgoParts(days:locale:)`） |
| 見た目の差し替え口・書体・描く前に読み込む画像・大きさ | `OshiCon/Share/ShareCardStyle.swift`（`ShareCardStyle`・`ShareCardImages`・`ShareCardSize`） |
| 正方形のカードの View（`#Preview` は写真あり・なし・終わった・当日・長い予定名・英語・着せ替えの地） | `OshiCon/Share/ShareCardView.swift` |
| PNG への書き出し（`ImageRenderer`。メインアクター）と共有に渡す画像（`Transferable`） | `OshiCon/Share/ShareCardRenderer.swift`（`ShareCardRenderer`・`ShareCardImage`） |
| プレビュー画面（見本・載せる項目の切り替え・`ShareLink`） | `OshiCon/Share/ShareCardPreviewScreen.swift` |
| 入口（ツールバーのボタン・シートを閉じるきっかけ） | `OshiCon/Screens/EventDetail/EventDetailScreen.swift` |
| 写真への追加の説明 | `OshiCon/Info.plist`・`OshiCon/InfoPlist.xcstrings`（`NSPhotoLibraryAddUsageDescription`） |
| 文言（プレビュー画面・透かし） | `Shared/Resources/Localizable.xcstrings` |

## テスト

- Unit（Swift Testing）: `OshiConTests/Share/`
  - `ShareCardContentTests`: `Calendar` と現在時刻を注入して、残りがある・日付の変わり目（23:59:59 と 0:00）・当日（時刻あり／なし、開演の前と後）・終わった・くり返し（年をまたぐ・2/29）・タイムゾーン（東京とロサンゼルス）・会場と写真の有無と既定値・推しなし・推しの名前が載らないこと・英語・透かしの 12 言語
  - `ShareCardRendererTests`: 1080 px 四方の PNG になること、ダイナミックタイプや端末の外観を変えても画素が同じこと、書体（日本語だけテーマの書体・数字は Outfit・固定の大きさ）、写真と模様の描き分け、着せ替えの地（読めないときはテーマの地）
  - `ShareCardAppearanceStyleTests`: 着せ替えの設定と Plus からカードの地を選ぶ規則、カードの地の画像を `backgroundPhotos` から読むこと
  - `ShareCardSharingTests`: 共有に渡すのが書き出した PNG そのものであること（iOS 18.2 以降）、Info.plist に写真への追加の説明だけがあり読む説明が無いこと、その説明の 12 言語の訳
  - `OshiConTests/Domain/EventTextTests`: `daysAgoParts`
- UI（XCTest）: `OshiConUITests/ShareCardUITests`。起動引数 `-useInMemoryStore -useTestPhoto` と日本語で起動し、詳細のシェアのボタン（`eventDetail.share`）からプレビューを開いて、
  見本（`shareCard.preview`）・会場の切り替え（`shareCard.includesVenue`）・写真の切り替え（`shareCard.includesPhoto`）・シェアのボタン（`shareCard.share`）まで通す。推しなし・会場なしの予定では切り替えが出ないことも確かめる
- 共有シートそのものは別のプロセスの画面なので、UI テストでは開かない。「画像を保存」で写真に追加できることは実機で確かめる
