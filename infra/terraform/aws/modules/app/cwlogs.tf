# [Cloud Watch Logs]

# symlinked from:
# - infra/terraform/{provider}/modules/{module}/{resource_group}.tf
# symlinked to:
# - src/{subdomain}/{microservice}/infra/terraform/{provider}/modules/{module}/{resource_group}.tf
# see "Override Files" on how to override this file
# https://developer.hashicorp.com/terraform/language/files/override

locals {
  log_groups = flatten([
    for vpc in local.context.vpc : [
      for lg in [
        for g in local.app_common.resources.cwlogs.log_groups :
        g.name_short != null ?
        g :
        merge(g, { name_short = var.common.microservice })
      ] :
      merge(lg, {
        name = "${var.common.prefix}${vpc.vpc_resource_prefix}${var.cwlogs.log_group.resource_prefix}${lg.name_short}${var.common.suffix}"
        vpc  = vpc
      })
    ]
  ])
}

resource "aws_cloudwatch_log_group" "this" {
  # ref: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group
  for_each = {
    for lg in local.log_groups : "${lg.vpc.name_short}-${lg.name_short}" => lg
  }

  name              = each.value.name
  retention_in_days = var.cwlogs.retention_in_days # e.g. 731

  tags = {
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
