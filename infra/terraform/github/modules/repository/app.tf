# resource "github_app_installation_repositories" "this" {
#   # ref: https://registry.terraform.io/providers/integrations/github/latest/docs/resources/app_installation_repositories
#   for_each = {
#     for app in var.github_apps : app.id => app if lower(var.is_ci) != "true"
#   }

#   installation_id       = each.value.installation_id
#   selected_repositories = [github_repository.this.name]
# }
