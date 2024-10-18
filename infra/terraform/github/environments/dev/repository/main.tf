module "repository" {
  source  = "../../../modules/repository"
  common  = var.common
  secrets = var.secrets

  repository     = var.repository
  github_actions = var.github_actions
}
