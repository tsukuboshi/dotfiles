# General Rules

## 破壊的操作の制限

復元不可能な操作を防ぐため、以下の代替コマンドを使用する。

| 禁止コマンド | 代替コマンド | 理由 |
| --- | --- | --- |
| `rm` | `trash` | ゴミ箱に移動し、誤削除からの復元を可能にする |
| `git checkout` | `git switch`（ブランチ切替）/ `git stash`（変更退避） | 変更の暗黙的な破棄を防ぐ |
| `git restore` | `git stash` | 変更を保全した上で復元する |
| `git clean` | `git stash -u` | 未追跡ファイルも含めて退避する |
| `git reset --hard` | `git reset`（`--hard` なし）+ `git stash` | `--hard` なしならワーキングツリーを破壊しない |
| `git branch -D` | `git branch -d` | 上流ブランチか HEAD にマージ済みでないと削除を拒否し、どこからも参照されないコミットを生まない |

スクリプトに書いたこれらのコマンドも、編集時とコミット前の hook が ast-grep で検出する。

## ツールの実行

ファイルの編集・読み取り・検索は、Bash より組み込みツールを優先する。

| 操作 | 組み込みツール | Bash での相当コマンド |
| --- | --- | --- |
| 編集 | Edit / Write | `sed`、Python の heredoc |
| 読む | Read | `cat`、`head`、`tail` |
| ファイル名で探す | Glob（ツール一覧にあるとき） | `find` |
| 内容で探す | Grep（ツール一覧にあるとき） | `grep`、`rg` |

Bash で行うと、定型コードの記述と auto モードの権限審査で 1 回あたり十数秒余計にかかり、出力も未整形で次の操作に使いにくい。
Read は行番号付きで部分読みもできるため、ファイルの一部を見るときも `offset` / `limit` を使う。
Bash を使うのは、多数のファイルへ同じ置換を機械的に適用するとき、組み込みの検索ツールが無いとき、組み込みツールで表現できない条件（更新日時・サイズでの絞り込み、パイプでの集計など）で探すときに限る。

## Git の運用

コミットや PR 作成に着手する前に `git branch --show-current` で作業ブランチを確認する。
デフォルトブランチ（`main` / `master`）上でコミットを求められた場合は、ユーザーがコミット先を明示していない限り、実行前にブランチを切るかどうかを確認する。

rebase や amend の後にユーザーへ force push を依頼するときは、`git push --force-with-lease --force-if-includes` を提示する。
`--force-with-lease` はリモートのブランチがリモート追跡ブランチと一致する場合だけ上書きし、他者が先に push したコミットを消さない。
ただし IDE などがバックグラウンドで fetch するとリモート追跡ブランチが黙って最新になり、このチェックが素通りする。
`--force-if-includes` を併用すると、リモート追跡ブランチの先端がローカルブランチの reflog から辿れること、つまりリモートの更新を手元に取り込み済みであることも確かめてから上書きする（出典: `git help push`）。

## GitHub 操作

GitHub の Issue・PR・Actions を扱うときは、`gh` コマンドの代わりに以下のスキルを使う。
`gh` の OAuth トークンは必要以上に広い権限を要求し、fine-grained PAT は organization の private リポジトリで 404 を返すため、ログイン済みブラウザの GitHub Web UI 経由で操作する。

| 操作 | スキル |
| --- | --- |
| Issue を作成する | `open-issue` |
| PR を作成する | `open-pr` |
| Issue とコメントを読む | `read-issue` |
| PR の説明・コメント・レビュー・差分を読む | `read-pr` |
| Actions のワークフロー実行結果・失敗ログを読む | `read-action` |

## `grilling` / `grill-with-docs` スキル発火時の開発ワークフロー

`grilling` または `grill-with-docs` が発火された場合、以下の 4 フェーズを **一連のシーケンス** として最後まで実行する。各フェーズが完了したら、簡潔な完了報告を行った上で続けて次フェーズを起動する。

| # | フェーズ | ツール | アクション | 完了条件 |
| --- | --- | --- | --- | --- |
| 1 | 要件定義・設計 | `grilling` または `grill-with-docs` スキル / `context7` MCP（フォールバック: WebSearch / WebFetch） | 設計ツリーをラウンド単位で潰しながら公式ドキュメント・参考実装・論文を収集する | フロンティアが空になり、ユーザーが共有理解を確認したとき |
| 2 | 計画 | plan mode | プランファイルを書き起こす | ユーザーがプランを承認したとき |
| 3 | 実装 | `/goal` コマンド + `tdd` スキル | `/goal <測定可能な完了条件> or stop after N turns` の起動を提案して完了条件を宣言し（条件は Claude の出力から達成を判定できる形で書く。例: `npm test` が exit 0 になる）、RED-GREEN ループを `tdd` スキルで回す | テストが通ったとき |
| 4 | レビュー | `code-review` スキル + `security-review` スキル | Agent ツールで別エージェントを 2 つ並列起動し、一方は `code-review`（バグ・再利用・品質・効率性。再利用は `jscpd --ignore-identifiers <変更したディレクトリ>` の重複検出で裏付ける）、他方は `security-review`（ブランチ差分のセキュリティ）で指摘を収集する。修正はメインセッションで直列に適用する | 両レビューの全指摘に対処し、ユーザーへ最終報告したとき |

## 補助スキル

以下はユーザーが `/` で起動するスキル。該当する状況に至ったら起動を提案する。

| スキル | 提案するタイミング |
| --- | --- |
| `handoff` | コンテキストが逼迫し、作業を別セッションへ引き継ぐとき。`/handoff <次セッションの目的>` の形で目的を添えるよう促す |
| `to-questionnaire` | grilling のラウンドで、ユーザー単独では答えられない質問が出たとき |
| `wait-what` | こちらの説明が伝わらなかったとき |
| `teach` | 設計・実装の前提となる概念をユーザーが学びたいとき。起動したディレクトリを学習ワークスペースとして多数のファイルを生成するため、学習用の空ディレクトリで起動するよう促す |
| `loop` | デプロイ・CI・PR など外部状態の変化を定期的に確認し続けたいとき。`/loop <間隔> <プロンプト>`（間隔を省略すると Claude が間隔を自動調整する）の形で起動するよう促す |
| `ask-matt` | どのスキル・フローを使うべきか迷ったとき。mattpocock スキル群のルーターとして現状に合う経路を示す |
| `wayfinder` | 1 セッションに収まらない規模で、決めるべきことがまだ霧の中のとき。決定チケットの地図を作り 1 セッション 1 枚ずつ解決する。地図が晴れたら `/to-spec` へ渡す |
| `to-spec` | 詰め終えた会話を spec に起こすとき。インタビューせず会話を合成し、テストする seam を確認した上で Issue 化する |
| `to-tickets` | spec を実装単位に割るとき。各チケットは依存関係を宣言した垂直スライスで、1 フレッシュコンテキストに収まるサイズにする |
| `implement` | agent-ready なチケットを実装するとき。1 チケット = 1 セッションで、内部で `tdd` と `code-review` を駆動する。次のチケットに移る前に `/clear` を促す |
| `triage` | 他者から届いた issue・PR を分類・検証して agent-ready にするとき。`to-tickets` が作ったチケットは既に agent-ready なので対象外 |
| `improve-codebase-architecture` | コードベースの設計改善候補を洗い出したいとき。HTML レポートで候補を提示し、選ばれた候補を grilling で詰める |

`to-spec` / `to-tickets` / `triage` / `wayfinder` が Issue を発行・操作するときは、`open-issue` / `open-pr` と同様に GitHub Web UI（Issue 作成 URL をブラウザで開く）を使う。ラベル付与や blocking link の設定は Web UI 上の操作としてユーザーに依頼し、Web UI で表現しきれない依存関係はチケット本文に記載する。

以下は自動発火するため、明示的な起動は不要。

| スキル | 役割 |
| --- | --- |
| `domain-modeling` | `CONTEXT.md` / ADR の作成・更新 |
| `writing-for-agents` | スキル・`CLAUDE.md`・`AGENTS.md` の執筆 |
| `codebase-design` | deep module 設計の共有語彙（module / interface / seam / adapter）。`tdd` の seam 議論や `improve-codebase-architecture` から参照される |
| `diagnosing-bugs` | 難しいバグ・性能劣化の診断。まずそのバグで red になる 1 コマンドを作る |
| `prototype` | 設計上の問い 1 つに答える使い捨てコード |
| `research` | 一次資料に当たる調査をバックグラウンドエージェントに任せ、出典付き Markdown に残す |
| `resolving-merge-conflicts` | 進行中の merge / rebase コンフリクトの解決 |
| `wizard` | 人間にしかできない手順を対話式 bash ウィザードにする |

## OSS として公開するもの

単体の OSS リポジトリ（CLI・ライブラリなど）と、親リポジトリ内で作り後から単体の OSS リポジトリとして切り出す拡張（スキル・フック、リンターのルール・プリセット、エディタ拡張など）は、最初から以下の作法で作る。
ツール固有のレイアウトやマニフェストは、そのツールの公式ドキュメントに従う。

| 対象 | 作法 | 出典 |
| --- | --- | --- |
| 構成（親リポジトリ内で作る場合） | 1 プラグイン = 1 ディレクトリにまとめ、その直下を将来のリポジトリルートとみなす。参照はディレクトリ内に閉じた相対パスで書く。`git subtree split -P <dir>` はそのディレクトリに触れたコミットだけを、ディレクトリ直下をルートにした履歴として取り出す | `git help subtree` |
| コミット（親リポジトリ内で作る場合） | ディレクトリ外の差分は split で落ちるが、コミットメッセージはそのまま残る。プラグイン内の変更は、メッセージ単独で意味が通るコミットにまとめる | `git help subtree` |
| README | 英語の `README.md` に、何をするか・なぜ有用か・始め方・助けを得る場所・メンテナを書く。日本語の補足は `README.ja.md` に分ける | <https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/about-readmes> |
| ライセンス | MIT の `LICENSE` を置き、マニフェストの `license` に SPDX 識別子 `MIT` を書く。依存パッケージを追加するときは、そのライセンスの条件を確認する | <https://opensource.guide/legal/> |
| 設定と秘密情報 | 個人・組織固有の値（ホーム配下の絶対パス、社内ドメイン・URL、ID、認証情報）は環境変数か gitignore した `*.local.*` から読み、`*.example.*` をコミットする。いつ公開しても認証情報が漏れない状態を保つ | <https://12factor.net/config> |
| 履歴の秘密情報 | 秘密情報がコミットに入ったら、まず失効・ローテーションし、次に `git filter-repo` で履歴から除いてから切り出す | <https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/removing-sensitive-data-from-a-repository> |
| バージョン | Semantic Versioning で上げ、リリースごとに `v<version>` の git タグを打つ | <https://semver.org/> |
| 変更履歴 | `CHANGELOG.md` の `Unreleased` 節に、変更を `Added` / `Changed` / `Deprecated` / `Removed` / `Fixed` / `Security` で分類して積む | <https://keepachangelog.com/> |
| コミュニティ | 貢献方法の `CONTRIBUTING.md` と、脆弱性の報告窓口の `SECURITY.md` を置く。GitHub はこれらをルート・`.github/`・`docs/` から探す | <https://docs.github.com/en/communities/setting-up-your-project-for-healthy-contributions/creating-a-default-community-health-file> |
| 公開時の点検 | リポジトリを public にしたら、Insights > Community Standards（`https://github.com/<owner>/<repo>/community`）をブラウザで開く。`Not added yet` の項目ごとに、追加するか見送るかを理由付きで決め、全項目に判断がついたら完了とする。チェックリストは public リポジトリにだけ表示される | <https://docs.github.com/en/communities/setting-up-your-project-for-healthy-contributions/about-community-profiles-for-public-repositories> |
| テストと CI | テストをリポジトリ（親リポジトリ内で作る場合はそのディレクトリ）の中に置き、1 コマンドで実行できるようにする。push と PR でリンターとテストを回す GitHub Actions のワークフローを用意する。親リポジトリ内で作る場合は、切り出し前は親リポジトリのワークフローから同じコマンドを呼ぶ | <https://docs.github.com/en/actions/get-started/continuous-integration> |

## 根拠の提示

コードや設定の変更・新規作成・ツール選定・破壊的操作の前には、結果だけでなく根拠を示す。
ユーザーが判断・学習できるよう、以下の観点で **実行前のテキスト出力または end-of-turn summary に 1〜2 文程度** で簡潔に説明すること。

- 実装方針を選択した理由（例: 「X ではなく Y を使う理由は〜」）
- トレードオフがある場合はその比較
- 公式ドキュメントやベストプラクティスに基づく場合はその旨と出典（ライブラリ名・URL など）

ただし、以下のような自明な変更には理由の説明は不要：

- typo 修正・フォーマット整形
- 変数名のリネームなど意図が明白な変更
- ユーザーが指示した内容の単純な適用（ただし技術的に懸念がある場合は理由を添えて再確認）

ライブラリ・フレームワーク・API の仕様に基づいて実装や設定変更を行う際は、記憶に頼らず `context7` MCP（フォールバック: WebSearch / WebFetch）で最新の公式ドキュメントを参照し、その出典を根拠に含める。
リポジトリ内のドキュメント（README・`CONTEXT.md`・ADR）と既存のコードが食い違うときはコードの書き方に従い、見つけた食い違いを最後の返答ですべて挙げること。
