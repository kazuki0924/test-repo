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

dynamodb = [
  {
    name_short = "EVSE-MASTER"
    hash_key   = "chargerId"
    attributes = [
      {
        name = "chargerId"
        type = "S"
      }
    ]
  },
  {
    name_short = "CHARGING-STATUS-HISTORY"
    hash_key   = "chargerId"
    range_key  = "createTimestamp"
    attributes = [
      {
        name = "chargerId"
        type = "S"
      },
      {
        name = "createTimestamp"
        type = "S"
      }
    ]
  },
  {
    name_short = "CHARGING-STATUS-LATEST"
    hash_key   = "chargerId"
    attributes = [
      {
        name = "chargerId"
        type = "S"
      },
      {
        name = "chargingReadyInt"
        type = "N"
      }
    ],
    global_secondary_index = [
      {
        name            = "GSI-XEV-CHRDYINT"
        hash_key        = "chargingReadyInt"
        projection_type = "ALL"
      }
    ]
  }
]
