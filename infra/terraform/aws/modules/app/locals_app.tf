locals {
  app_common = {
    resources       = var.is_microservice ? var.per_microservice_resources : var.microservices_shared_resources
    resource_prefix = var.is_microservice ? "" : "${var.common.domain}-"
  }
}
