# requirements:
# - `terragrunt init` ran in infra/terraform/{provider}/environments/dev/{module}
# - `terraform init` ran in infra/terraform/{provider}/modules/{module}

# refs:
# - https://developer.hashicorp.com/terraform/language/tests
# - https://developer.hashicorp.com/terraform/cli/commands/test
# - https://developer.hashicorp.com/terraform/cli/test
# - https://developer.hashicorp.com/terraform/language/tests#modules

run "integration_test_init_module_works" {
  # ref: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecr_registry_scanning_configuration
  command = apply

  variables {
    is_test = true
    common  = var.defaults.common
  }

  module {
    source = "../../../modules/init"
  }

  assert {
    condition = (
      aws_dynamodb_table.this["tfstate-lock"].name == "xev-vpp-evems-dev-ddb-tfstate-lock-delete-me"
    )
    error_message = var.defaults.error_message
  }

  assert {
    condition = (
      aws_dynamodb_table.this["tfstate-lock"].billing_mode == "PAY_PER_REQUEST"
    )
    error_message = var.defaults.error_message
  }

  assert {
    condition = (
      aws_dynamodb_table.this["tfstate-lock"].deletion_protection_enabled == false
    )
    error_message = var.defaults.error_message
  }

  assert {
    condition = (
      aws_dynamodb_table.this["tfstate-lock"].hash_key == "LockID"
    )
    error_message = var.defaults.error_message
  }

  assert {
    condition = (
      aws_dynamodb_table.this["tfstate-lock"].range_key == null
    )
    error_message = var.defaults.error_message
  }

  assert {
    condition = (
      aws_dynamodb_table.this["tfstate-lock"].tags.name == "xev-vpp-evems-dev-ddb-tfstate-lock-delete-me"
    )
    error_message = var.defaults.error_message
  }

  assert {
    condition = (
      aws_dynamodb_table.this["tfstate-lock"].tags.name_short == "tfstate-lock"
    )
    error_message = var.defaults.error_message
  }

  assert {
    condition = (
      length(
        [
          for attribute in aws_dynamodb_table.this["tfstate-lock"].attribute :
          attribute if attribute.name == "LockID" && attribute.type == "S"
        ]
      ) == 1
    )
    error_message = var.defaults.error_message
  }

  assert {
    condition = (
      length(
        [
          for point_in_time_recovery in aws_dynamodb_table.this["tfstate-lock"].point_in_time_recovery :
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
          for server_side_encryption in aws_dynamodb_table.this["tfstate-lock"].server_side_encryption :
          server_side_encryption if server_side_encryption.enabled == true
        ]
      ) == 1
    )
    error_message = var.defaults.error_message
  }
}
