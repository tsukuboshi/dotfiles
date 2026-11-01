---
name: "prepare-oss"
description: "Prepare a repository, or a plugin directory inside one, for publishing as OSS: audit it, add the missing community files (README, LICENSE, CHANGELOG, CONTRIBUTING, SECURITY, CI) and move personal or organization-specific values out of the code (Target Default: current repository root). Use this skill whenever the user wants to open-source, publish or split out a repo or directory — e.g. 'OSS 化して', 'OSS として公開する準備をして', 'public にする前に点検して', 'open-source this repo', 'subtree で切り出せるようにして'."
argument-hint: "[Target Path]"
---

指定された対象を調査し、OSS として公開できる状態に整えてください。
公開そのもの（push、public 化、タグ打ち、履歴の書き換え）はユーザーに残し、その手前までを行います。

# 1. 対象とモードを決める

`ARGUMENT` は 1 つの引数を受け取ります。

- 第一引数: 対象のパス（未指定時は今のディレクトリ）

```bash
target=$(cd "TARGET_PATH" && pwd -P)
root=$(git -C "$target" rev-parse --show-toplevel)
git -C "$root" remote get-url origin
```

`$target` が git リポジトリの中に無ければ、`git init` してから進めるかを `AskUserQuestion` で確認します。
`$target` と `$root` が一致すれば **単体モード**、`$root` の配下なら **切り出しモード** として扱います。
切り出しモードでは、`$target` を将来のリポジトリルートとみなします。
`git subtree split -P <dir>` は、そのディレクトリに触れたコミットだけを、ディレクトリ直下をルートにした履歴として取り出すためです（出典: `git help subtree`）。

公開先の owner / repo は、単体モードなら `origin` の URL から取ります。
切り出しモードの `origin` は親リポジトリなので、公開先は「判断を仰ぐ」でユーザーに聞きます。
`origin` が無いときも同じく聞きます。

続けて、`$target` 直下のマニフェスト（`package.json`・`pyproject.toml`・`Cargo.toml`・`go.mod`・`.claude-plugin/plugin.json` など）とタスクランナー（`Makefile`・`mise.toml`・`justfile` など）を読み、インストール・テスト・リントをそれぞれ 1 コマンドで実行する方法を探します。
ツール固有のレイアウトやマニフェストの書き方は、そのツールの公式ドキュメントを `context7` MCP（フォールバック: WebSearch / WebFetch）で確かめます。

モード、将来のルート、公開先の owner / repo（未定なら「要判断」）、インストール・テスト・リントのコマンド（無ければ「無し」）が確定したら次へ進みます。

# 2. 調査する

下表の全行を、ファイルを変更する前に判定します。
「現状」は有り / 無し / 要修正、「対応」は作成 / 修正 / 対応不要 / 要判断 のいずれかです。

| 項目 | 満たす状態 | 出典 |
| --- | --- | --- |
| README | 英語の `README.md` に、何をするか・なぜ有用か・始め方・助けを得る場所・メンテナがある。日本語の補足は `README.ja.md` にある | <https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/about-readmes> |
| ライセンス | `LICENSE` があり、マニフェストの `license` がその SPDX 識別子（既定は `MIT`）。直接依存のライセンスが、そのライセンスでの配布と両立する | <https://opensource.guide/legal/> |
| 設定と秘密情報 | 個人・組織固有の値（ホーム配下の絶対パス、社内ドメイン・URL、ID、認証情報）を環境変数か gitignore した `*.local.*` から読み、`*.example.*` をコミットしている | <https://12factor.net/config> |
| 履歴の秘密情報 | 対象の履歴に、秘密情報・固有値・組織のメールアドレスが無い | <https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/removing-sensitive-data-from-a-repository> |
| バージョン | Semantic Versioning のバージョンをマニフェストに持つ | <https://semver.org/> |
| 変更履歴 | `CHANGELOG.md` に `Unreleased` 節があり、変更を `Added` / `Changed` / `Deprecated` / `Removed` / `Fixed` / `Security` で分類して積む | <https://keepachangelog.com/> |
| コミュニティ | 貢献方法の `CONTRIBUTING.md` と、脆弱性の報告窓口の `SECURITY.md` がある。GitHub はこれらをルート・`.github/`・`docs/` から探す | <https://docs.github.com/en/communities/setting-up-your-project-for-healthy-contributions/creating-a-default-community-health-file> |
| テストと CI | テストが対象の中にあり 1 コマンドで実行できる。push と PR でリントとテストを回す GitHub Actions のワークフローがある | <https://docs.github.com/en/actions/get-started/continuous-integration> |
| 構成（切り出しモードのみ） | 対象内の参照が、対象内に閉じた相対パスで書かれている | `git help subtree` |
| コミット（切り出しモードのみ） | 対象に触れるコミットが、メッセージ単独で意味が通る。split は対象外の差分を落とすが、メッセージはそのまま残す | `git help subtree` |

直接依存のライセンスは、ロックファイルかマニフェストに並ぶ依存ごとに、そのパッケージのマニフェストかレジストリのページで確かめます。

## 秘密情報と固有値の検出

検出した値は、会話にもファイルにも書き出さず、場所（ファイル・行・コミット）と種類だけで扱います。
値の隣に認証情報が並んでいることが多く、一覧に値を載せるとそのまま漏れるためです。

gitleaks は `--redact` で値を伏せ、`-v` でファイル・行・コミット・ルール ID を出します。
`--ignore-gitleaks-allow` で、対象のコード内の `gitleaks:allow` コメントによる除外を無効にします。

```bash
gitleaks dir -v --redact --ignore-gitleaks-allow --no-banner --no-color "$target"
gitleaks git -v --redact --ignore-gitleaks-allow --no-banner --no-color "$root"
```

切り出しモードの履歴は、`--log-opts="--all --full-history -- <$root からの相対パス>"` で対象に絞ります。
`--log-opts` を渡すと gitleaks 既定の `--all` が外れ、今のブランチから辿れないコミットを見落とすため、`--all --full-history` を必ず残します。
gitleaks は `--log-opts` を空白で区切るため、相対パスに空白が含まれるときは絞り込まずに `$root` 全体を走査し、対象の外の検出を読み捨てます。

対象に `.gitleaks.toml` か `.gitleaksignore` があれば、その除外内容を調査の表と一緒にユーザーへ示します。
除外は公開前の検出も黙らせるため、足すか外すかはユーザーが決めます。

ホーム配下の絶対パスは、dotfiles の ast-grep ルールを 1 本ずつ `-r` で当てて検出します。
共有の `sgconfig.yml` には、この対象と関係の無い dotfiles 専用のルールも入っているため使いません。

```bash
for lang in bash python yaml; do
	ast-grep scan -r ~/dotfiles/genai/lint/ast-grep/rules/$lang/no-hardcoded-home-path.yml "$target"
done
```

ast-grep が読まない形式（Markdown・JSON・TOML など）と組織固有の値は、`Grep` を `output_mode: "files_with_matches"` か `"count"` で使って場所だけ拾います。
探すのは `/Users/<名前>/`・`/home/<名前>/`、`git config user.email` のドメイン、社内向けの URL・ホスト名、AWS アカウント ID などの 12 桁の数字、Slack・Asana などのワークスペース ID です。
同じパターンを履歴にも当て、値を含むコミットとファイル名だけを出します。

```bash
git -C "$root" log --all -G'<パターン>' --format='%h' --name-only -- "$target"
git -C "$root" log --all --format='%an <%ae>%n%cn <%ce>' -- "$target" | sort -u
```

2 つ目のコマンドは、コミットの作者とコミッターの一覧です。
`git subtree split` もこの情報をそのまま残すため、組織のメールアドレスがあれば候補に入れます。

## 切り出しモードの追加調査

- `../` で対象の外へ出る参照と、`$root` を絶対パスで指す参照を `Grep` で探す
- テストとフィクスチャが対象の中にあるかを確かめる
- 親リポジトリの `.github/workflows/` が、対象のテストコマンドを呼んでいるかを確かめる
- 対象の外のファイルも一緒に変えたコミットを、次のコマンドで探す。`--full-diff` が無いと、パスで絞った外側のファイルが一覧から消える

```bash
git -C "$root" log --full-diff --name-only --format='%h %s' -- "$target"
```

## 調査結果を示す

表の全行に現状と対応が付いたら、表と検出した場所の一覧をユーザーに示します。
履歴に秘密情報・固有値・組織のメールアドレスがあれば、表より先にそれを伝え、漏れた認証情報の失効と差し替えを最初に行うよう促します。
履歴を書き換える手順は「7. 履歴の書き換えを案内する」で示します。

# 3. 判断を仰ぐ

対応が「要判断」の項目を、`AskUserQuestion` で 1 つずつ確認します。
論点ごとに答えを受け取ってから、次の論点に進みます。

- 公開先の owner / repo: 切り出しモードか、`origin` が無いとき
- README の「何をするか・なぜ有用か」: コードとコミット履歴から書いた 1〜2 文の案を選択肢に出す
- 著作権者: `git config user.name` と、所属組織の名前を選択肢に出す
- マニフェストに MIT 以外のライセンスが宣言済み: そのライセンスを維持するか、MIT にするか
- 両立しない直接依存のライセンス: 依存を置き換えるか、プロジェクトのライセンスを合わせるか
- マニフェストにバージョンが無い: 最初のバージョン（`0.1.0` か `1.0.0` か）
- 脆弱性の報告窓口: GitHub の Private vulnerability reporting か、メールアドレスか
- 固有値の扱い: 場所ごとに、環境変数にするか・`*.local.*` へ移すか・削るか
- テストコマンドが無い: 用意するテストフレームワーク

「要判断」の項目すべてに答えが揃ったら次へ進みます。

# 4. ファイルを作る・直す

対応が「作成」の項目は、対象の直下にファイルを作ります。
対応が「修正」の項目は、既存のファイルに、表の「満たす状態」に足りない部分だけを足します。

- `README.md` と `README.ja.md`: 表の README の行の 5 項目を見出しにする。始め方には、「1. 対象とモードを決める」で確定したインストールとテストのコマンドを書く
- `LICENSE`: 決まったライセンスの SPDX 本文（MIT なら <https://spdx.org/licenses/MIT.html>）に、今年の年と著作権者を入れる。マニフェストの `license` をその SPDX 識別子にする
- バージョン: マニフェストに無ければ、決まった最初のバージョンを書く
- `CHANGELOG.md`: Keep a Changelog 形式で、`Unreleased` 節の下に 6 分類の見出しを置く。マニフェストにバージョンがあれば、その版の節も作る
- `CONTRIBUTING.md`: 開発環境の用意、テストとリントの 1 コマンド、Issue と PR の流れ
- `SECURITY.md`: サポートするバージョンと、決まった報告窓口
- `.github/workflows/ci.yml`: トリガーは `push` と `pull_request` にし、リントとテストを実行する。`permissions: contents: read` を宣言し、`actions/checkout` には `persist-credentials: false` を渡す。actions はコミット SHA で固定し、コメントにバージョンを添える。SHA は `git ls-remote https://github.com/<owner>/<action> 'refs/tags/<vX.Y.Z>*'` で、そのアクション自身のリポジトリから取る（注釈付きタグは `^{}` の行の SHA）
- `.gitignore` と `*.example.*`: 環境変数か `*.local.*` に移す値があるとき、先に `.gitignore` へ `*.local.*` を足してから、プレースホルダーだけを書いた例示ファイルを作る。作った例示ファイルにも gitleaks を当て、検出ゼロを確かめる

切り出しモードでは、`.github/workflows/ci.yml` も対象の中に置きます。
GitHub が読むのはリポジトリルートの `.github/workflows/` だけなので、このワークフローは切り出した後に初めて動きます。
切り出すまでは、親リポジトリのワークフローに、対象のテストとリントのコマンドを呼ぶ step を足して同じ検査を回します。

表の「作成」と「修正」の行すべてに対応が済んだら次へ進みます。

# 5. リファクタリングする

リファクタリングで編集するのは、git が追跡しているファイル（`git ls-files` に出るもの）だけです。
`.env` など未追跡・gitignore 済みのファイルは、git で戻せない唯一の控えのことが多いため、検出があっても触らず、場所を最後の報告に載せます。

機械的な置き換えは、そのまま適用します。

- ホーム配下の絶対パス: `$HOME/...`・`~/...`・`Path.home()` など、その言語でホームを指す書き方にする
- 固有値: 決まったとおり、環境変数か `*.local.*` から読む形にする。読めないときのエラーメッセージに、`*.example.*` の場所を書く
- 対象の外への参照（切り出しモード）: 対象内のファイルを相対パスで指す形にする。対象の外にしか無いものは、対象内へ移すか依存として宣言するかを `AskUserQuestion` で確認する

置き換えたら、確定したリントとテストのコマンドを実行します。
gitleaks・ast-grep・`Grep` をもう一度実行し、追跡しているファイルの検出がゼロになったら次へ進みます。
ゼロにできない検出（テストのフィクスチャなど）は、除外設定を足さずに、場所と理由を添えてユーザーに判断を委ねます。

# 6. 公開後の点検を案内する

公開先が GitHub なら、`https://github.com/<owner>/<repo>` を認証なしで取得して公開状態を確かめます。

```bash
curl -s -o /dev/null -w '%{http_code}\n' https://github.com/<owner>/<repo>
```

`200` なら public です。
このときは `read-issue` スキルの「ブラウザツールの準備」と同じ手順でタブを用意し、Claude in Chrome で `https://github.com/<owner>/<repo>/community` を開きます。
`Not added yet` の項目ごとに、追加するか見送るかを理由付きで決め、追加するものは「4. ファイルを作る・直す」に戻って作ります。
このチェックリストは public リポジトリにだけ表示されます（出典: <https://docs.github.com/en/communities/setting-up-your-project-for-healthy-contributions/about-community-profiles-for-public-repositories>）。

`404` なら private かまだ無いので、この点検を最後の報告の「ユーザーに残した作業」に載せます。

# 7. 履歴の書き換えを案内する

調査で履歴に秘密情報・固有値・組織のメールアドレスが見つかったときだけ行います。
履歴の書き換えはやり直しが効かず、公開済みのクローンやフォークからは消せないため、実行はユーザーに委ね、次の順の手順を示します（出典: 表の履歴の秘密情報の行、<https://github.com/newren/git-filter-repo/blob/main/Documentation/git-filter-repo.txt>）。

1. 漏れた認証情報があれば失効させ、新しい値に差し替える
2. `git filter-repo` で履歴を書き換える。ファイルの中の値は `--replace-text <式ファイル>`、作者・コミッターの名前とメールアドレスは `--mailmap <mailmap ファイル>` で置き換える
3. 書き換えた後の履歴で「2. 調査する」の検出をもう一度実行し、ゼロを確かめてから公開または切り出しを行う

# 8. 結果を伝える

次の 5 つを伝えます。

- 作成・修正したファイル
- リファクタリングした箇所と、置き換え後の値の読み方
- 対応不要とした表の行と、その理由
- ユーザーに残した作業: 認証情報の失効と履歴の書き換え、触らなかった未追跡ファイルの検出、ユーザーに委ねた検出、public 化と Community Standards の点検、最初の `v<version>` タグ、切り出しモードなら次のコマンド
- 今後の運用: 下の一覧

```bash
git subtree split -P <$root からの相対パス> -b <split 用ブランチ名>
```

今後の運用として、次の 4 つを添えます。
いつ公開しても認証情報が漏れない状態を保つためです。

- 個人・組織固有の値は、書くときから環境変数か `*.local.*` に置く
- 依存パッケージを追加するときに、そのライセンスの条件を確かめる
- リリースごとに Semantic Versioning でバージョンを上げ、`CHANGELOG.md` の `Unreleased` 節を版の節に移して `v<version>` タグを打つ
- 切り出しモードなら、1 プラグイン = 1 ディレクトリを保ち、対象の中の変更はメッセージ単独で意味が通るコミットにまとめる。表のコミットの行で見つかったコミットも、ここで一覧にする
