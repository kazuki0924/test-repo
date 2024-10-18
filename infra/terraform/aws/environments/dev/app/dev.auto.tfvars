# 各環境で共通となるtfvars
# 主にプロジェクト固有となる値を記述する
# 環境毎に異なる値は、各root moduleの{env}.auto.tfvarsで上書きする
# 以下の理由により、上書きされる側となるデフォルトの.auto.tfvarsファイル名は先頭に"."を付与する
# 上書きする側のファイル名には"."を付与しない
# terraformは*.auto.tfvarsをファイル名のlexical orderで読み込むため、読み込みの順番をファイル名で制御が出来る
# "."はlexical orderで最初の方に読み込まれるため、".*.auto.tfvars"に上書きされる対象の値を記述する
# これにより、terraform consoleでのデバッグ時や開発段階でのローカル実行時、各環境毎の値の上書きが可能となる
# e.g.
# - local.auto.tfvarsを作成し、ローカル実行時に*.auto.tfvarsの値を上書きする
# - prod.auto.tfvarsを作成し、prod環境用に値を上書きする
# https://developer.hashicorp.com/terraform/language/values/variables#variable-definition-precedence

# .app.auto.tfvarsの値の上書き
ecs = {
  # 値の上書きの動作確認用。デフォルト値からの上書きをしたい値が無い場合はこのdev.auto.tfvars自体不要
  cpu    = 512
  memory = 1024
}
