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

// run "setup-init" {
//   command = apply

//   variables {
//     is_test = true
//     common  = var.defaults.common
//   }

//   module {
//     source = "../../../../../../../../../infra/terraform/aws/modules/init"
//   }
// }

// run "setup-storage" {
//   command = apply

//   variables {
//     is_test = true
//     common  = var.defaults.common
//   }

//   module {
//     source = "../../../../../../../../../infra/terraform/aws/environments/dev/storage"
//   }
// }

// run "setup-network" {
//   command = apply

//   variables {
//     is_test = true
//     common  = var.defaults.common
//   }

//   module {
//     source = "../../../../../../../../../infra/terraform/aws/environments/dev/network"
//   }
// }

// run "setup-microservices-shared-app" {
//   command = apply

//   variables {
//     is_test = true
//     common  = var.defaults.common
//   }

//   module {
//     source = "../../../../../../../../../infra/terraform/aws/environments/dev/app"
//   }
// }

// run "integration_test_per_microservice_app_module_works" {
//   # ref: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecr_lifecycle_policy
//   command = apply

//   variables {
//     is_test = true
//     common  = var.defaults.common
//   }

//   module {
//     source = "../../../modules/app"
//   }

//   assert {
//     condition = (
//       aws_ecs_service.this["main-stub-intra-api"].tags_all.name_short == "stub-intra-api"
//     )
//     error_message = var.defaults.error_message
//   }
// }
