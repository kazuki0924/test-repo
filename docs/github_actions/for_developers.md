# GitHub Actions workflows TIPS

- 開発TIPS一覧
- 開発時に参照するべき情報を集約する目的で用意

## GitHub Actions workflow expressions

- `${{}}`の中でstringを使う場合、`""`で囲もうとするとエラーになる為、囲む場合は`''`にする必要がある
  - <https://docs.github.com/en/actions/writing-workflows/choosing-what-your-workflow-does/evaluate-expressions-in-workflows-and-actions#literals>
