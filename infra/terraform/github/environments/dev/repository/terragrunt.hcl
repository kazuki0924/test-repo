include "root" {
  path   = "${get_repo_root()}/infra/terraform/shared/terragrunt.hcl"
  expose = true
}

terraform {
  source = "${get_path_to_repo_root()}/infra//${trimprefix(get_path_from_repo_root(), "infra")}"

  # [variables_{module}.tf]
  # e.g. infra/terraform/aws/modules/app/variables_app.tf -> infra/terraform/aws/environments/dev/app/variables_app.tf
  after_hook "symlink_varibales_module_tf_from_infra_module_to_root_module" {
    commands = ["terragrunt-read-config"]
    execute = [
      "ln",
      "-s", # create symlink
      "-f", # force
      "-v", # verbose
      "${include.root.locals.relpath_to_infra_module_from_root_module}/variables_${include.root.locals.module}.tf",
      "${include.root.locals.root_module}/variables_${include.root.locals.module}.tf"
    ]
    suppress_stdout = true
  }
}

inputs = {
  repository = {
    autolinks = [
      {
        key_prefix          = "THIS-REPO-"
        target_url_template = "https://github.com/${include.root.locals.org_repo}/blob/dev/<num>"
        is_alphanumeric     = true
      }
    ]
  }
  github_actions = {
    variables = {
      repository = {
        SYSTEM                           = include.root.locals.system
        SUBSYSTEM                        = include.root.locals.subsystem
        GH_OIDC_PROVIDER                 = include.root.locals.github.oidc.provider
        AWS_ACCOUNT_ID_DEV               = get_env("AWS_ACCOUNT_ID_DEV", "dummy")
        INSTALLATION_ACCESS_TOKEN_APP_ID = get_env("INSTALLATION_ACCESS_TOKEN_APP_ID", "dummy")
      }
    }
  }
  github_actions_secrets = {
    repository = {
      # TBD: use sops
      INSTALLATION_ACCESS_TOKEN_APP_PRIVATE_KEY = get_env("INSTALLATION_ACCESS_TOKEN_APP", "ZHVtbXk=") # echo -n "dummy" | base64
    }
  }
  secrets = {
    github = {
      token = get_env("GITHUB_TOKEN", "dummy")
    }
  }
}
