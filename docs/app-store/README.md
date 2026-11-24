# App Store 公開用の文面（下書き）

推し活カウントダウン iOS 版（OshiCon）を App Store で公開するときに使う文面の下書きです。
ループ（epic/mvp）が仕様（Android 版の SPEC）とアプリの実装から書きました。**公開・登録の前に、人間が中身を確かめてください。**

| ファイル | 中身 | 使う場所 |
| --- | --- | --- |
| [metadata/](metadata/) | 言語ごと（14 言語）のアプリ名・サブタイトル・プロモーションテキスト・説明文・キーワード | App Store Connect の「App 情報」「App Store」タブ（言語ごと） |
| [listing.md](listing.md) | 掲載文のファイルの一覧と書き方・マーケティング URL（全言語で共通）・カテゴリ・年齢制限・スクリーンショット | App Store Connect の「App 情報」「App Store」タブ |
| [privacy-policy.md](privacy-policy.md) | プライバシーポリシー | 公開した URL を「App 情報」のプライバシーポリシー URL に入れる |
| [support.md](support.md) | サポートページ（よくある質問・お問い合わせ） | 公開した URL を「App Store」タブのサポート URL に入れる |
| [app-privacy.md](app-privacy.md) | 「App のプライバシー」の回答案と、輸出コンプライアンス | App Store Connect の「App のプライバシー」 |
| [whats-new/](whats-new/) | バージョンごと（`<バージョン>.md`）の、言語ごと（14 言語）の「このバージョンの新機能」 | App Store Connect の「App Store」タブ（言語ごと）の「このバージョンの新機能」 |
| [review-notes.md](review-notes.md) | 審査用メモ（審査員への説明。日本語版と英語版） | App Store Connect の「App Review に関する情報」のメモ |
| [sample-oshi-photos.md](sample-oshi-photos.md) | App Store 用スクリーンショットの見本の推しの写真（フリー素材）の出典・ライセンス・置き場所 | スクリーンショットとクリエイティブアセット（`AppStoreScreenshotTests`） |
| [in-app-purchases.json](in-app-purchases.json) | 課金の商品（推し活カウントダウン Plus の月額・年額・買い切り）の productId・価格・14 言語の表示名と説明 | ワークフロー「App Store In-App Purchases」で App Store Connect の「サブスクリプション」「App 内課金」に登録する（README の「課金の商品の登録」） |

## 決まっていないこと（人間が決める）

アプリ名は「推し活カウントダウン」に決まった（Discussion #58。ホーム画面の表示名は「推し活カウント」のまま）。App Store Connect で名前が空いているかは、登録するときに人間が確かめる。

- **サポートページをどこに公開するか**。下書きの `{{…}}` を埋めてから公開する
  - プライバシーポリシーは https://shilokuma.jp/privacy/oshikatsu-countdown/ に公開している（shilokuma-inc/shilokuma-web の `privacy/oshikatsu-countdown/`）。
    公開しているページの文面と [privacy-policy.md](privacy-policy.md) の下書きは別に書いてあるので、中身を変えたら公開しているページも直す。課金画面のリンク（`PlusLegalLink.privacyPolicy`）もこの URL
- 提供者名・お問い合わせ先のメールアドレス（[privacy-policy.md](privacy-policy.md)・[support.md](support.md) の `{{…}}`）
- 価格と配信国、年齢制限の回答（[listing.md](listing.md) に案を書いた）

## 書くときに守ったこと

- App Store の掲載文（[metadata/](metadata/)）は 14 言語（en を既定に、en-GB, ja, zh-Hans, zh-Hant, ko, fr, de, es, es-MX, pt-BR, it, th, id）。直訳せず、その言語の推し活のファンに自然な言い方にする。審査用メモは日本語と英語。それ以外の文面（プライバシーポリシー・サポートページなど）は日本語だけ
  - en-GB（英国）と es-MX（メキシコ・中南米）は、ストアの掲載だけの言語。アプリの訳は持たず、アプリは en・es で出る（[languages.json](languages.json) の `appleLocale` で、スクリーンショットの日付や数字の書き方だけ英国・メキシコになる）。
    文面は en・es をもとに、en-GB は英国のつづり（colour・favourite・cancelled）と言い方（gig）、es-MX は中南米の言い方（cuenta regresiva・agregar・computadora）と iOS の呼び名（Actividad en vivo・Configuración）に直す。アプリの画面・機能の名前は、アプリの訳（en・es）のままにする。
    サブタイトルとキーワードは en・es と語を分け、en・es のサブタイトルに入れた語をキーワードに回す
  - 言語を足すと、掲載文・whats-new の見出し・クリエイティブ（[creative/creative.html](creative/creative.html) の文言）・課金の商品の表示名（[in-app-purchases.json](in-app-purchases.json) と `Configs/OshiCon.storekit`）が、その言語ぶん要る（無いとワークフローが止まる）
- アプリにない機能（広告・検索・カレンダー・iCloud 同期など）を書かない
  - シェアと Plus は 1.3.0 で入ったので、1.3.0 から掲載文（説明文・プロモーションテキスト）と whats-new に書いている。1.3.0 より前の版の掲載文を登録し直すときは、Plus とシェアの段落を外す
  - Plus を書くときは、有料と分かるように「（有料）」を付け（審査ガイドライン 2.3.2）、今ある無料の機能（数える・ウィジェット・通知・ロック画面・ライブアクティビティ・シェア）はこれからも無料と書く。
    説明文には、自動更新・無料のお試しのあとの課金・解約の方法（3.1.2）と、利用規約（Apple の標準 EULA）・プライバシーポリシーの URL を全言語で載せる。価格の数字はどこにも書かない（国で変わる。アプリ名・サブタイトルは 2.3.7）
  - Plus の入口は `PlusEntryPolicy.showsEntry(in:)` が App Store 版で出すようにしてから、Plus を書いた掲載文を登録する（入口が無いのに説明文に書くと、審査で機能が見つからない）
  - 課金の仕組み（StoreKit）はアプリに入っているので、プライバシーポリシー・App のプライバシーには購入の扱いを書く（Plus を買える版より前に公開しても、購入しなければ当てはまらない書き方にする）
  - 審査用メモの Plus の段落は、Plus の入口を App Store 版で出す版（1.3.0）を審査に出すときのもの。それより前の版で出すときは外す（[review-notes.md](review-notes.md) の冒頭）
- アプリ名は変えない（Discussion #58）。検索の語は、サブタイトル（30 文字を使い切る）とキーワードで取る。サブタイトル・アプリ名に入れた語はキーワードから外す。
  実在のアーティスト名・競合のアプリ名・"app"・"free"・価格は入れない（2.3.7）。英語圏では "oshi" がほとんど検索されないので、en は K-pop・bias・idol・concert・D-day の語で取る
- データは端末の中だけ・通信しない、という実装と食い違うことを書かない。端末のバックアップ（iCloud・パソコン）には含まれることは、設定画面の説明と同じく書く
