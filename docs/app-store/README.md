# App Store 公開用の文面（下書き）

推し活カウントダウン iOS 版（OshiCon）を App Store で公開するときに使う文面の下書きです。
ループ（epic/mvp）が仕様（Android 版の SPEC）とアプリの実装から書きました。**公開・登録の前に、人間が中身を確かめてください。**

| ファイル | 中身 | 使う場所 |
| --- | --- | --- |
| [metadata/](metadata/) | 言語ごと（12 言語）のアプリ名・サブタイトル・プロモーションテキスト・説明文・キーワード | App Store Connect の「App 情報」「App Store」タブ（言語ごと） |
| [listing.md](listing.md) | 掲載文のファイルの一覧と書き方・カテゴリ・年齢制限・スクリーンショット | App Store Connect の「App 情報」「App Store」タブ |
| [privacy-policy.md](privacy-policy.md) | プライバシーポリシー | 公開した URL を「App 情報」のプライバシーポリシー URL に入れる |
| [support.md](support.md) | サポートページ（よくある質問・お問い合わせ） | 公開した URL を「App Store」タブのサポート URL に入れる |
| [app-privacy.md](app-privacy.md) | 「App のプライバシー」の回答案と、輸出コンプライアンス | App Store Connect の「App のプライバシー」 |
| [review-notes.md](review-notes.md) | 審査用メモ（審査員への説明。日本語版と英語版） | App Store Connect の「App Review に関する情報」のメモ |

## 決まっていないこと（人間が決める）

アプリ名は「推し活カウントダウン」に決まった（Discussion #58。ホーム画面の表示名は「推し活カウント」のまま）。App Store Connect で名前が空いているかは、登録するときに人間が確かめる。

- **プライバシーポリシーとサポートページをどこに公開するか・誰が書いた名義にするか**（GitHub Pages など）。下書きの `{{…}}` を埋めてから公開する
- 提供者名・お問い合わせ先のメールアドレス（[privacy-policy.md](privacy-policy.md)・[support.md](support.md) の `{{…}}`）
- 価格と配信国、年齢制限の回答（[listing.md](listing.md) に案を書いた）

## 書くときに守ったこと

- App Store の掲載文（[metadata/](metadata/)）は 12 言語（en を既定に、ja, zh-Hans, zh-Hant, ko, fr, de, es, pt-BR, it, th, id）。直訳せず、その言語の推し活のファンに自然な言い方にする。審査用メモは日本語と英語。それ以外の文面（プライバシーポリシー・サポートページなど）は日本語だけ
- アプリにない機能（通知・広告・シェア・検索・カレンダー・iCloud 同期・ロック画面ウィジェット）を書かない
- データは端末の中だけ・通信しない、という実装と食い違うことを書かない。端末のバックアップ（iCloud・パソコン）には含まれることは、設定画面の説明と同じく書く
