# requirements:
# - `terragrunt init` ran in infra/terraform/{provider}/environments/dev/{module}
# - `terraform init` ran in infra/terraform/{provider}/modules/{module}

# refs:
# - https://developer.hashicorp.com/terraform/language/tests
# - https://developer.hashicorp.com/terraform/cli/commands/test
# - https://developer.hashicorp.com/terraform/cli/test
# - https://developer.hashicorp.com/terraform/language/tests#modules

run "unit_test_aws_dynamodb_table_works_app" {
  # ref: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecr_registry_scanning_configuration
  command = plan

  variables {
    is_test = true
    common  = var.defaults.common
  }

  assert {
    condition = (
      aws_dynamodb_table.this["EVSE-MASTER"].name == "T01_WVPP-XEV-DEV-DDB-EVSE-MASTER-delete-me"
    )
    error_message = var.defaults.error_message
  }

  assert {
    condition = (
      aws_dynamodb_table.this["EVSE-MASTER"].billing_mode == "PAY_PER_REQUEST"
    )
    error_message = var.defaults.error_message
  }

  assert {
    condition = (
      aws_dynamodb_table.this["EVSE-MASTER"].deletion_protection_enabled == false
    )
    error_message = var.defaults.error_message
  }

  assert {
    condition = (
      aws_dynamodb_table.this["EVSE-MASTER"].hash_key == "chargerId"
    )
    error_message = var.defaults.error_message
  }

  assert {
    condition = (
      aws_dynamodb_table.this["EVSE-MASTER"].range_key == null
    )
    error_message = var.defaults.error_message
  }

  assert {
    condition = (
      aws_dynamodb_table.this["EVSE-MASTER"].tags.name == "T01_WVPP-XEV-DEV-DDB-EVSE-MASTER-delete-me"
    )
    error_message = var.defaults.error_message
  }

  assert {
    condition = (
      aws_dynamodb_table.this["EVSE-MASTER"].tags.name_short == "EVSE-MASTER"
    )
    error_message = var.defaults.error_message
  }

  assert {
    condition = (
      length(
        [
          for attribute in aws_dynamodb_table.this["EVSE-MASTER"].attribute :
          attribute if attribute.name == "chargerId" && attribute.type == "S"
        ]
      ) == 1
    )
    error_message = var.defaults.error_message
  }

  assert {
    condition = (
      length(
        [
          for point_in_time_recovery in aws_dynamodb_table.this["EVSE-MASTER"].point_in_time_recovery :
          point_in_time_recovery if point_in_time_recovery.enabled == true
        ]
      ) == 1
    )
    error_message = var.defaults.error_message
  }

  assert {
    condition = (
      length(
        [
          for server_side_encryption in aws_dynamodb_table.this["EVSE-MASTER"].server_side_encryption :
          server_side_encryption if server_side_encryption.enabled == true
        ]
      ) == 1
    )
    error_message = var.defaults.error_message
  }
}

# TODO: add more
