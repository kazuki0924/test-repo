# YAML design decisions

- YAML実装方針（design decisions）一覧
- 目的：レビュー時に参照するべき情報の集約

## Style Guide

- opinionated(strings): 長い文字列は以下のようにYAML Multilineを使い分けて記述する
  - refs:
    - [YAML Multiline](https://yaml-multiline.info)
    - [YAML Spec v1.2.2 - 5.7 Escaped Characters](https://yaml.org/spec/1.2.2/#57-escaped-characters)
  - 途中で区切ってはならない1つの長い文字列を扱う場合: `\`でエスケープした改行で区切る
    - colon indicator(`:`)の後に改行する
    - `""`で区切らないとエスケープ出来ない点に留意

```yaml
# e.g.
role-to-assume:
  "arn:aws:iam::\
  ${{ inputs.AWS_ACCOUNT_ID }}:\
  role/${{ inputs.ASSUME_ROLE_PREFIX }}-\
  ${{ inputs.ASSUME_ROLE_RESOURCE_NAME }}"
```

- スペースで区切っても良い長い文字列（コマンドなど）を扱う場合: folded + strip(`>-`)で改行する

```yaml
# e.g.
run: >-
  git
  diff
  --name-only
  main
  feat/hoge
  --
  src
```yaml
