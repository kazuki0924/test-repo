# [ECS (Elastic Container)] - Cluster

resource "aws_ecs_cluster" "this" {
  # ref: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_cluster
  depends_on = [aws_cloudwatch_log_group.this]
  for_each = {
    for cluster in local.ecs_cluster : cluster.vpc.name_short => cluster
  }

  name = each.value.name

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  configuration {
    execute_command_configuration {
      # default AWS managed key
      # kms_key_id = null
      logging = "OVERRIDE"
      log_configuration {
        cloud_watch_log_group_name     = aws_cloudwatch_log_group.this["${each.value.vpc.name_short}-${var.ecs.cluster.cwlogs.execute_command.name_short}"].name
        cloud_watch_encryption_enabled = true
      }
    }
  }

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

resource "aws_ecs_cluster_capacity_providers" "this" {
  # ref: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_cluster_capacity_providers
  depends_on = [aws_ecs_cluster.this]
  for_each   = aws_ecs_cluster.this

  cluster_name       = each.value.name
  capacity_providers = [lookup(var.ecs.cluster.capacity_provider, var.common.env, "FARGATE")]

  default_capacity_provider_strategy {
    capacity_provider = lookup(var.ecs.cluster.capacity_provider, var.common.env, "FARGATE")
    base              = 0
    weight            = 100
  }
}
