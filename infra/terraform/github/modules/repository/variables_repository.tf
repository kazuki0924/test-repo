# Repository
variable "repository" {
  description = "GitHub Repository"
  sensitive   = false
  nullable    = true

  type = object({
    # ref: https://registry.terraform.io/providers/integrations/github/latest/docs/resources/repository
    # Terraformでimportする前に手動で入力されたdescriptionがある場合はここで指定しないとnullで上書きされてしまうので注意
    description = optional(string, null)
    visibility  = optional(string, "private")
    # GitFeatureFlowの場合、PRをマージしてもブランチを削除しない
    git_branching_model = optional(string, "GitFeatureFlow")
    # テンプレートリポジトリとして利用する場合
    is_template                 = optional(bool, false)
    enable_vulnerability_alerts = optional(bool, true)
    enable_advanced_security    = optional(bool, true)
    topics = optional(list(string), [
      "aws", "terraform", "terragrunt", "github-actions", "python"
    ])
    # teamの動作確認用:
    # teamの{name, id}一覧の取得:
    # gh api /orgs/${ORGS}/teams | jq '.[] | {name, id}'
    # ref: https://registry.terraform.io/providers/integrations/github/latest/docs/resources/repository_environment
    environments = optional(object({
      prod = optional(object({
        # refs:
        # - https://registry.terraform.io/providers/integrations/github/latest/docs/data-sources/team
        # - https://registry.terraform.io/providers/integrations/github/latest/docs/data-sources/user
        reviewers = optional(object({
          # username
          users = optional(set(string), [])
          # slug
          teams = optional(set(string), [])
        }), {})
        # refs:
        # - https://docs.github.com/en/rest/deployments/branch-policies?apiVersion=2022-11-28#create-a-deployment-branch-policy
        # - https://registry.terraform.io/providers/integrations/github/latest/docs/resources/repository_environment_deployment_policy
        deployment_policy = optional(object({
          branch_pattern = optional(string, "feat/*|hotfix/*|dev|test|stg|prod")
        }), {})
      }), {})
      stg = optional(object({
        reviewers = optional(object({
          # username
          users = optional(set(string), [])
          # slug
          teams = optional(set(string), [])
        }), {})
        deployment_policy = optional(object({
          branch_pattern = optional(string, "feat/*|hotfix/*|dev|test|stg")
        }), {})
      }), {})
      test = optional(object({
        reviewers = optional(object({
          # username
          users = optional(set(string), [])
          # slug
          teams = optional(set(string), [])
        }), {})
        deployment_policy = optional(object({
          branch_pattern = optional(string, "feat/*|hotfix/*|dev|test")
        }), {})
      }), {})
      dev = optional(object({
        reviewers = optional(object({
          # username
          users = optional(set(string), [])
          # slug
          teams = optional(set(string), [])
        }), {})
        deployment_policy = optional(object({
          branch_pattern = optional(string, "feat/*|hotfix/*|dev")
        }), {})
      }), {})
    }), {})
    # ref: https://docs.github.com/en/enterprise-cloud@latest/organizations/managing-user-access-to-your-organizations-repositories/managing-repository-roles/repository-roles-for-an-organization
    collaborators = optional(list(object({
      username   = optional(string)
      permission = optional(string, "push")
    })), [])
    teams = optional(list(object({
      slug       = optional(string)
      permission = optional(string, "push")
    })), [])
    autolinks = optional(list(object({
      key_prefix          = optional(string, "TICKET-")
      target_url_template = optional(string, "https://example.com/TICKET?query=<num>")
      is_alphanumeric     = optional(bool, false)
    })), [{}])
  })

  validation {
    condition = length(var.repository.collaborators) > 0 ? alltrue([for collaborator in var.repository.collaborators : contains([
      # Write権限
      "push",
      # Admin権限
      "admin"
      # 以下は利用する場合に追加
      # pull, maintain, triage,
    ], collaborator.permission)]) : true
    error_message = "repository.collaborators[*].permissionは次のいずれかを指定してください: push, admin"
  }

  validation {
    condition = length(var.repository.teams) > 0 ? alltrue([for team in var.repository.teams : contains([
      # Write権限
      "push",
      # Admin権限
      "admin"
      # 以下は利用する場合に追加
      # pull, maintain, triage,
    ], team.permission)]) : true
    error_message = "repository.teams[*].permissionは次のいずれかを指定してください: push, admin"
  }

  default = {}
}

# 登録するRepository Variables/Environment Variables
# - 基本的にGitHub Actionsで使う非シークレットな値はRepository Variablesとして登録する
# - 以下の問題を回避する為、基本的にEnvironment Variablesは使用しない方針とする
# - ref: https://github.com/orgs/community/discussions/36919
#   - GitHubの仕様でGitHub Environment Variablesを参照した場合、GitHub Actions Deploymentsが作成されてしまう
#   - 各種CIがAWS_ACCOUNT_IDなどのEnvironment Variablesを参照する度にDeploymentsが作成されてしまい、その度にPRにDeployments作成のメッセージが表示される為、PRレビューのメッセージが埋もれてしまう
#   - Deploymentsに承認フローを設定している場合、Deploymentsが作成される度に承認ボタンを押す必要がある
#   - その結果、Deployをする為に承認ボタンを何十回も押す必要が出てきてしまう
variable "github_actions" {
  description = "GitHub Actions"
  sensitive   = false
  nullable    = true

  type = object({
    access_level = optional(string, "none")
    # Note: GITHUB_ がprefixのVariables/Secretsを登録しようとするとエラーになる
    variables = optional(object({
      repository = optional(object({
        # システム名
        SYSTEM = optional(string, "xev-vpp")
        # サブシステム名
        SUBSYSTEM = optional(string, "evems")
        # AWSのリージョン
        AWS_DEFAULT_REGION = optional(string, "ap-northeast-1")
        # OIDC Provider
        GH_OIDC_PROVIDER = optional(string, "token.actions.githubusercontent.com/stargate")
        # ドメイン名
        THIS_API_DOMAIN_DEV      = optional(string, "main.evems.eas-ev-dev.woven-cems.com")
        THIS_API_DOMAIN_DEV_MISC = optional(string, "misc.evems.eas-ev-dev.woven-cems.com")
        THIS_API_DOMAIN_TEST     = optional(string, "evems.eas-ev-test.woven-cems.com")
        THIS_API_DOMAIN_STG      = optional(string, "evems.eas-ev-stg.woven-cems.com")
        THIS_API_DOMAIN_PROD     = optional(string, "evems.eas-ev.woven-cems.com")
        # 各環境のAWSアカウントID
        AWS_ACCOUNT_ID_DEV  = optional(string, null)
        AWS_ACCOUNT_ID_TEST = optional(string, null)
        AWS_ACCOUNT_ID_STG  = optional(string, null)
        AWS_ACCOUNT_ID_PROD = optional(string, null)
        # GitHub Actions worlflow内で使用するGitHub Installation Access Tokenを発行するGitHub AppのID
        INSTALLATION_ACCESS_TOKEN_APP_ID = optional(string, null)
        # SecretsにGitHub Personal Access Tokenを登録した際に更新の目安とする為にオプショナルで設定する
        PERSONAL_ACCESS_TOKEN_EXPIRATION_DATE = optional(string, "2026-01-01")
      }), {})
      environment = optional(object({
        prod = optional(object({
          DEPLOYMETS_REVIEW_REQUIRED = optional(string, "true")
        }), {})
        stg = optional(object({
          DEPLOYMETS_REVIEW_REQUIRED = optional(string, "false")
        }), {})
        test = optional(object({
          DEPLOYMETS_REVIEW_REQUIRED = optional(string, "false")
        }), {})
        dev = optional(object({
          DEPLOYMETS_REVIEW_REQUIRED = optional(string, "false")
        }), {})
      }), {})
    }), {})
    secrets_keys = optional(object({
      repository = optional(set(string), ["INSTALLATION_ACCESS_TOKEN_PRIVATE_KEY"])
      environment = optional(object({
        prod = optional(set(string), ["PER_ENV_SECRET_PLACEHOLDER"])
        stg  = optional(set(string), ["PER_ENV_SECRET_PLACEHOLDER"])
        test = optional(set(string), ["PER_ENV_SECRET_PLACEHOLDER"])
        dev  = optional(set(string), ["PER_ENV_SECRET_PLACEHOLDER"])
      }), {})
    }), {})
  })

  validation {
    condition = contains([
      # 他のリポジトリからの参照不可
      "none",
      # organization内で参照可
      "organization",
    ], var.github_actions.access_level)
    error_message = "github_actions.access_levelは次のいずれかを指定してください: none, organization"
  }

  default = {}
}

variable "github_actions_secrets" {
  description = "GitHub Actions Secrets"
  sensitive   = true
  nullable    = true

  type = object({
    repository = optional(object({
      # 任意でGitHub Personal Access Tokenを登録する際に設定する
      # 主にInstallation Aaccess Tokenでは操作出来ないGitHubリソースを一時的に操作する際にオプショナルで使用する
      # Classic Personal Access Tokenは非推奨となっている為、Fined GrainedのPersonal Access Tokenを"6 Months"の期限で使用する
      PERSONAL_ACCESS_TOKEN = optional(string, "ZHVtbXk=") # echo -n "dummy" | base64
      # GitHub Actions worlflow内で使用するGitHub Installation Access Tokenを発行するGitHub Appの秘密鍵
      INSTALLATION_ACCESS_TOKEN_PRIVATE_KEY = optional(string, "ZHVtbXk=")
      #
    }), {})
    environment = optional(object({
      prod = optional(object({
        PER_ENV_SECRET_PLACEHOLDER = optional(string, "ZHVtbXk=")
      }), {})
      stg = optional(object({
        PER_ENV_SECRET_PLACEHOLDER = optional(string, "ZHVtbXk=")
      }), {})
      test = optional(object({
        PER_ENV_SECRET_PLACEHOLDER = optional(string, "ZHVtbXk=")
      }), {})
      dev = optional(object({
        PER_ENV_SECRET_PLACEHOLDER = optional(string, "ZHVtbXk=")
      }), {})
    }), {})
  })

  default = {}
}

# ref: https://docs.github.com/en/enterprise-cloud@latest/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/about-rulesets
variable "rulesets" {
  description = "GitHub Repository rulesets"
  sensitive   = false
  nullable    = true

  type = object({
    conventional_commits = optional(object({
      enabled = optional(bool, true)
      # ref: https://gist.github.com/donhector/9b4139f1db682a77c9cdd3110e259505#file-conventional-commit-regex-md
      regex = optional(string, "^(build|chore|ci|docs|feat|fix|perf|refactor|revert|style|test)(\\(\\w+((,|\\/|\\\\)?\\s?\\w+)+\\))?!?: [\\S ]{1,99}[^\\.]$")
    }), {})
    semver_tags = optional(object({
      enabled = optional(bool, true)
      # ref: https://semver.org/
      # based on one of the semver.org's reccomended regex
      regex = optional(string, "^(?:(?P<pre_version>[a-zA-Z0-9]+(?:-[a-zA-Z0-9]+)*)-)?v(?P<major>0|[1-9]\\d*)\\.(?P<minor>0|[1-9]\\d*)\\.(?P<patch>0|[1-9]\\d*)(?:-(?P<prerelease>(?:0|[1-9]\\d*|\\d*[a-zA-Z-][0-9a-zA-Z-]*)(?:\\.(?:0|[1-9]\\d*|\\d*[a-zA-Z-][0-9a-zA-Z-]*))*))?(?:\\+(?P<buildmetadata>[0-9a-zA-Z-]+(?:\\.[0-9a-zA-Z-]+)*))?$")
    }), {})
    required_status_checks = optional(object({
      enabled = optional(bool, false)
      # TODO: add ci
      contexts = optional(list(string), [])
    }), {})
  })

  default = {}
}

variable "github_apps" {
  description = "GitHub Apps"
  sensitive   = false
  nullable    = true

  type = list(object({
    id = optional(string)
  }))

  default = []
}
