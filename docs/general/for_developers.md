# General TIPS

- 開発TIPS一覧
- 開発時に参照するべき情報を集約する目的で用意

## GitHub Code Advanced Search

- GitHub Code Advanced Searchを使う事でpublic repositoryにおける実装例や設定ファイルの例が検索できる
  - <https://github.com/search/advanced>

## AIによるツールのconfigファイル生成

- 以下の様なpromptでデフォルト値かつコメントで説明を付与したconfigファイルを生成した上で編集すると便利
- 例: ruff.tomlの生成

``` text
given the following info,
can you write me a full ruff.toml with all the defaults and comments explaining what each field does?

（https://docs.astral.sh/ruff/settings/から内容を丸々コピー）
```
