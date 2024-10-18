module "db" {
  source = "../../../modules/db"

  common          = var.common
  secrets         = var.secrets
  enum            = var.enum
  vpc             = var.vpc
  api             = var.api
  is_ci           = var.is_ci
  is_microservice = var.is_microservice
  is_test         = var.is_test

  dynamodb = var.dynamodb
}
