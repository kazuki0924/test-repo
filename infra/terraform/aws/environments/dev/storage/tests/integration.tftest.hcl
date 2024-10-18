# requirements:
# - `terragrunt init` ran in infra/terraform/{provider}/environments/dev/{module}

# refs:
# - https://developer.hashicorp.com/terraform/language/tests
# - https://developer.hashicorp.com/terraform/cli/commands/test
# - https://developer.hashicorp.com/terraform/cli/test
# - https://developer.hashicorp.com/terraform/language/tests#modules

run "setup-init" {
  command = apply

  variables {
    is_test  = true
    common   = var.defaults.common
    s3       = null
    dynamodb = null
  }

  module {
    source = "../../../modules/init"
  }
}

run "integration_test_storage_module_works" {
  command = apply

  variables {
    is_test = true
    common  = var.defaults.common
  }

  module {
    source = "../../../modules/storage"
  }

  assert {
    condition = (
      aws_s3_bucket.this["alb-access-log"].bucket == "xev-vpp-evems-dev-s3-alb-access-log-delete-me"
    )
    error_message = var.defaults.error_message
  }
}
