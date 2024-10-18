locals {
  ecs_cluster_id = {
    for vpc in local.context.vpc : vpc.name_short => aws_ecs_cluster.this[vpc.name_short].arn
  }
}
