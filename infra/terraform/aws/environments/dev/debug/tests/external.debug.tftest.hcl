# !CAUTION this test only works with `terragrunt test` command

# refs:
# - https://developer.hashicorp.com/terraform/language/tests
# - https://developer.hashicorp.com/terraform/cli/commands/test
# - https://developer.hashicorp.com/terraform/cli/test
# - https://developer.hashicorp.com/terraform/language/tests#modules

run "external" {
  command = plan

  variables {
    is_test = true
    common  = var.defaults.common
  }

  assert {
    condition     = output.container_def_envs_json == "[{\"name\": \"HOGE\", \"value\": \"hoge\"}, {\"name\": \"HUGA\", \"value\": \"huga\"}, {\"name\": \"PIYO\", \"value\": \"piyo\"}, {\"name\": \"HOGE_HUGA\", \"value\": \"hoge_huga\"}, {\"name\": \"HOGE_PIYO\", \"value\": \"hoge_piyo\"}]"
    error_message = var.defaults.error_message
  }
}
