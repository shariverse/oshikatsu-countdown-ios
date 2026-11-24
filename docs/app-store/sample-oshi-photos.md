# App Store 用スクリーンショットの見本の推しの写真

App Store 用スクリーンショット（`AppStoreScreenshotTests`）と、そこから書き出すクリエイティブアセットで、見本の推し（`SampleData`）のアイコンと予定の詳細の上の帯に出す写真（#276）。
頭文字だけだと実際に使っている感じが伝わらないので、商用利用できるフリー素材を加工して使う。

## 置き場所と仕組み

- 画像は `OshiConUITests/SampleOshiPhotos/sample-oshi-<役どころ>.jpg`（UI テストのバンドルに入る）。**アプリには入れない**（アプリの容量を増やさない）
- `AppStoreScreenshotTests` が、画像のあるディレクトリを環境変数 `OSHICON_SAMPLE_OSHI_PHOTOS` でアプリに渡す。Simulator のアプリはホストのファイルを読めるので、場所だけを渡す
- アプリは `-useInMemoryStore -seedSampleData` のときだけ（`LaunchOptions.sampleOshiPhotosDirectory`）、役どころごとの画像を推しの写真の置き場所（`OshiPhotoLibrary.shared`）に `<UUID>.jpg` の名前で写し、見本の推しに付ける（`SampleData.attachingPhotos(to:from:library:)`）
- 環境変数を渡さないテスト（`AppearanceUITests` など、`-seedSampleData` を使うほかの UI テスト）では、今までどおり写真なし（頭文字）

## 使っている画像

どれも、元の画像を一辺 1024px の正方形に切り抜き、顔にかからない周りに小さなキラキラ（光の筋と丸い光）を足して、撮影情報（EXIF）を消した JPEG。

| ファイル | 役どころ（見本の推し） | 出典 | 作者 | ライセンス |
| --- | --- | --- | --- | --- |
| `sample-oshi-group.jpg` | アイドルグループ（LUMINA） | [Pexels 8392623](https://www.pexels.com/photo/a-portrait-of-a-young-man-in-a-trendy-outfit-8392623/) | eman-genatilan | [Pexels License](https://www.pexels.com/license/) |
| `sample-oshi-voice-actor.jpg` | 声優（ミナト ほか） | [Pexels 6892711](https://www.pexels.com/photo/a-man-in-a-blue-sweater-holding-a-microphone-6892711/) | cottonbro studio | [Pexels License](https://www.pexels.com/license/) |
| `sample-oshi-character.jpg` | アニメ・ゲームのキャラクター（レオ ほか） | [Pixabay 7968884](https://pixabay.com/illustrations/ai-generated-man-visual-novel-7968884/) | meteoras | [Pixabay Content License](https://pixabay.com/service/license-summary/)（AI 生成のイラスト） |
| `sample-oshi-stage-actor.jpg` | 舞台俳優（レン ほか） | [Pexels 3891294](https://www.pexels.com/photo/man-in-white-crew-neck-t-shirt-3891294/) | streetwindy | [Pexels License](https://www.pexels.com/license/) |
| `sample-oshi-streamer.jpg` | 配信者（ひなた ほか） | [Pexels 7858757](https://www.pexels.com/photo/man-wearing-gray-shirt-wearing-black-headphones-7858757/) | Ron Lach | [Pexels License](https://www.pexels.com/license/) |
| `sample-oshi-singer.jpg` | 歌手（ソラ ほか） | [Pexels 5104964](https://www.pexels.com/photo/a-man-singing-in-front-of-a-condenser-microphone-5104964/) | Teddy Yang | [Pexels License](https://www.pexels.com/license/) |

- 作者は、Teddy Yang と meteoras は出典のページで確かめた名前。それ以外は Pexels のダウンロードのファイル名にあるハンドル
- 歌手の写真は、後ろに写っていた別の人（ピアノの奏者）を切り抜きで外した。キャラクターのイラストは、無料で取れる大きさ（853 × 1280px）から少し引き伸ばしている

## 守ること

- **実在の有名人・既存の作品のキャラクター・VTuber・ロゴは使わない**（自由に使える肖像が無い）。写真は一般のモデル、イラストは既存の作品のものではない素材にする
- **加工した画像だけを置き、元の画像はリポジトリに置かない**。Pexels License も Pixabay Content License も、加工しない画像をそのまま再配布すること・素材集として配ることを禁じている
- 写真の人物は、本人が推しているように見せたり、悪く見せたりしない（Pexels License の禁止事項）。モデルリリース（本人の使用許諾）は無く、年齢の記載も無い。気になる素材があれば差し替える
- 画像を差し替える・足すときは、この表に出典・作者・ライセンスを書き足す。ファイル名は `SampleData.Role.photoFileName`（`sample-oshi-<役どころ>.jpg`）に合わせる
