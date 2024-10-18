# requirements:
# - `terragrunt init` ran in infra/terraform/{provider}/environments/dev/{module}
# - `terraform init` ran in infra/terraform/{provider}/modules/{module}

# refs:
# - https://developer.hashicorp.com/terraform/language/tests
# - https://developer.hashicorp.com/terraform/cli/commands/test
# - https://developer.hashicorp.com/terraform/cli/test
# - https://developer.hashicorp.com/terraform/language/tests#modules

run "unit_test_github_actions_variable_works" {
  # ref: https://registry.terraform.io/providers/integrations/github/latest/docs/resources/actions_variable
  command = plan

  variables {
    is_test        = true
    common         = var.defaults.common
    github_actions = var.defaults.github_actions
  }

  assert {
    condition = (
      github_actions_variable.this["AWS_ACCOUNT_ID_DEV"].repository == var.common.github.repo
    )
    error_message = var.defaults.error_message
  }

  assert {
    condition = (
      github_actions_variable.this["AWS_ACCOUNT_ID_DEV"].variable_name == "AWS_ACCOUNT_ID_DEV"
    )
    error_message = var.defaults.error_message
  }

  assert {
    condition = (
      github_actions_variable.this["AWS_ACCOUNT_ID_DEV"].value == "123456789012"
    )
    error_message = var.defaults.error_message
  }

  assert {
    condition = (
      github_actions_variable.this["AWS_DEFAULT_REGION"].value == "ap-northeast-1"
    )
    error_message = var.defaults.error_message
  }
}

run "unit_test_github_actions_environment_variable_plan_works" {
  # ref: https://registry.terraform.io/providers/integrations/github/latest/docs/resources/actions_environment_variable#argument-reference
  command = plan

  variables {
    is_test = true
    common  = var.defaults.common
  }

  assert {
    condition = (
      github_actions_environment_variable.this["dev_DEPLOYMETS_REVIEW_REQUIRED"].repository == var.common.github.repo
    )
    error_message = var.defaults.error_message
  }

  assert {
    condition = (
      github_actions_environment_variable.this["dev_DEPLOYMETS_REVIEW_REQUIRED"].environment == "dev"
    )
    error_message = var.defaults.error_message
  }

  assert {
    condition = (
      github_actions_environment_variable.this["dev_DEPLOYMETS_REVIEW_REQUIRED"].variable_name == "DEPLOYMETS_REVIEW_REQUIRED"
    )
    error_message = var.defaults.error_message
  }

  assert {
    condition = (
      github_actions_environment_variable.this["dev_DEPLOYMETS_REVIEW_REQUIRED"].value == "false"
    )
    error_message = var.defaults.error_message
  }
}
