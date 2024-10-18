# python design decisions

- python script実装方針（design decisions）一覧
- レビュー時に参照するべき情報を集約する目的で用意
- Atlassianの"デザイン決定テンプレート"の簡易版・開発者間での参照用のような位置付け
  - <https://www.atlassian.com/ja/software/confluence/templates/design-decision>

## python(In Review)

- opinionated(json): python scriptを書く際にjsonデータやjsonファイルを扱う場合はpydanticで型を定義する
  - rationale: pydanticはエディターでの編集時にバリデーションも同時に行えるため
    - dataclass、dataclass-json、TypedDictなどの型定義方法ではエディターでの編集時にはエラーが出ず、実行時になってはじめてエラーが出るという事が起こり得る
- opinionated(linter):
  - 基本的にruffのlinerの"preview"に該当する設定も含め、すべて有効にする
  - pylintも併用する
  - その他のpython用のlinterは必要に応じて併用する
  - rationale:
    - linterは一度導入さえしてしまえば、その後のコードレビューの工数が恒久的に減る為、可能な限り導入する
    - 基本的にruffは多くの既存のpython用のlinterやそのpluginの内容を再現をしているが、すべてではない
      - そのため、ruffのlinterだけではカバーしきれない部分もカバーする為にオリジナルのlinterも一部併用していく
      - ただし、同じ目的で複数のlinterを実行するとその分実行時間がかかるため、バランスを考えて選定する
