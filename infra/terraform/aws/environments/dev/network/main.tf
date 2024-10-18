module "network" {
  source = "../../../modules/network"

  common          = var.common
  secrets         = var.secrets
  enum            = var.enum
  vpc             = var.vpc
  alb             = var.alb
  api             = var.api
  is_ci           = var.is_ci
  is_microservice = var.is_microservice
  is_test         = var.is_test

  nlb     = var.nlb
  route53 = var.route53
}
