# General Design Decisions

- 実装方針（design decisions）一覧
- レビュー時に参照するべき情報を集約する目的で用意
- Atlassianの"デザイン決定テンプレート"の簡易版・開発者間での参照用のような位置付け
  - <https://www.atlassian.com/ja/software/confluence/templates/design-decision>

## docs(In Review)

- opinionated: ドキュメントはmarkdown形式で書き、git管理する
  - rationale: エディター（VS Codeなど）やgitを活用した自動化を容易にするため

## comments(In Review)

- opinionated: 実装する際に参照した公式ドキュメントのリンクは可能な限りコメントに記載する
  - rationale: レビュアーへの配慮、自己レビュー時の再確認用

``` bash
# e.g.
# ref: https://google.github.io/styleguide/shellguide.html
```

- opinionated: コメントはプログラミング言語/コンフィグ言語からの指定がない限り（yaml内のコメント等）生のmarkdownの記載方式に近い形にする
  - rationale: markdownからコピペ、またはその逆ができるため

``` text
# - comment1
#   - comment2
#   - comment3
```

## tools(In Review)

- 使用するツールのバージョンはCI/CDやdevcontainersでの指定とで一元管理（常に同期）を目指す為に別ファイルで管理する
  - バージョン情報は`.env.tool-versions`ファイルに記載し、`source .env.tool-versions`などの方法で読み込むようにする
- 各種ツールの設定ファイルには以下の情報をコメントで記載する
  - 設定時のツールのバージョン
  - 公式ドキュメントの設定のページへのリンク
  - （任意）元のデフォルト値をコメントで記載
  - （任意）参考にしたGitHubリポジトリがあればリンクを記載
  - （任意）GitHub Code Advanced Searchでの検索で比較した例があれば検索条件を記載
  - rationale: ツールのバージョンアップ時に設定の変更点を把握しやすくする為
- json, yaml, tomlの設定ファイルはJSON Schemaが有効になるように設定する
  - VS Codeの拡張によって自動的に適応される場合とコメントで記載する事ではじめてエディターの拡張機能が認識してくれる場合がある事に留意
  - rationale: バージョンアップの際に名前変更になった項目を検知しやすくする為

## Naming Conventions(In Review)

- GitHub Actionsの略称として以下は避ける
  - `gha`、`gh-a` GitHub Appsと混同してしまうため
  - `ghas` GitHub Advanced Securityと混同してしまうため
  - `gh-actions` ghの部分がGitHub CLIと混同してしまうため
- 命名でGitHub Actionsを指す場合は以下で統一する
  - GitHub Actions workflows: `github-actions`、`github_actions`
    - rationale: 以下のような著名なGitHub Actions関連OSSポジトリのGitHub Topicsに`github-actions`が使われているため
      - <https://github.com/nektos/act>
  - GitHub Actions composite actions: `actions.yml`
