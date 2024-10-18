variable "common" {
  description = "全リソース共通で扱う値を入れるオブジェクト"
  sensitive   = false
  nullable    = true

  type = object({
    # システム名
    system = optional(string, "xev-vpp")
    # サブシステム名
    subsystem = optional(string, "evems")
    # 環境名
    env = optional(string, "dev")
    # Terraform Provider
    provider = optional(string, "aws")
    # モジュール名
    module = optional(string, "app")
    # ドメイン名
    domain = optional(string, "fleet-control")
    # サブドメイン名
    subdomain = optional(string, null) # マイクロサービス共通リソースの場合はnull
    # マイクロサービス名
    microservice = optional(string, null) # マイクロサービス共通リソースの場合はnull
    # 各種リソース名の先頭に付与する文字列
    prefix = optional(string, "xev-vpp-evems-dev-")
    # 各種リソース名の末尾に付与する文字列
    suffix = optional(string, "") # terraform test時には"-delete-me"
    # リポジトリのルートパス
    repo_root = optional(string, "/home/devcontainer/workspace")

    # 各種リソース共通で扱うGitHub関連の値
    github = optional(object({
      org  = optional(string, "wcm-eas")
      repo = optional(string, "xev-vpp-evems-fleet-control")
      # 開発期間中か後かで設定を切り替える為のフラグに使用
      # - 基本的に開発期間中はアジリティを優先した設定にする
      # - 開発期間後（初回リリース以降、等）はセキュリティやチームコラボレーションを優先した設定にする
      phase = optional(string, "IN_ACTIVE_DEVELOPMENT")
    }), {})

    # 各種リソース共通で扱うAWS関連の値
    aws = optional(object({
      region           = optional(string, "ap-northeast-1")
      secondary_region = optional(string, "us-east-1")
      default_tags = optional(object({
        managed_by = optional(string, "terraform")
        wrapped_by = optional(string, "terragrunt")
        # timestamp()の値をterragruntから渡す
        created_at = optional(string)
        # formatdate("YYYY-MM-DD", timestamp())の値をterragruntから渡す
        created_date = optional(string)
        system       = optional(string, "xev-vpp")
        subsystem    = optional(string, "evems")
        env          = optional(string, "dev")
        domain       = optional(string, "fleet-control")
        subdomain    = optional(string, null) # マイクロサービス共通リソースの場合はnull
        microservice = optional(string, null) # マイクロサービス共通リソースの場合はnull
        owner        = optional(string, "wcm-eas")
        repo         = optional(string, "xev-vpp-evems-fleet-control")
      }), {})
    }), {})

    # 各種リソース共通で扱うアプリケーションのデフォルト値
    app = optional(object({
      default = optional(object({
        port = optional(number, 8000)
        health_check = optional(object({
          protocol            = optional(string, "HTTPS")
          path                = optional(string, "/health")
          matcher             = optional(string, "200")
          interval            = optional(number, 30)
          timeout             = optional(number, 20)
          retries             = optional(number, 3)
          start_period        = optional(number, 60)
          healthy_threshold   = optional(number, 3)
          unhealthy_threshold = optional(number, 3)
        }), {})
      }), {})
    }), {})

    # 各種リソース共通で扱うterraformのデフォルト値
    terraform = optional(object({
      timeouts = optional(object({
        dev = optional(object({
          create = optional(string, "10m")
          update = optional(string, "20m")
          delete = optional(string, "5m")
        }), {})
        test = optional(object({
          create = optional(string, "30m")
          update = optional(string, "60m")
          delete = optional(string, "10m")
        }), {})
        stg = optional(object({
          create = optional(string, "60m")
          update = optional(string, "60m")
          delete = optional(string, "60m")
        }), {})
        prod = optional(object({
          create = optional(string, "60m")
          update = optional(string, "60m")
          delete = optional(string, "60m")
        }), {})
      }), {})
    }), {})
  })

  validation {
    condition = contains([
      "prod",  # 本番環境
      "stg",   # ステージング環境
      "test",  # テスト環境
      "dev",   # 開発環境
      "sdbx1", # インフラ専用開発環境1 - リクエスト元、他
      "sdbx2", # インフラ専用開発環境2 - リクエスト先、他
    ], var.common.env)
    error_message = "common.envは次のいずれかを指定してください: prod, stg, test, dev, sdbx1, sdbx2"
  }

  validation {
    condition = contains([
      # 開発期間中
      "IN_ACTIVE_DEVELOPMENT",
      # 初回リリース以降
      "MAINTENANCE",
    ], var.common.github.phase)
    error_message = "common.github.phaseは次のいずれかを指定してください: IN_ACTIVE_DEVELOPMENT, MAINTENANCE"
  }

  default = {}
}

variable "secrets" {
  description = "全リソース共通で扱うシークレット群を入れるオブジェクト"
  sensitive   = true
  nullable    = true

  type = object({
    github = optional(object({
      # GITHUB_TOKEN
      # 以下のパターンでそれぞれ権限が異なる点に留意
      # - GitHub Actions内でデフォルトで利用出来るtoken
      # - GitHub Appsから渡すtoken
      # _ gh auth tokenで渡すtoken
      token = optional(string, null)
    }), {})
  })

  default = {}
}

variable "enum" {
  description = "全リソース共通で扱う列挙型を入れるオブジェクト"
  sensitive   = false
  nullable    = true

  type = object({
    # 環境
    environments = optional(set(string), [
      "prod",  # 本番環境
      "stg",   # ステージング環境
      "test",  # テスト環境
      "dev",   # 開発環境
      "sdbx1", # インフラ専用開発環境1 - リクエスト元、他
      "sdbx2", # インフラ専用開発環境2 - リクエスト先、他
    ])
    # フェーズ
    phase = optional(set(string), [
      "IN_ACTIVE_DEVELOPMENT", # 動作確認前
      "MAINTENANCE"            # 初回リリース以降
    ])
  })

  default = {}
}

variable "vpc" {
  description = "Amazon VPC"
  sensitive   = false
  nullable    = true

  type = list(object({
    # リソース短縮名
    # リソース名の構成要素としてだけでなく、terraform local nameとしても使用する
    resource_prefix     = optional(string, "vpc-")
    name_short          = optional(string, "main")
    vpc_resource_prefix = optional(string, "main-")
    # CIDRブロックを構成する要素
    cidr = optional(object({
      network_address = optional(string, "172.16.0.0")
      prefix          = optional(number, 21)
    }))
    # subnetを構成する要素
    # subnet_group:
    # "intra" - 外部と接続をするsubnet群
    # "protected" - 内部のリソースにのみ接続するsubnet群
    subnet_groups = list(object({
      resource_prefix = optional(string, "subnet-")
      group_name      = optional(string, "intra")
      az              = optional(list(string), ["ap-northeast-1a", "ap-northeast-1c", "ap-northeast-1d"])
      cidr = optional(object({
        prefix = optional(number, 24)
      }))
    }))
    route_table = optional(object({
      name_short = optional(string, "rt")
    }), {})
  }))

  # "main" - メインVPC
  # "misc" - サブ(汎用)VPC
  # 以下の用途などで使用:
  # - アプリケーションレイヤーのintegrationテスト用のstub/mockの配置
  # - networkリソースのinbound/outbound intergation/e2eテスト用リソースの配置
  # - パフォーマンステスト用のリソースの配置
  default = [
    {
      name_short          = "main"
      vpc_resource_prefix = "main-"
      cidr = {
        network_address = "172.16.0.0"
        prefix          = 21
      }
      subnet_groups = [
        {
          group_name = "intra"
          az         = ["ap-northeast-1a", "ap-northeast-1c", "ap-northeast-1d"]
          cidr = {
            prefix = 24
          }
        },
        {
          group_name = "protected"
          az         = ["ap-northeast-1a", "ap-northeast-1c", "ap-northeast-1d"]
          cidr = {
            prefix = 24
          }
        },
      ]
    },
    {
      name_short          = "misc"
      vpc_resource_prefix = "misc-"
      cidr = {
        network_address = "172.16.8.0"
        prefix          = 22
      }
      subnet_groups = [
        {
          group_name = "intra"
          az         = ["ap-northeast-1a", "ap-northeast-1c", "ap-northeast-1d"]
          cidr = {
            prefix = 24
          }
        },
        {
          group_name = "protected"
          az         = ["ap-northeast-1a", "ap-northeast-1c", "ap-northeast-1d"]
          cidr = {
            prefix = 24
          }
        },
      ]
    }
  ]
}

variable "alb" {
  description = "Elastic Load Balancing: Application Load Balancer"
  sensitive   = false
  nullable    = true

  type = object({
    resource_prefix = optional(string, "alb-")
    name_short      = optional(string, "fleet") # lb, tgは32文字制限がある為、common.subsystem + name_shortで16文字以内にする
    enable_deletion_protection = optional(object({
      dev  = optional(bool, false)
      test = optional(bool, true)
      stg  = optional(bool, true)
      prod = optional(bool, true)
    }), {})
    listener = optional(object({
      resource_prefix = optional(string, "alb-l-")
    }), {})
    listener_rule = optional(object({
      resource_prefix = optional(string, "alb-lr-")
    }), {})
    target_group = optional(object({
      resource_prefix = optional(string, "atg-")
    }), {})
    access_log = optional(object({
      prefix = optional(string, "access/alb")
      bucket = optional(object({
        resource_prefix = optional(string, "s3-")
        name_short      = optional(string, "alb-access-log")
      }), {})
    }), {})
    connection_log = optional(object({
      prefix = optional(string, "connection/alb")
      bucket = optional(object({
        resource_prefix = optional(string, "s3-")
        name_short      = optional(string, "alb-access-log")
      }), {})
    }), {})
  })

  validation {
    condition     = length(var.common.subsystem) + length(var.alb.name_short) < 16
    error_message = "var.common.subsystem + var.alb.name_short must be less than 16 characters"
  }

  default = {}
}

variable "ecs" {
  description = "Amazon Elastic Container Service"
  sensitive   = false
  nullable    = true

  type = object({
    cluster = optional(object({
      resource_prefix = optional(string, "cluster-")
      # if null, var.common.domain is used
      name_short = optional(string, null)
      cwlogs = optional(object({
        execute_command = optional(object({
          name_short = optional(string, "ecs-execute-command")
        }), {})
      }), {})
      capacity_provider = optional(object({
        dev  = optional(string, "FARGATE_SPOT")
        test = optional(string, "FARGATE")
        stg  = optional(string, "FARGATE")
        prod = optional(string, "FARGATE")
      }), {})
    }), {})
    service = optional(object({
      resource_prefix = optional(string, "service-")
      enable_execute_command = optional(object({
        dev  = optional(bool, true)
        test = optional(bool, false)
        stg  = optional(bool, false)
        prod = optional(bool, false)
      }), {})
      force_delete = optional(object({
        dev  = optional(bool, true)
        test = optional(bool, false)
        stg  = optional(bool, false)
        prod = optional(bool, false)
      }), {})
      force_new_deployment = optional(object({
        dev  = optional(bool, true)
        test = optional(bool, false)
        stg  = optional(bool, false)
        prod = optional(bool, false)
      }), {})
      health_check_grace_period_seconds = optional(object({
        dev  = optional(number, 2)
        test = optional(number, 10)
        stg  = optional(number, 10)
        prod = optional(number, 60)
      }), {})
      timeouts = optional(object({
        dev = optional(object({
          # TODO: revert
          create = optional(string, "1m")
          update = optional(string, "5m")
          delete = optional(string, "5m")
        }), {})
        test = optional(object({
          create = optional(string, "20m") # terraform's default
          update = optional(string, "20m") # terraform's default
          delete = optional(string, "20m") # terraform's default
        }), {})
        stg = optional(object({
          create = optional(string, "20m") # terraform's default
          update = optional(string, "20m") # terraform's default
          delete = optional(string, "20m") # terraform's default
        }), {})
        prod = optional(object({
          create = optional(string, "30m")
          update = optional(string, "30m")
          delete = optional(string, "30m")
        }), {})
      }), {})
    }), {})
    taskdef = optional(object({
      resource_prefix = optional(string, "taskdef-")
    }), {})
  })

  default = {}
}

variable "iam" {
  description = "AWS Identity and Access Management"
  sensitive   = false
  nullable    = true

  type = object({
    policy = optional(object({
      resource_prefix = optional(string, "iamp-")
    }), {})
    role = optional(object({
      resource_prefix = optional(string, "iamr-")
    }), {})
    role_names = optional(list(string), ["ecs-task-default", "ecs-exec-default", "scheduler-default"])
  })

  default = {}
}

variable "api" {
  description = "API"
  sensitive   = false
  nullable    = true

  type = object({
    this = optional(object({
      domain = optional(object({
        dev = optional(object({
          main = optional(string, "main.evems.eas-ev-dev.woven-cems.com")
          misc = optional(string, "misc.evems.eas-ev-dev.woven-cems.com")
        }), {})
        test = optional(object({
          main = optional(string, "evems.eas-ev-test.woven-cems.com")
        }), {})
        stg = optional(object({
          main = optional(string, "evems.eas-ev-stg.woven-cems.com")
        }), {})
        prod = optional(object({
          main = optional(string, "evems.eas-ev.woven-cems.com")
        }), {})
      }), {})
    }), {})
    destinations = optional(object({
      xev_vpp_doms = optional(object({
        test = optional(object({
          account_id  = optional(string, "TBD")         # TODO: manually add here
          cidr_blocks = optional(list(string), ["TBD"]) # TODO: manually add here
          domain      = optional(string, "TBD")         # TODO: manually add here
          vpc_endpoint = optional(object({
            resource_prefix = optional(string, "vpce-")
            name_short      = optional(string, "xev-vpp-doms")
            service_name    = optional(string, "TBD") # TODO: manually add here
          }), {})
        }), {})
        stg = optional(object({
          account_id  = optional(string, "TBD")         # TODO: manually add here
          cidr_blocks = optional(list(string), ["TBD"]) # TODO: manually add here
          domain      = optional(string, "TBD")         # TODO: manually add here
          vpc_endpoint = optional(object({
            resource_prefix = optional(string, "vpce-")
            name_short      = optional(string, "xev-vpp-doms")
            service_name    = optional(string, "TBD") # TODO: manually add here
          }), {})
        }), {})
        prod = optional(object({
          account_id  = optional(string, "TBD")         # TODO: manually add here
          cidr_blocks = optional(list(string), ["TBD"]) # TODO: manually add here
          domain      = optional(string, "TBD")         # TODO: manually add here
          public_dns  = optional(string, "TBD")         # TODO: manually add here
          vpc_endpoint = optional(object({
            resource_prefix = optional(string, "vpce-")
            name_short      = optional(string, "xev-vpp-doms")
            service_name    = optional(string, "TBD") # TODO: manually add here
          }), {})
        }), {})
      }), {})
    }), {})
  })

  default = {}
}

variable "is_ci" {
  description = "GitHub Actionsでの実行の場合"
  sensitive   = false
  nullable    = true

  type = bool

  default = false
}

variable "is_microservice" {
  description = "マイクロサービス毎のterraform modulesの場合"
  sensitive   = false
  nullable    = true

  type = bool

  default = false
}

variable "is_test" {
  description = "terraform testでの実行の場合"
  sensitive   = false
  nullable    = true

  type = bool

  default = false
}
