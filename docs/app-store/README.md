# App Store 公開用の文面（下書き）

推し活カウントダウン iOS 版（OshiCon）を App Store で公開するときに使う文面の下書きです。
ループ（epic/mvp）が仕様（Android 版の SPEC）とアプリの実装から書きました。**公開・登録の前に、人間が中身を確かめてください。**

| ファイル | 中身 | 使う場所 |
| --- | --- | --- |
| [listing.md](listing.md) | アプリ名の候補・サブタイトル・プロモーションテキスト・説明文・キーワード・カテゴリ | App Store Connect の「App 情報」「App Store」タブ |
| [privacy-policy.md](privacy-policy.md) | プライバシーポリシー | 公開した URL を「App 情報」のプライバシーポリシー URL に入れる |
| [support.md](support.md) | サポートページ（よくある質問・お問い合わせ） | 公開した URL を「App Store」タブのサポート URL に入れる |
| [app-privacy.md](app-privacy.md) | 「App のプライバシー」の回答案と、輸出コンプライアンス | App Store Connect の「App のプライバシー」 |
| [review-notes.md](review-notes.md) | 審査用メモ（審査員への説明） | App Store Connect の「App Review に関する情報」のメモ |

## 決まっていないこと（人間が決める）

- **プライバシーポリシーとサポートページをどこに公開するか・誰が書いた名義にするか**（GitHub Pages など）。下書きの `{{…}}` を埋めてから公開する
- **App Store Connect のアプリ名**（ホーム画面の表示名は「推し活カウント」。[listing.md](listing.md) に候補を書いた）
- 提供者名・お問い合わせ先のメールアドレス（[privacy-policy.md](privacy-policy.md)・[support.md](support.md) の `{{…}}`）
- 価格と配信国、年齢制限の回答（[listing.md](listing.md) に案を書いた）

## 書くときに守ったこと

- 文言は日本語だけ（英語のページは作らない）
- アプリにない機能（通知・広告・シェア・検索・カレンダー・iCloud 同期・ロック画面ウィジェット）を書かない
- データは端末の中だけ・通信しない、という実装と食い違うことを書かない。端末のバックアップ（iCloud・パソコン）には含まれることは、設定画面の説明と同じく書く
