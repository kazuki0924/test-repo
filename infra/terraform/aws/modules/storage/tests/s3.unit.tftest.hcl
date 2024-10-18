# requirements:
# - `terragrunt init` ran in infra/terraform/{provider}/environments/dev/{module}
# - `terraform init` ran in infra/terraform/{provider}/modules/{module}

# refs:
# - https://developer.hashicorp.com/terraform/language/tests
# - https://developer.hashicorp.com/terraform/cli/commands/test
# - https://developer.hashicorp.com/terraform/cli/test
# - https://developer.hashicorp.com/terraform/language/tests#modules

run "unit_test_aws_s3_bucket_works" {
  # ref: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket
  command = plan

  variables {
    is_test = true
    common  = var.defaults.common
  }

  assert {
    condition = (
      aws_s3_bucket.this["alb-access-log"].bucket == "xev-vpp-evems-dev-s3-alb-access-log-delete-me"
    )
    error_message = var.defaults.error_message
  }

  assert {
    condition = (
      aws_s3_bucket.this["alb-access-log"].force_destroy == true
    )
    error_message = var.defaults.error_message
  }

  assert {
    condition = (
      aws_s3_bucket.this["alb-access-log"].tags_all.name == "xev-vpp-evems-dev-s3-alb-access-log-delete-me"
    )
    error_message = var.defaults.error_message
  }

  assert {
    condition = (
      aws_s3_bucket.this["alb-access-log"].tags_all.name_short == "alb-access-log"
    )
    error_message = var.defaults.error_message
  }
}

// TODO: rest
