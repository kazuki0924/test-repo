# [EventBridge Scheduler]

# symlinked from:
# - infra/terraform/{provider}/modules/{module}/{resource_group}.tf
# symlinked to:
# - src/{subdomain}/{microservice}/infra/terraform/{provider}/modules/{module}/{resource_group}.tf
# see "Override Files" on how to override this file
# https://developer.hashicorp.com/terraform/language/files/override

locals {
  ecs_schedules = local.app_common.resources.ecs.schedules != null ? flatten([
    for vpc in local.context.vpc : [
      for schedule in [
        for s in local.app_common.resources.ecs.schedules :
        s.name_short != null ?
        s :
        merge(s, { name_short = var.common.microservice })
      ] :
      merge(schedule, {
        name = "${var.common.prefix}${vpc.vpc_resource_prefix}${var.scheduler.schedule.resource_prefix}${schedule.name_short}${var.common.suffix}"
        # name cannot be longer than 64 characters
        group = {
          name = "${var.common.subsystem}-${vpc.vpc_resource_prefix}${var.scheduler.group.resource_prefix}${schedule.name_short}${var.common.suffix}"
        }
        taskdef = {
          name = "${var.common.prefix}${vpc.vpc_resource_prefix}${var.ecs.taskdef.resource_prefix}${schedule.name_short}${var.common.suffix}"
        }
        vpc = vpc
      })
    ]
  ]) : []
}

resource "aws_scheduler_schedule_group" "this" {
  # ref: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/scheduler_schedule_group
  for_each = {
    for schedule in local.ecs_schedules : "${schedule.vpc.name_short}-${schedule.name_short}" => schedule
  }

  name = each.value.group.name

  tags = {
    name           = each.value.group.name
    Name           = each.value.group.name
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

  timeouts {
    create = var.scheduler.timeouts[var.common.env].create
    delete = var.scheduler.timeouts[var.common.env].delete
  }
}

resource "aws_scheduler_schedule" "this" {
  # ref: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/scheduler_schedule
  depends_on = [aws_scheduler_schedule_group.this, data.aws_iam_role.this]
  for_each = {
    for schedule in local.ecs_schedules : "${schedule.vpc.name_short}-${schedule.name_short}" => schedule
  }

  name                         = each.value.name
  description                  = each.value.description
  state                        = "ENABLED"
  start_date                   = null
  end_date                     = var.is_test ? timeadd(timestamp(), "12h") : null
  group_name                   = each.value.group.name
  kms_key_arn                  = null # use default AWS managed key
  schedule_expression          = each.value.schedule_expression
  schedule_expression_timezone = each.value.schedule_expression_timezone

  flexible_time_window {
    mode = "OFF"
  }

  target {
    arn      = local.ecs_cluster_id[each.value.vpc.name_short]
    role_arn = data.aws_iam_role.this["${each.value.vpc.name_short}-${each.value.iam_role.exec.name_short}"].arn

    ecs_parameters {
      group                   = each.value.group.name
      task_count              = 1
      task_definition_arn     = aws_ecs_task_definition.this["${each.value.vpc.name_short}-${each.value.name_short}"].arn
      platform_version        = "LATEST"
      launch_type             = "FARGATE"
      propagate_tags          = "TASK_DEFINITION"
      enable_execute_command  = lookup(var.scheduler.enable_execute_command, var.common.env, false)
      enable_ecs_managed_tags = true

      network_configuration {
        subnets          = flatten([for group in each.value.subnet_groups : data.aws_subnets.this["${each.value.vpc.name_short}-${group.group_name}"].ids])
        security_groups  = flatten([for sg in each.value.security_groups : data.aws_security_group.this["${each.value.vpc.name_short}-${sg.name_short}"].id])
        assign_public_ip = false
      }
    }

    retry_policy {
      maximum_event_age_in_seconds = lookup(var.scheduler.maximum_event_age_in_seconds, var.common.env, 86400)
      maximum_retry_attempts       = lookup(var.scheduler.maximum_retry_attempts, var.common.env, 10)
    }
  }
}
