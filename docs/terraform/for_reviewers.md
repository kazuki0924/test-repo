# terraform design decisions

- terraform/terragrunt実装方針（design decisions）一覧
- レビュー時に参照するべき情報を集約する目的で用意
- Atlassianの"デザイン決定テンプレート"の簡易版・開発者間での参照用のような位置付け
  - <https://www.atlassian.com/ja/software/confluence/templates/design-decision>

## terraform(In Review)

- convention(built_in_functions): `templatefile()`関数で使うファイルの拡張子は`*.tftpl`にする
  - <https://developer.hashicorp.com/terraform/language/functions/templatefile>
- opinionated(directory_structure): `file()`関数使うファイルは`/file`ディレクトリ、`templatefile()`関数で使うファイルは`/templatefile`ディレクトリに配置する
  - ファイルが増えたら用途によってからにディレクトリ分けをする事を検討する
  - rationale: 通常のファイル（terraform以外からも利用）か、terraformでしか使わないファイルかを明示的にする為
- opinionated(syntax): 三項演算子はその行がよほど短くない限りは基本的に`()`で囲って改行する
- opinionated(variables): `locals.tf`、`variables.tf`は複数の`.tf`ファイルで

``` terraform
# e.g.
something {
  something = (
    local.is_something ?
    "${local.something_very_long}" :
    "${local.something_else_very_long}"
  )
  ...
}
```

- opinionated(ref): resource定義と一緒にそのドキュメントのリンクを貼る
  - rationale:
    - terraformのレビュー観点に"tagsが指定可能なのに指定されていない"というのがある
    - レビュアーがそれぞれのresourceのドキュメントのリンク先をいちいち調べなくても良いようにする為

``` terraform

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_openid_connect_provider
resource "aws_iam_openid_connect_provider" "main" {
  ...
}
```

- opinionated(env, locals): ID、ARNなどのID系を除く、環境差分のあるパラメーターはresourceを定義するファイルのlocalsで各環境の設定値を書く
  - rationale: プロジェクトAからterraformコードを流用してプロジェクトBを構築する際、レビューをする際などに各環境毎の差分がそれぞれ別ファイルに書かれていると見つけるのが手間である為
  - 参照する際は`lookup()`関数を使い、デフォルト値を明示的にする
    - レビューの際に通常であればただ参照しているだけだとどのような値が入るのかがいまいち分からないところ、この方法であればパッと見で分かりやすくなる

``` terraform
locals {
  ecr = {
    ...
    force_delete = {
      dev  = true
      test = false
      stg  = false
      prod = false
    }
    ...
  }
}

resource "aws_ecr_repository" "main" {
  ...
  force_delete         = lookup(local.ecr.force_delete, local.common.env, false)
  ...
}
```

- opinionated(for_each): 極力、繰り返し作成するリソース数が3以上の場合にのみ`for_each, count`を使う
  - 言い換えると、2以下の場合は個別にresourceを定義する
  - rationale: for_eachはDRYになる反面、可読性が損なわれるため
- suggestion(modules): nested modulesを作る時/レビューする時は公式ドキュメントの関連ページを改めて一読する
  - <https://developer.hashicorp.com/terraform/language/style#module-structure>
  - <https://developer.hashicorp.com/terraform/language/modules/develop/structure>
  - <https://developer.hashicorp.com/terraform/tutorials/modules/pattern-module-creation>
  - rationale: 他の実装がそうしているからという理由でnested modulesを作るのではなく、必要性を理解した上でnested modulesとなる事が望ましい

## terragrunt(In Review)

- opinionated: terragruntで使う`.hcl`ファイルは`_terragrunt.hcl`をsuffixにする
  - rationale: hclには`docker-bake.hcl`などのterragrunt以外のhclがあり得る。terragrunt固有のsyntaxを使う場合はterragrunt用のファイルである事を明示的にする為
