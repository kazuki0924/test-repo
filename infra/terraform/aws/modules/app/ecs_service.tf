
# [ECS (Elastic Container)] - Service

# symlinked from:
# - infra/terraform/{provider}/modules/{module}/{resource_group}.tf
# symlinked to:
# - src/{subdomain}/{microservice}/infra/terraform/{provider}/modules/{module}/{resource_group}.tf
# see "Override Files" on how to override this file
# https://developer.hashicorp.com/terraform/language/files/override

locals {
  ecs_services = local.app_common.resources.ecs.services != null ? flatten([
    for vpc in local.context.vpc : [
      for service in [
        for s in local.app_common.resources.ecs.services :
        s.name_short != null ?
        merge(s, { name_short = "${local.app_common.resource_prefix}${s.name_short}" }) :
        merge(s, { name_short = var.common.microservice })
      ] :
      merge(service, {
        name = "${var.common.prefix}${vpc.vpc_resource_prefix}${var.ecs.service.resource_prefix}${service.name_short}${var.common.suffix}"
        taskdef = {
          name = "${var.common.prefix}${vpc.vpc_resource_prefix}${var.ecs.taskdef.resource_prefix}${service.name_short}${var.common.suffix}"
        }
        vpc = vpc
      })
    ]
  ]) : []
}

resource "aws_service_discovery_service" "this" {
  # ref: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/service_discovery_service
  depends_on = [data.aws_service_discovery_dns_namespace.this]
  for_each = {
    for service in local.ecs_services : "${service.vpc.name_short}-${service.name_short}" => service
  }

  # Note: aws_service_discovery_dns_namespace.this.name is "${var.common.prefix}${vpc.vpc_resource_prefix}${var.common.domain}${var.common.suffix}.internal"
  # e.g. DNS Name: fleet-control-stub-intra-api.xev-vpp-evems-dev-main-fleet-control.internal
  # to test: dig fleet-control-stub-intra-api.xev-vpp-evems-dev-main-fleet-control.internal
  name        = each.value.name_short
  description = "Cloud Map Service Discovery Service managed by terraform"

  dns_config {
    namespace_id   = data.aws_service_discovery_dns_namespace.this[each.value.vpc.name_short].id
    routing_policy = "MULTIVALUE"

    dns_records {
      ttl  = 10
      type = "A"
    }
  }

  health_check_custom_config {
    failure_threshold = 1
  }

  tags = {
    name           = each.value.name_short
    Name           = each.value.name_short
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

resource "aws_ecs_service" "this" {
  # ref: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_service
  depends_on = [data.aws_subnets.this, aws_ecs_task_definition.this, aws_service_discovery_service.this]
  for_each = {
    for service in local.ecs_services : "${service.vpc.name_short}-${service.name_short}" => service
  }

  name                               = each.value.name
  cluster                            = local.ecs_cluster_id[each.value.vpc.name_short]
  task_definition                    = aws_ecs_task_definition.this["${each.value.vpc.name_short}-${each.value.name_short}"].arn
  platform_version                   = "LATEST"
  launch_type                        = "FARGATE"
  propagate_tags                     = "TASK_DEFINITION"
  enable_execute_command             = lookup(var.ecs.service.enable_execute_command, var.common.env, false)
  enable_ecs_managed_tags            = true
  desired_count                      = 1
  deployment_maximum_percent         = 200
  deployment_minimum_healthy_percent = 100
  scheduling_strategy                = "REPLICA"
  force_delete                       = lookup(var.ecs.service.force_delete, var.common.env, false)
  force_new_deployment               = lookup(var.ecs.service.force_new_deployment, var.common.env, false)
  # TODO: revert
  # wait_for_steady_state              = true
  health_check_grace_period_seconds = lookup(var.ecs.service.health_check_grace_period_seconds, var.common.env, 60)

  service_registries {
    registry_arn   = aws_service_discovery_service.this["${each.value.vpc.name_short}-${each.value.name_short}"].arn
    container_name = each.value.name_short
  }

  deployment_controller {
    type = "ECS"
  }

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  network_configuration {
    subnets          = flatten([for group in each.value.subnet_groups : data.aws_subnets.this["${each.value.vpc.name_short}-${group.group_name}"].ids])
    security_groups  = flatten([for sg in each.value.security_groups : data.aws_security_group.this["${each.value.vpc.name_short}-${sg.name_short}"].id])
    assign_public_ip = false
  }

  dynamic "load_balancer" {
    for_each = anytrue([for sg in each.value.security_groups : true if sg.name_short == "ecs-intra"]) ? [1] : []

    content {
      target_group_arn = aws_lb_target_group.alb["${each.value.vpc.name_short}-${trimprefix(each.value.name_short, "${var.common.domain}-")}"].arn
      container_name   = each.value.name_short
      container_port   = each.value.container_port
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
      desired_count,
      # ecspressoでのデプロイ時にtask_definitionが変更されるため、変更を無視する
      task_definition,
      tags["created_at"],
      tags["created_date"]
    ]
  }

  timeouts {
    create = var.ecs.service.timeouts[var.common.env].create
    update = var.ecs.service.timeouts[var.common.env].update
    delete = var.ecs.service.timeouts[var.common.env].delete
  }
}
