# ref: https://developer.hashicorp.com/terraform/language/providers/configuration
provider "github" {
  # ref: https://registry.terraform.io/providers/integrations/github/latest/docs
  token = var.secrets.github.token
  owner = var.common.github.org
}
