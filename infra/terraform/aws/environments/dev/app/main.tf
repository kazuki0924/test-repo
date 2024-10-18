module "app" {
  source = "../../../modules/app"

  # variables_common.tf
  common          = var.common
  secrets         = var.secrets
  enum            = var.enum
  vpc             = var.vpc
  alb             = var.alb
  ecs             = var.ecs
  iam             = var.iam
  api             = var.api
  is_ci           = var.is_ci
  is_microservice = var.is_microservice
  is_test         = var.is_test

  # variables_{module}.tf
  per_microservice_resources     = var.per_microservice_resources
  microservices_shared_resources = var.microservices_shared_resources
  scheduler                      = var.scheduler
  ecr                            = var.ecr
  cwlogs                         = var.cwlogs
  image_tag                      = var.image_tag
}
