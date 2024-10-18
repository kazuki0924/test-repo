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


# TODO: main-vpcの"stub-external-requester"を"aws_scheduler_schedule"で定期実行させ、VPCE経由でmisc-vpcの"stub-intra-api"へcurlでリクエストが送れる事を確認する

microservices_shared_resources = {
  ecs = {
    services = [
      {
        name_short   = "stub-intra-api"
        health_check = { path = "/health" }
      },
    ]
    schedules = [
      {
        name_short          = "stub-external-requester"
        schedule_expression = "cron(0/1 * * * ? *)"
      }
    ]
  }
  ecr = {
    repositories = [
      { name_short = "baseimage" },
      { name_short = "stub-intra-api" },
      { name_short = "stub-external-requester" }
    ]
  }
  cwlogs = {
    log_groups = [
      { name_short = "ecs-execute-command" },
      { name_short = "stub-intra-api" },
      { name_short = "stub-external-requester" }
    ]
  }
  alb = {
    target_groups = [
      {
        name_short   = "stub-intra-api"
        health_check = { path = "/health" }
      }
    ]
    listener_rules = [
      {
        name_short   = "stub-intra-api"
        path_pattern = "/dummy_endpoint"
      }
    ]
  }
}

per_microservice_resources = null
