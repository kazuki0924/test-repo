locals {
  service_discovery = {
    for vpc in local.context.vpc : vpc.name_short => {
      namespace  = "${var.common.prefix}${vpc.vpc_resource_prefix}${var.common.domain}${var.common.suffix}.internal"
      name       = "${var.common.prefix}${vpc.vpc_resource_prefix}${var.common.domain}${var.common.suffix}"
      name_short = var.common.domain
      vpc        = vpc
    }
  }
}

resource "aws_service_discovery_private_dns_namespace" "this" {
  # ref: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/service_discovery_private_dns_namespace
  depends_on = [aws_vpc.this]
  for_each   = local.service_discovery

  name        = each.value.namespace
  description = "service discovery for ecs services"
  vpc         = aws_vpc.this[each.value.vpc.name_short].id

  tags = {
    namespace      = each.value.namespace
    name           = each.value.name
    Name           = each.value.name
    name_short     = each.value.name_short
    vpc_name       = each.value.vpc.name
    vpc_name_short = each.value.vpc.name_short
  }

  lifecycle {
    ignore_changes = [
      tags["created_at"],
      tags["created_date"]
    ]
  }
}
