# !!! IMPORTANT !!!
# ! if you cancel the test run before teardown, you may need to manually clean up resources created by the test run

# requirements:
# - `terragrunt init` ran in infra/terraform/{provider}/environments/dev/{module}
# - `terraform init` ran in infra/terraform/{provider}/modules/{module}

# refs:
# - https://developer.hashicorp.com/terraform/language/tests
# - https://developer.hashicorp.com/terraform/cli/commands/test
# - https://developer.hashicorp.com/terraform/cli/test
# - https://developer.hashicorp.com/terraform/language/tests#modules

run "setup-init" {
  command = apply

  variables {
    is_test = true
    common  = var.defaults.common
  }

  module {
    source = "../../../modules/init"
  }
}

run "setup-storage" {
  command = apply

  variables {
    is_test = true
    common  = var.defaults.common
  }

  module {
    source = "../storage"
  }
}

run "setup-network" {
  command = apply

  variables {
    is_test = true
    common  = var.defaults.common
  }

  module {
    source = "../network"
  }
}

run "integration_test_app_module_works" {
  # ref: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecr_lifecycle_policy
  command = apply

  variables {
    is_test = true
    common  = var.defaults.common
  }

  module {
    source = "../../../modules/app"
  }

  assert {
    condition = (
      aws_ecr_lifecycle_policy.this["stub-intra-api"].registry_id == aws_ecr_repository.this["stub-intra-api"].registry_id
    )
    error_message = var.defaults.error_message
  }

  assert {
    condition = (
      aws_ecr_registry_scanning_configuration.this.registry_id == aws_ecr_repository.this["stub-intra-api"].registry_id
    )
    error_message = var.defaults.error_message
  }
}
