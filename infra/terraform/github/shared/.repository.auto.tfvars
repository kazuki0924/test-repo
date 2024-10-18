# terraformは*.auto.tfvarsをファイル名のlexical orderで読み込むため、読み込みの順番をファイル名で制御する
# e.g. x-local.auto.tfvarsを作成し、ローカルからmain.auto.tfvarsの値を上書きする
# https://developer.hashicorp.com/terraform/language/values/variables#variable-definition-precedence
# repository = {
#   # Terraformでimportする前に手動で入力されたdescriptionがある場合はここに転機しないと上書きされてしまうので注意
#   # STUB: template repository適応後要変更
#   description = "repository description"
# }

repository = {
  enable_advanced_security = false
  visibility               = "public"
}
