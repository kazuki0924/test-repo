# requirements:
# - `terragrunt init` ran in infra/terraform/{provider}/environments/dev/{module}

# refs:
# - https://developer.hashicorp.com/terraform/language/tests
# - https://developer.hashicorp.com/terraform/cli/commands/test
# - https://developer.hashicorp.com/terraform/cli/test
# - https://developer.hashicorp.com/terraform/language/tests#modules

run "integration_test_storage_module_works" {
  command = apply

  variables {
    is_test = true
    common  = var.defaults.common
  }

  module {
    source = "../../../modules/db"
  }

  assert {
    condition = (
      aws_dynamodb_table.this["EVSE-MASTER"].name == "T01_WVPP-XEV-DEV-DDB-EVSE-MASTER-delete-me"
    )
    error_message = var.defaults.error_message
  }
}
