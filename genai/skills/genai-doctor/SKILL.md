---
name: genai-doctor
description: "Tune the entire ~/dotfiles/genai configuration (settings.json, AGENTS.md, rules, skills, hooks, permissions) by cross-checking the latest official Claude Code documentation and analyzing recent conversation history for recurring request patterns. Use when the user wants to audit, check, or tune their Claude Code setup as a whole — e.g. 'genai をチューニング', '設定を最新化', '設定の棚卸し', 'settings.json をチェック', '会話履歴から改善点を探して', 'スキルを提案して'. For a single targeted settings change (e.g. adding one permission or env var), use update-config instead."
argument-hint: "[days]"
---

# 引数の解決

引数 `days`: 会話履歴分析の対象期間（日数）。省略時は 30 日とする。

`~/dotfiles/genai` 配下の Claude Code 設定一式を、最新の公式ドキュメントとの突き合わせ、および会話履歴の分析に基づいて診断し、チューニング提案を行ってください。

# Step 1: ハーネス診断の委譲

ハーネス自体の健全性は Claude Code の組み込み診断が担当し、このスキルは `~/dotfiles/genai` の設定内容を担当する。以下の診断結果を Step 5 の材料として先に揃える。

| 診断 | 起動方法 | 担当範囲 | 受け取る入力 |
| --- | --- | --- | --- |
| `/doctor` | ユーザーに実行と結果の共有を依頼する | インストール健全性・バージョン・設定ファイルの構文・スキルとエージェント定義の妥当性・未使用のプラグイン / MCP サーバー・フック実行時間の実測 | フックの実測時間 / 未使用のプラグインと MCP サーバー |
| `/skill-doctor` | ユーザーに実行と `/plugin` の Stats タブの共有を依頼する | スキルごとの使用実績とコンテキストコストの実測 | 未使用スキルの一覧 / スキル別の実測トークン量 |
| `/fewer-permission-prompts` | `Skill` tool で起動する（`skill: "fewer-permission-prompts"`） | 拒否されたツール呼び出しから、読み取り専用コマンドの allow 候補をプロジェクトの `.claude/settings.json` へ追加 | 追加された allow ルール / 見送りとその理由 |

`/doctor` と `/skill-doctor` は組み込みの CLI コマンドであり、起動はユーザーの手に委ねられている。冒頭で実行を依頼し、ユーザーが会話に貼った出力を診断材料として使う。同一セッションで実行済みならその結果を使う。

ユーザーが実行を見送った診断がある場合は、その入力に依存する Step 5 の行を「入力なし」として扱い、推測で補わずレポートにその旨を明記する。

これらは設定ファイルを書き換えることがあるため、必ず Step 2 より先に実行する。逆順にすると Step 2 が読み込んだ構成が古くなる。

# Step 2: 現状把握

`~/dotfiles/genai` 配下の構成を読み込んでください。

1. `settings.json` と、そこから参照されている関連ファイル
   - `statusLine.command` が指すスクリプト（例: `scripts/statusline.sh`）
   - `hooks` の各エントリが指すスクリプト（例: `hooks/*.sh`）
2. `rules/*.md`（全ルールファイル）
3. `skills/*/SKILL.md`（この時点では frontmatter の name と description のみ。Step 5 で改善候補に挙がったスキルに限り本文を読む。全スキルの本文を読むとコンテキストが溢れる）
4. `apm/apm.yml`（外部スキルの導入状況）
5. `AGENTS.md`（エージェント共通指示）

読み込みを終えたら、続く Step 3 と Step 4 は互いに独立しているため、両方のエージェントを**同一ターンで並列起動**してください（逐次実行すると数分余計にかかる）。

# Step 3: 公式ドキュメントの取得

`claude-code-guide` エージェントに以下を問い合わせ、最新仕様を取得してください。

- settings.json で有効な全設定キーとその型・デフォルト値
- `env` で有効な環境変数の一覧（廃止されたものがあればその情報も）
- `permissions` / `hooks` / `statusLine` の最新仕様
- 最近追加された推奨設定項目

エージェントが利用できない場合のフォールバックとして、WebFetch で以下の公式ドキュメントを直接参照してください。

- <https://code.claude.com/docs/en/settings>
- <https://code.claude.com/docs/en/hooks>（hooks を使用している場合）
- <https://code.claude.com/docs/en/statusline>（statusLine を使用している場合）

# Step 4: 会話履歴の分析

`~/.claude/projects/*/` 配下の JSONL トランスクリプトから、指定期間内のユーザー依頼パターンを抽出してください。

分析手順:

1. `find ~/.claude/projects -name "*.jsonl" -mtime -<days>` で対象ファイルを特定する
2. プロジェクト群を 2〜3 系統に分け、Explore サブエージェントを並列起動して分析を委譲する
3. 各エージェントには抽出方法を指示する
   - ユーザー発話: `jq -r 'select(.type=="user") | .message.content // empty | if type=="string" then . else (map(select(.type=="text") | .text) | join(" ")) end'`（`.message` を持たない summary 行を `// empty` で読み飛ばす）
   - `tool_use_id` を含む行（tool_result）はスキップ
   - JSONL は 1 ファイルで数 MB になり得るため、1 ファイルあたり冒頭のユーザーメッセージ数件をサンプリングする（セッションの目的把握には十分で、サブエージェントのコンテキスト溢れを防ぐ）
4. 以下を報告させる。いずれも設定に「足りないもの」を見つけるための材料で、使用頻度の集計は Step 1 の `/skill-doctor` が担当する
   - 繰り返し登場する依頼パターン（3 回以上）
   - 毎回手動で指示している定型作業・方針
   - スキル発火後にユーザーが言い直し・訂正しているケース（スキル本文・description の改善候補の材料にする）

# Step 5: 診断レポート

Step 2〜4 の結果を突き合わせ、以下の観点で表形式のレポートを提示してください。

| 観点 | 診断内容 |
| --- | --- |
| settings | 廃止・無効なキー / デフォルト値と同一の冗長なキー / 未導入の推奨設定 |
| permissions | 履歴に登場しない allow エントリ（削除候補）/ `/fewer-permission-prompts` がプロジェクトの `.claude/settings.json` に追加した allow のうち、複数プロジェクトで使うため genai の settings.json へ昇格すべきもの |
| rules | 毎回口頭で指示している方針（rules/*.md への追記候補）/ 履歴と矛盾する既存ルール |
| skills | 繰り返し依頼パターンから導く新スキル候補（自作の前に `find-skills` スキルに委譲して既存の公開スキルで代替できないか確認する）/ Step 4 で言い直しが観測されたスキルに限り `SKILL.md` 本文を読み、description の発火精度・手順の改善を提案する |
| hooks | settings.json の hooks 登録と `hooks/*.sh` の実体の不整合 / `post-edit-fmt.sh` の対応拡張子と `rules/*.md` のリンタ・フォーマッタ定義のずれ / 最新 hooks 仕様（新イベント・matcher）の活用余地。実行時間とエラーは Step 1 の `/doctor` の実測値を使う |
| AGENTS.md | `rules/` へのリンク切れ・参照漏れ / 履歴上毎回口頭で指示している方針のうちエージェント共通指示へ昇格すべきもの / rules との内容重複 |
| apm | Step 1 の `/skill-doctor` が未使用と判定したスキルのうち `apm.yml` の dependencies にあるもの（削除候補） |

診断時の注意:

- 仕様の確認が取れないキーは「要確認」として、参照した出典（ドキュメント URL）とともに提示する
- 確証が取れた指摘だけを報告する（有効に機能している設定を問題ありと誤報するより、偽陽性の回避を優先する）
- 各指摘には根拠（公式ドキュメントの記述、または履歴上の頻度）を添える
- 設定変更の根拠にする項目は、出典 URL の記述を WebFetch で裏取りしてから提案する（サブエージェントが有効なキーに誤った説明を付けるケースが実際にある）
- 新スキルを提案する前に、同等の機能を持つ公開スキルの有無を確認する。候補ごとに `find-skills` スキル（`Skill` tool, `skill: "find-skills"`, `args: "<検索クエリ>"`）を呼び出して skills.sh エコシステムを検索する。見つかった場合は自作ではなく導入を提案する（インストール手順は Step 6 の既存フローに従う）

# Step 6: 提案と適用

1. 診断結果に基づく変更案を、変更理由付きで優先度順に提示する。対象は `settings.json` ・`hooks/*.sh`・`AGENTS.md`・`rules/*.md`・既存の `skills/*/SKILL.md`・`apm/apm.yml` を含む
2. ユーザーが選択した項目のみ適用する
3. キーの削除・ルールの変更・hooks スクリプトの挙動変更・`apm.yml` の dependencies からの削除など既存動作に影響する変更は、項目ごとに個別確認を挟む
4. 新スキルの作成や既存スキルの大幅な書き換えなど規模の大きい提案は、plan mode での別途着手を提案してこのスキルの範囲を終える（description の修正のような小さな変更はこのスキル内で適用してよい）。既存の公開スキルで代替する場合は `apm/apm.yml` の dependencies に追記して `apm install -g`（または `genai/setup.sh -i`）の実行を提案する
5. 適用後、変更内容のサマリ（変更前 → 変更後）を報告し、`genai/setup.sh` の再実行が必要な場合はその旨を案内する
