module "init" {
  source = "../../../modules/init"

  common          = var.common
  secrets         = var.secrets
  enum            = var.enum
  vpc             = var.vpc
  api             = var.api
  is_ci           = var.is_ci
  is_microservice = var.is_microservice
  is_test         = var.is_test

  github        = var.github
  oidc_provider = var.oidc_provider
  s3            = var.s3
  dynamodb      = var.dynamodb
  kms           = var.kms
}
