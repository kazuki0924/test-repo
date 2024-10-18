# !CAUTION this test only works with `terragrunt test` command

# refs:
# - https://developer.hashicorp.com/terraform/language/tests
# - https://developer.hashicorp.com/terraform/cli/commands/test
# - https://developer.hashicorp.com/terraform/cli/test
# - https://developer.hashicorp.com/terraform/language/tests#modules

run "terraform_configuration_language" {
  command = plan

  variables {
    is_test = true
    common  = var.defaults.common
  }

  assert {
    condition     = output.if_main_return_misc_else_main_with_main == "misc"
    error_message = var.defaults.error_message
  }

  assert {
    condition     = output.if_main_return_misc_else_main_with_misc == "main"
    error_message = var.defaults.error_message
  }
}
