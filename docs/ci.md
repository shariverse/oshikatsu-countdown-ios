# ブランチ運用と CI

- 作業は `develop` から作業ブランチを切ります。AskHub の epic は、ワーカーが作業ブランチ `askhub/<epic の id>` を `develop` から作り、子 PR をそこに集め、最終 PR で `develop` に取り込みます
- `develop`・`main`・`release/**` は、ルールセットで PR 必須・`build / build` 必須・force push と削除の禁止にしています。管理者にも効くので、直接 push はできません

| ブランチ | Build（ビルド + テスト + SwiftLint） | Archive（IPA Export） | Upload（App Store Connect） |
|---|:-:|:-:|:-:|
| `main` | ✅ | | |
| `develop` | ✅ | | ✅ |
| `release/**` | ✅ | | ✅ |
| その他の作業ブランチ | ✅（Unit テストのみ） | | |
| Pull Request の作成時（opened / reopened / ready_for_review） | ✅ | | |
| AskHub の子 PR（作業ブランチ `askhub/**` 宛て） | PR では実行しない（push の Unit テストだけ） | | |
| AskHub の最終 PR（`askhub/**` → `develop`） | ✅（更新のたびに UI テストまで） | | |
| Fork からの Pull Request | ✅ | | |
| 手動実行（Actions タブの Run workflow） | | ✅ | ✅ |

- `main` への push で動くのは Build だけです。Archive は動かしません
- Upload は Archive → IPA Export を含むため、`develop` / `release/**` では Archive を別途実行しません
- Archive は Actions タブからの手動実行（Run workflow）だけで動きます。署名と IPA Export が通ることを確かめたいときに、ブランチを選んで実行します
- Upload も Actions タブから手動で実行できます。作業ブランチを TestFlight で確認したいときは、Upload を手動実行してそのブランチを選びます
- リポジトリ変数（Settings → Secrets and variables → Actions → Variables）に `ENABLE_DELIVERY=false` を設定すると Upload をスキップします（Archive は App Store Connect にアプリが無くても通るため止めません）。テンプレートリポジトリ自身はこの設定でアップロードを止めています。テンプレートから作成したリポジトリには引き継がれないため、何もしなければ従来どおり実行されます
- Build はドキュメントだけの変更でも実行します。ルールセットで `build / build` を必須にしているため、飛ばすとチェックが出ず、PR をマージできなくなります
- 作業ブランチへの push では、時間のかかる UI テスト（`<プロジェクト名>UITests`）を省いて Unit テストだけ実行します。UI テストは Pull Request の作成時と `main` / `develop` / `release/**` への push で実行します。AskHub の子 PR（`askhub/**` 宛て）は PR のイベントでは実行せず（ワーカーが手元でテストを流してから出すため）、作業ブランチ → `develop` の最終 PR は更新（synchronize）でも UI テストまで実行します。Fork からの Pull Request は push で実行されないため、更新（synchronize）を含むすべてのイベントで UI テストまで実行します
- Xcode のバージョンは [.github/workflows/_build.yml](../.github/workflows/_build.yml) と [.github/workflows/_archive.yml](../.github/workflows/_archive.yml) の `xcode-version` で固定しています。Environment の更新時はあわせて変更してください
