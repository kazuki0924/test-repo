# shared terragrunt.hcl

# 全root module(**infra/terraform/*/environments/*)共通terragrunt.hcl
# 各root moduleに加え、各root moduleと他対1の関係となるinfra module(**infra/terraform/*/modules/*)に対してもファイルの配置等も行う

locals {
  system                                                   = get_env("SYSTEM", "xev-vpp")
  subsystem                                                = get_env("SUBSYSTEM", "evems")
  origin                                                   = run_cmd("--terragrunt-quiet", "git", "config", "--get", "remote.origin.url")
  org                                                      = regex("^(?:git@github.com:|https://github.com/)([^/]+)/", local.origin)[0]
  repo                                                     = split(".", basename(local.origin))[0]
  org_repo                                                 = "${local.org}/${local.repo}"
  domain                                                   = trimprefix(trimprefix(local.repo, "${local.system}-"), "${local.subsystem}-")
  root_module                                              = get_original_terragrunt_dir()
  repo_root                                                = get_repo_root()
  abspath_to_root_module_from_repo_root                    = trimprefix(local.root_module, "${local.repo_root}/")
  is_microservice                                          = startswith(local.abspath_to_root_module_from_repo_root, "src/")
  module                                                   = basename(local.abspath_to_root_module_from_repo_root)
  env                                                      = basename(trimsuffix(local.abspath_to_root_module_from_repo_root, local.module))
  tf_provider                                              = basename(trimsuffix(local.abspath_to_root_module_from_repo_root, "environments/${local.env}/${local.module}"))
  abspath_to_root_module_from_repo_root_forwardslash_split = split("/", local.abspath_to_root_module_from_repo_root)
  subdomain                                                = local.is_microservice ? local.abspath_to_root_module_from_repo_root_forwardslash_split[1] : "noop"
  microservice                                             = local.is_microservice ? local.abspath_to_root_module_from_repo_root_forwardslash_split[2] : "noop"
  prefix                                                   = "${local.system}-${local.subsystem}-${local.env}-"
  relpath_to_repo_root_from_root_module                    = get_path_to_repo_root()
  relpath_to_repo_root_from_root_module_tests              = "../${get_path_to_repo_root()}"
  relpath_to_repo_root_from_infra_module                   = trimprefix(get_path_to_repo_root(), "../")
  relpath_to_repo_root_from_infra_module_tests             = get_path_to_repo_root()
  relpath_to_infra_module_from_root_module = run_cmd(
    "--terragrunt-quiet",
    "realpath",
    "--canonicalize-missing",
    "--relative-to",
    "infra/terraform/${local.tf_provider}/environments/${local.env}/${local.module}",
    "infra/terraform/${local.tf_provider}/modules/${local.module}",
  )
  relpath_to_provider_shared_from_root_module = run_cmd(
    "--terragrunt-quiet",
    "realpath",
    "--canonicalize-missing",
    "--relative-to",
    "infra/terraform/${local.tf_provider}/environments/${local.env}/${local.module}",
    "infra/terraform/${local.tf_provider}/shared",
  )
  relpath_to_provider_shared_from_root_module_tests = run_cmd(
    "--terragrunt-quiet",
    "realpath",
    "--canonicalize-missing",
    "--relative-to",
    "infra/terraform/${local.tf_provider}/environments/${local.env}/${local.module}/tests",
    "infra/terraform/${local.tf_provider}/shared",
  )
  relpath_to_provider_shared_from_infra_module = run_cmd(
    "--terragrunt-quiet",
    "realpath",
    "--canonicalize-missing",
    "--relative-to",
    "infra/terraform/${local.tf_provider}/modules/${local.module}",
    "infra/terraform/${local.tf_provider}/shared",
  )
  relpath_to_provider_shared_from_infra_module_tests = run_cmd(
    "--terragrunt-quiet",
    "realpath",
    "--canonicalize-missing",
    "--relative-to",
    "infra/terraform/${local.tf_provider}/modules/${local.module}/tests",
    "infra/terraform/${local.tf_provider}/shared",
  )
  relpath_to_microservices_shared_root_module_from_per_microservice_root_module = run_cmd(
    "--terragrunt-quiet",
    "realpath",
    "--canonicalize-missing",
    "--relative-to",
    "src/${local.subdomain}/${local.microservice}/infra/terraform/${local.tf_provider}/environments/${local.env}/${local.module}",
    "infra/terraform/${local.tf_provider}/environments/${local.env}/${local.module}",
  )
  relpath_to_microservices_shared_infra_module_from_per_microservice_infra_module = run_cmd(
    "--terragrunt-quiet",
    "realpath",
    "--canonicalize-missing",
    "--relative-to",
    "src/${local.subdomain}/${local.microservice}/infra/terraform/${local.tf_provider}/modules/${local.module}",
    "infra/terraform/${local.tf_provider}/modules/${local.module}",
  )
  # devcontainerでは`~/.bashrc`で`source .env.tool-versions`を行って環境変数を読み込んで以下のバージョンを指定している
  # github actionsでは`GITHUB_ENV`に`.env.tool-versions`の中身を出力する処理を行って環境変数を読み込んで以下のバージョンを指定している
  versions = {
    terragrunt = get_env("TERRAGRUNT_VERSION")
    terraform  = get_env("TERRAFORM_VERSION")
    terraform_provider = {
      cloud = {
        aws    = get_env("TERRAFORM_PROVIDER_AWS_VERSION")
        github = get_env("TERRAFORM_PROVIDER_GITHUB_VERSION")
      }
      # ref: https://registry.terraform.io/search/providers?category=utility&namespace=hashicorp
      utility = {
        local    = get_env("TERRAFORM_PROVIDER_LOCAL_VERSION")
        null     = get_env("TERRAFORM_PROVIDER_NULL_VERSION")
        random   = get_env("TERRAFORM_PROVIDER_RANDOM_VERSION")
        external = get_env("TERRAFORM_PROVIDER_EXTERNAL_VERSION")
        assert   = get_env("TERRAFORM_PROVIDER_ASSERT_VERSION")
      }
    }
  }
  aws = {
    account_id   = run_cmd("--terragrunt-quiet", "aws", "sts", "get-caller-identity", "--query", "Account", "--output", "text")
    region       = "ap-northeast-1"
    created_at   = timestamp()
    created_date = formatdate("YYYYMMDD-hhmmss", timestamp())
  }
  github = {
    oidc = {
      provider = get_env("GH_OIDC_PROVIDER", "token.actions.githubusercontent.com/stargate")
    }
    iam_role = {
      resource_prefix = "iamr-"
      name_short      = "github-actions"
    }
  }
  api = {
    this = {
      domain = {
        dev = {
          main = get_env("THIS_API_DOMAIN_DEV", "main.evems.eas-ev-dev.woven-cems.com")
          misc = get_env("THIS_API_DOMAIN_DEV_MISC", "misc.evems.eas-ev-dev.woven-cems.com")
        }
        test = {
          main = get_env("THIS_API_DOMAIN_TEST", "evems.eas-ev-test.woven-cems.com")
        }
        stg = {
          main = get_env("THIS_API_DOMAIN_STG", "evems.eas-ev-stg.woven-cems.com")
        }
        prod = {
          main = get_env("THIS_API_DOMAIN_PROD", "evems.eas-ev.woven-cems.com")
        }
      }
    }
  }
  backend = {
    s3 = {
      resource_prefix = "s3-"
      name_short      = "tfstate"
    }
    dynamodb = {
      resource_prefix = "ddb-"
      name_short      = "tfstate-lock"
    }
    key_prefix = (
      local.is_microservice ?
      "${local.domain}/${local.subdomain}/${local.microservice}/${local.tf_provider}/${local.env}/${local.module}" :
      "${local.domain}/${local.tf_provider}/${local.env}/${local.module}"
    )
    key = "terraform.tfstate"
  }
  s3_bucket_tfstate_id           = "${local.prefix}${local.backend.s3.resource_prefix}${local.backend.s3.name_short}"
  dynamodb_table_tfstate_lock_id = "${local.prefix}${local.backend.dynamodb.resource_prefix}${local.backend.dynamodb.name_short}"
  # for `terragrunt test`
  path_relative_to_include    = path_relative_to_include()
  path_relative_from_include  = path_relative_from_include()
  get_repo_root               = get_repo_root()
  get_path_from_repo_root     = get_path_from_repo_root()
  get_path_to_repo_root       = get_path_to_repo_root()
  get_terragrunt_dir          = get_terragrunt_dir()
  get_working_dir             = get_working_dir()
  get_parent_terragrunt_dir   = get_parent_terragrunt_dir()
  get_original_terragrunt_dir = get_original_terragrunt_dir()
}

inputs = {
  common = {
    system       = local.system
    subsystem    = local.subsystem
    env          = local.env
    provider     = local.tf_provider
    module       = local.module
    domain       = local.domain
    subdomain    = local.subdomain == "noop" ? null : local.subdomain
    microservice = local.microservice == "noop" ? null : local.microservice
    prefix       = local.prefix
    repo_root    = local.repo_root
    github = {
      org  = local.org
      repo = local.repo
    }
    aws = merge(
      local.aws,
      {
        default_tags = {
          system       = local.system
          subsystem    = local.subsystem
          env          = local.env
          domain       = local.domain
          subdomain    = local.subdomain
          microservice = local.microservice
          org          = local.org
          repo         = local.repo
        }
    })
  }
  api = local.api
  # ref: https://docs.github.com/en/actions/writing-workflows/choosing-what-your-workflow-does/store-information-in-variables#default-environment-variables
  is_ci           = get_env("CI", "false") # In GitHub Actions, this is always set to true
  is_microservice = local.is_microservice
}

# ref: https://terragrunt.gruntwork.io/docs/reference/config-blocks-and-attributes/#remote_state
remote_state {
  backend      = "s3"
  disable_init = false
  generate = {
    path      = "${local.root_module}/backend_generated.tf"
    if_exists = "overwrite_terragrunt"
  }
  config = {
    region         = local.aws.region
    encrypt        = true
    bucket         = local.s3_bucket_tfstate_id
    dynamodb_table = local.dynamodb_table_tfstate_lock_id
    key            = "${local.backend.key_prefix}/${local.backend.key}"
    # 以下はterraformを使って作成・管理する為、terragruntでは作成しない
    # aws_dynamodb_table, accesslogging_bucketも同様
    skip_bucket_versioning             = true
    skip_bucket_ssencryption           = true
    skip_bucket_root_access            = true
    skip_bucket_enforced_tls           = true
    skip_bucket_public_access_blocking = true
  }
}

# ! CAUTION terragrunt will glitch if set
# download_dir = abspath(
#  "${get_repo_root()}/.terragrunt-cache"
# )

terraform_version_constraint  = "~> ${local.versions.terraform}"
terragrunt_version_constraint = "~> ${local.versions.terragrunt}"

# [versions.tf]
# e.g. infra/terraform/aws/shared/templatefile/versions.tf.tftpl -> infra/terraform/aws/environments/dev/app/versions.tf
generate "versions_tf_from_provider_shared_to_root_module" {
  path      = "${local.root_module}/versions.tf"
  if_exists = "overwrite_terragrunt"
  contents = templatefile("${get_repo_root()}/infra/terraform/${local.tf_provider}/shared/templatefile/versions.tf.tftpl", {
    terraform_version                   = local.versions.terraform
    terraform_provider_main_version     = local.versions.terraform_provider.cloud[local.tf_provider]
    terraform_provider_local_version    = local.versions.terraform_provider.utility.local
    terraform_provider_null_version     = local.versions.terraform_provider.utility.null
    terraform_provider_random_version   = local.versions.terraform_provider.utility.random
    terraform_provider_external_version = local.versions.terraform_provider.utility.external
    terraform_provider_assert_version   = local.versions.terraform_provider.utility.assert
  })
}

# e.g. infra/terraform/aws/shared/templatefile/versions.tf.tftpl -> infra/terraform/aws/modules/app/versions.tf
generate "versions_tf_from_provider_shared_to_infra_module" {
  path      = "${local.relpath_to_infra_module_from_root_module}/versions.tf"
  if_exists = "overwrite_terragrunt"
  contents = templatefile("${get_repo_root()}/infra/terraform/${local.tf_provider}/shared/templatefile/versions.tf.tftpl", {
    terraform_version                   = local.versions.terraform
    terraform_provider_main_version     = local.versions.terraform_provider.cloud[local.tf_provider]
    terraform_provider_local_version    = local.versions.terraform_provider.utility.local
    terraform_provider_null_version     = local.versions.terraform_provider.utility.null
    terraform_provider_random_version   = local.versions.terraform_provider.utility.random
    terraform_provider_external_version = local.versions.terraform_provider.utility.external
    terraform_provider_assert_version   = local.versions.terraform_provider.utility.assert
  })
}

terraform {
  # [variables_common.tf]
  # e.g. infra/terraform/shared/variables_common.tf -> infra/terraform/aws/environments/dev/app/variables_common.tf
  after_hook "symlink_varibales_common_tf_from_terraform_shared_to_root_module" {
    commands = ["terragrunt-read-config"]
    execute = [
      "ln",
      "-s", # create symlink
      "-f", # force
      "-v", # verbose
      "${local.relpath_to_repo_root_from_root_module}/infra/terraform/shared/variables_common.tf",
      "${local.root_module}/variables_common.tf"
    ]
    suppress_stdout = true
  }

  # e.g. infra/terraform/shared/variables_common.tf -> infra/terraform/aws/modules/app/variables_common.tf
  after_hook "symlink_varibales_common_tf_from_terraform_shared_to_infra_module" {
    commands = ["terragrunt-read-config"]
    execute = [
      "ln",
      "-s", # create symlink
      "-f", # force
      "-v", # verbose
      "${local.relpath_to_repo_root_from_infra_module}/infra/terraform/shared/variables_common.tf",
      "${local.relpath_to_infra_module_from_root_module}/variables_common.tf"
    ]
    suppress_stdout = true
  }

  # [locals_common.tf]
  # e.g. infra/terraform/shared/locals_common.tf -> infra/terraform/aws/environments/dev/app/locals_common.tf
  after_hook "symlink_varibales_common_tf_from_terraform_shared_to_root_module" {
    commands = ["terragrunt-read-config"]
    execute = [
      "ln",
      "-s", # create symlink
      "-f", # force
      "-v", # verbose
      "${local.relpath_to_repo_root_from_root_module}/infra/terraform/shared/locals_common.tf",
      "${local.root_module}/locals_common.tf"
    ]
    suppress_stdout = true
  }

  # e.g. infra/terraform/shared/locals_common.tf -> infra/terraform/aws/modules/app/locals_common.tf
  after_hook "symlink_varibales_common_tf_from_terraform_shared_to_infra_module" {
    commands = ["terragrunt-read-config"]
    execute = [
      "ln",
      "-s", # create symlink
      "-f", # force
      "-v", # verbose
      "${local.relpath_to_repo_root_from_infra_module}/infra/terraform/shared/locals_common.tf",
      "${local.relpath_to_infra_module_from_root_module}/locals_common.tf"
    ]
    suppress_stdout = true
  }

  # [data_common.tf]
  # e.g. infra/terraform/shared/data_common.tf -> infra/terraform/aws/environments/dev/app/data_common.tf
  after_hook "symlink_varibales_common_tf_from_terraform_shared_to_root_module" {
    commands = ["terragrunt-read-config"]
    execute = [
      "ln",
      "-s", # create symlink
      "-f", # force
      "-v", # verbose
      "${local.relpath_to_repo_root_from_root_module}/infra/terraform/shared/data_common.tf",
      "${local.root_module}/data_common.tf"
    ]
    suppress_stdout = true
  }

  # e.g. infra/terraform/shared/data_common.tf -> infra/terraform/aws/modules/app/data_common.tf
  after_hook "symlink_varibales_common_tf_from_terraform_shared_to_infra_module" {
    commands = ["terragrunt-read-config"]
    execute = [
      "ln",
      "-s", # create symlink
      "-f", # force
      "-v", # verbose
      "${local.relpath_to_repo_root_from_infra_module}/infra/terraform/shared/data_common.tf",
      "${local.relpath_to_infra_module_from_root_module}/data_common.tf"
    ]
    suppress_stdout = true
  }

  # [provider.tf]
  # e.g. infra/terraform/aws/shared/provider.tf -> infra/terraform/aws/environments/dev/app/provider.tf
  after_hook "symlink_provider_tf_from_provider_shared_to_root_module" {
    commands = ["terragrunt-read-config"]
    execute = [
      "ln",
      "-s", # create symlink
      "-f", # force
      "-v", # verbose
      "${local.relpath_to_repo_root_from_root_module}/infra/terraform/${local.tf_provider}/shared/provider.tf",
      "${local.root_module}/provider.tf"
    ]
    suppress_stdout = true
  }

  # e.g. infra/terraform/aws/shared/provider.tf -> infra/terraform/aws/modules/app/provider.tf
  after_hook "symlink_provider_tf_from_provider_shared_to_infra_module" {
    commands = ["terragrunt-read-config"]
    execute = [
      "ln",
      "-s", # create symlink
      "-f", # force
      "-v", # verbose
      "${local.relpath_to_repo_root_from_infra_module}/infra/terraform/${local.tf_provider}/shared/provider.tf",
      "${local.relpath_to_infra_module_from_root_module}/provider.tf"
    ]
    suppress_stdout = true
  }

  # [.{module}.auto.tfvars]
  # e.g. infra/terraform/aws/shared/.app.auto.tfvars -> infra/terraform/aws/environments/dev/app/.app.auto.tfvars
  after_hook "symlink_module_auto_tfvars_from_provider_shared_to_root_module" {
    commands = ["terragrunt-read-config"]
    execute = [
      "ln",
      "-s", # create symlink
      "-f", # force
      "-v", # verbose
      "${local.relpath_to_provider_shared_from_root_module}/.${local.module}.auto.tfvars",
      "${local.root_module}/.${local.module}.auto.tfvars"
    ]
    suppress_stdout = true
  }

  # e.g. infra/terraform/aws/shared/.app.auto.tfvars -> infra/terraform/aws/environments/dev/app/tests/.app.auto.tfvars
  after_hook "symlink_module_auto_tfvars_from_provider_shared_to_root_module_tests" {
    commands = ["terragrunt-read-config"]
    execute = [
      "ln",
      "-s", # create symlink
      "-f", # force
      "-v", # verbose
      "${local.relpath_to_provider_shared_from_root_module_tests}/.${local.module}.auto.tfvars",
      "${local.root_module}/tests/.${local.module}.auto.tfvars"
    ]
    suppress_stdout = true
  }

  # e.g. infra/terraform/aws/shared/.app.auto.tfvars -> infra/terraform/aws/modules/app/.app.auto.tfvars
  after_hook "symlink_module_auto_tfvars_from_provider_shared_to_infra_module" {
    commands = ["terragrunt-read-config"]
    execute = [
      "ln",
      "-s", # create symlink
      "-f", # force
      "-v", # verbose
      "${local.relpath_to_provider_shared_from_infra_module}/.${local.module}.auto.tfvars",
      "${local.relpath_to_infra_module_from_root_module}/.${local.module}.auto.tfvars"
    ]
    suppress_stdout = true
  }

  # e.g. infra/terraform/aws/shared/.app.auto.tfvars -> infra/terraform/aws/modules/app/tests/.app.auto.tfvars
  after_hook "symlink_module_auto_tfvars_from_provider_shared_to_infra_module_tests" {
    commands = ["terragrunt-read-config"]
    execute = [
      "ln",
      "-s", # create symlink
      "-f", # force
      "-v", # verbose
      "${local.relpath_to_provider_shared_from_infra_module_tests}/.${local.module}.auto.tfvars",
      "${local.relpath_to_infra_module_from_root_module}/tests/.${local.module}.auto.tfvars"
    ]
    suppress_stdout = true
  }

  # e.g. infra/terraform/aws/environments/test/app
  after_hook "mkdir_root_module_test" {
    commands = ["terragrunt-read-config"]
    execute = [
      "mkdir",
      "-p",
      "../../test/${local.module}"
    ]
    suppress_stdout = true
  }

  # e.g. infra/terraform/aws/environments/stg/app
  after_hook "mkdir_root_module_stg" {
    commands = ["terragrunt-read-config"]
    execute = [
      "mkdir",
      "-p",
      "../../stg/${local.module}"
    ]
    suppress_stdout = true
  }

  # e.g. infra/terraform/aws/environments/prod/app
  after_hook "mkdir_root_module_prod" {
    commands = ["terragrunt-read-config"]
    execute = [
      "mkdir",
      "-p",
      "../../prod/${local.module}"
    ]
    suppress_stdout = true
  }

  extra_arguments "retry_lock" {
    commands = get_terraform_commands_that_need_locking()
    arguments = [
      "-lock=true",
      "-lock-timeout=5m"
    ]
  }

  extra_arguments "default_project_specific_vars" {
    commands           = concat(get_terraform_commands_that_need_vars(), ["test"])
    required_var_files = ["${local.root_module}/.${local.module}.auto.tfvars"]
  }

  extra_arguments "disable_input" {
    commands  = get_terraform_commands_that_need_input()
    arguments = ["-input=false"]
  }

  include_in_copy = ["*.auto.tfvars"]
}
