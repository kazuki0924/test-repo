# requirements:
# - `terragrunt init` ran in infra/terraform/{provider}/environments/dev/{module}
# - `terraform init` ran in infra/terraform/{provider}/modules/{module}

# refs:
# - https://developer.hashicorp.com/terraform/language/tests
# - https://developer.hashicorp.com/terraform/cli/commands/test
# - https://developer.hashicorp.com/terraform/cli/test
# - https://developer.hashicorp.com/terraform/language/tests#modules

run "unit_test_aws_iam_role_works" {
  # ref: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecr_registry_scanning_configuration
  command = plan

  variables {
    is_test = true
    common  = var.defaults.common
    github  = var.defaults.github
  }

  assert {
    condition = (
      aws_iam_role.this.name == "xev-vpp-evems-dev-iamr-github-actions-delete-me"
    )
    error_message = var.defaults.error_message
  }

  assert {
    condition = (
      aws_iam_role.this.tags.name == "xev-vpp-evems-dev-iamr-github-actions-delete-me"
    )
    error_message = var.defaults.error_message
  }

  assert {
    condition = (
      aws_iam_role.this.tags_all.env == "dev"
    )
    error_message = var.defaults.error_message
  }
}

# TODO: rest
