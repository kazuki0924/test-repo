locals {
  common = {
    aws_account_id = data.aws_caller_identity.current.account_id
    lb = {
      suffix = var.is_test ? "-dm" : var.common.suffix
    }
  }
  context = {
    vpc = [
      for vpc in var.vpc : merge(vpc, {
        name       = "${var.common.prefix}${vpc.resource_prefix}${vpc.name_short}${var.common.suffix}"
        cidr_block = "${vpc.cidr.network_address}/${vpc.cidr.prefix}"
        route_table = merge(vpc.route_table, {
          name = "${var.common.prefix}${vpc.vpc_resource_prefix}${vpc.route_table.name_short}${var.common.suffix}"
        })
      })
    ]
  }
  ecs_cluster = [
    for cluster in [
      for vpc in local.context.vpc : {
        name_short = coalesce(var.ecs.cluster.name_short, var.common.domain)
        vpc        = vpc
      }
    ] :
    merge(cluster,
      { name = "${var.common.prefix}${cluster.vpc.vpc_resource_prefix}${var.ecs.cluster.resource_prefix}${cluster.name_short}${var.common.suffix}" }
    )
  ]
}
