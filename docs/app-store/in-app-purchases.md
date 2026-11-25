# 課金の商品の登録

Actions タブの「App Store In-App Purchases」を手動実行すると、[docs/app-store/in-app-purchases.json](in-app-purchases.json) の課金の商品（推し活カウントダウン Plus の月額・年額のサブスクリプションと、買い切りの非消耗型）を App Store Connect API で登録します。
既定は確認だけで、何も作りません。**productId は一度作ると変えられず、消しても同じ ID は使えない**ので、確認の結果（Job Summary）を見てから `apply` を付けて作ります。

```bash
# 確認だけ（作るもの・入れるものを表示する）
gh workflow run app-store-purchases.yml --ref develop
# 作る
gh workflow run app-store-purchases.yml --ref develop -f apply=true
```

- サブスクリプショングループは `referenceName`、商品は `productId` で探し、無ければ作ります。何度流しても二重には作りません。途中で失敗したら、直してから流し直すと続きから入れます
- 表示名と説明は App Store に載せる 14 言語（[docs/app-store/languages.json](languages.json)。アプリの 12 言語と、en-GB・es-MX）ぶん入れます。言語が足りない・文字数（表示名 30 文字・説明 45 文字）を超えるときは、何も登録せずに止まります
- 価格は `baseTerritory`（日本）の税込みの価格で、ほかの国・地域は App Store Connect の換算に合わせます。その価格が日本の価格の刻みに無ければ、近い価格を出して止まります
- 販売地域はすべての国・地域と、新しく増える国・地域です。年額には 1 週間の無料のお試しを付けます。ファミリー共有は OFF です（一度 ON にすると戻せません）
- サブスクリプションの販売地域・価格・お試しは、すでに入っているものを変えません（価格の変更は App Store Connect の画面で行います）。非消耗型の価格は毎回入れ直します（同じ価格なら変わりません）
- 審査用のスクリーンショット（課金画面）と審査への提出は扱いません。課金画面ができてから App Store Connect の画面で入れます。最初の課金の商品は、アプリの新しいバージョンと一緒に審査に出します

## 手元での課金の確かめ方

- [Configs/OshiCon.storekit](../../Configs/OshiCon.storekit) は、`in-app-purchases.json` と同じ商品（サブスクリプショングループ OshiCon Plus の年額 1,980 円・1 週間の無料のお試し、月額 280 円、非消耗型の買い切り 4,800 円。ファミリー共有は OFF、表示名と説明は 14 言語）を入れた StoreKit Configuration ファイルです。
  ストアフロントは日本です。共有スキーム OshiCon の Run（Options の StoreKit Configuration）と Test（テストプラン [OshiCon.xctestplan](../../OshiCon.xctestplan) の StoreKit Configuration）に設定してあり、Simulator では App Store Connect に繋がずに購入・復元・期限切れを試せます（Xcode の Debug → StoreKit → Manage Transactions）
- 商品を変えたら `in-app-purchases.json` と `.storekit` の両方を直します（`StoreKitConfigurationTests` が食い違いを見つけます）
- UI テストとスクリーンショット（`-useInMemoryStore` のとき）は StoreKit に問い合わせず、Plus は使えない状態に固定します。起動引数 `-plusUnlocked` で使える状態に、`-plusLocked` で使えない状態にします（`LaunchOptions.unlocksPlus`。両方渡したときは `-plusLocked` を優先します）
- 課金画面の入口（設定の Plus の行）は、1.3.0 から App Store 版を含むどの配り方でも出します（`PlusEntryPolicy`。それまでは開発版と TestFlight だけ。配り方は `AppTransaction` の環境で端末の中で見分けます）。
  起動引数 `-simulateAppStoreDistribution`（`-useInMemoryStore` のときだけ効く）で App Store 版として動かします。App Store 用スクリーンショットはこれを渡します
