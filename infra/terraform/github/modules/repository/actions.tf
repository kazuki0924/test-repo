# locals {
#   environment_variables = var.github_actions.variables.environment != null ? flatten([
#     for environment, variable in var.github_actions.variables.environment : variable != null ? [
#       for key, value in variable : value != null ? {
#         environment = environment
#         key         = key
#         value       = value
#       } : null
#     ] : null
#   ]) : []
#   environment_secrets = var.github_actions.secrets_keys.environment != null ? flatten([
#     for environment, secret_keys in var.github_actions.secrets_keys.environment : secret_keys != null ? [
#       for key in secret_keys : key != null ? {
#         environment = environment
#         key         = key
#       } : null
#     ] : null
#   ]) : []
# }

# # Repository Variables
# resource "github_actions_variable" "this" {
#   # ref: https://registry.terraform.io/providers/integrations/github/latest/docs/resources/actions_variable
#   depends_on = [github_repository.this]
#   for_each = {
#     for key, value in var.github_actions.variables.repository : key => value if value != null
#   }

#   repository = github_repository.this.name

#   variable_name = each.key
#   value         = each.value
# }

# # Repository Secrets
# resource "github_actions_secret" "this" {
#   # ref: hhttps://registry.terraform.io/providers/integrations/github/latest/docs/resources/actions_secret
#   depends_on = [github_repository.this]
#   for_each   = var.github_actions.secrets_keys.repository

#   repository = github_repository.this.name

#   secret_name     = each.value
#   encrypted_value = var.github_actions_secrets.repository[each.key]
# }

# # Environment Variables
# resource "github_actions_environment_variable" "this" {
#   # ref: https://registry.terraform.io/providers/integrations/github/latest/docs/resources/actions_environment_variable
#   depends_on = [github_repository_environment.this]
#   for_each = {
#     for variable in local.environment_variables : "${variable.environment}_${variable.key}" => variable
#   }

#   repository    = github_repository.this.name
#   environment   = each.value.environment
#   variable_name = each.value.key
#   value         = each.value.value
# }

# # Environment Secrets
# resource "github_actions_environment_secret" "this" {
#   # ref: https://registry.terraform.io/providers/integrations/github/latest/docs/resources/actions_environment_secret
#   depends_on = [github_repository_environment.this]
#   for_each = {
#     for secret_key in local.environment_secrets : "${secret_key.environment}_${secret_key.key}" => secret_key
#   }

#   repository = github_repository.this.name

#   environment     = each.value.environment
#   secret_name     = each.value.key
#   encrypted_value = var.github_actions_secrets.environment[each.value.environment][each.value.key]
# }

# # GitHub Actions reusable workflowsをorganizationレベルで共通化する場合に設定
# resource "github_actions_repository_access_level" "this" {
#   # ref: https://registry.terraform.io/providers/integrations/github/latest/docs/resources/actions_repository_access_level
#   depends_on = [github_repository.this]

#   repository   = github_repository.this.name
#   access_level = var.github_actions.access_level
# }

# # 使用を許可するActions
# resource "github_actions_repository_permissions" "this" {
#   # ref: https://registry.terraform.io/providers/integrations/github/latest/docs/resources/actions_repository_permissions
#   depends_on = [github_repository.this]

#   repository      = github_repository.this.name
#   enabled         = true
#   allowed_actions = "selected"

#   allowed_actions_config {
#     # GitHubが提供するActionsを許可
#     github_owned_allowed = true
#     # 認定されたActionsを許可
#     verified_allowed = true
#   }
# }
