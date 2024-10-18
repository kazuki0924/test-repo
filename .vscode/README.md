# .vscode

### 実装メモ
- Project Level Snippets: https://code.visualstudio.com/updates/v1_28#_project-level-snippets
  - `.vscode`ディレクトリ内の`*.code-snippets`ファイルをスニペットとして読み込んでくれる
  - サブディレクトリまでは読みには行ってくれない模様
- 有志作成のスニペット集があるのでそこからbashスクリプトで動的に取得する
  - Friendly Snippets: https://github.com/rafamadriz/friendly-snippets
  - vim/neovimなどではプラグインとしてインストール可能だが、VSCodeでは自力で.code-snippetsファイル化する必要がある模様