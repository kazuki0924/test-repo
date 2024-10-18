
# [ECS (Elastic Container)] - Task Definition

# symlinked from:
# - infra/terraform/{provider}/modules/{module}/{resource_group}.tf
# symlinked to:
# - src/{subdomain}/{microservice}/infra/terraform/{provider}/modules/{module}/{resource_group}.tf
# see "Override Files" on how to override this file
# https://developer.hashicorp.com/terraform/language/files/override

locals {
  task_env_file = (
    var.is_test ?
    "${path.module}/testing/.env.defaults" :
    "${var.common.repo_root}/src/.env.defaults"
  )
  destination_endpoints = {
    for vpc in local.context.vpc : vpc.name_short => {
      # the other vpc's domain
      dev  = var.api.this.domain["dev"][one(setsubtract(["main", "misc"], [vpc.name_short]))],
      test = var.api.destinations.xev_vpp_doms["test"].domain,
      stg  = var.api.destinations.xev_vpp_doms["stg"].domain,
      prod = var.api.destinations.xev_vpp_doms["prod"].domain
    }
  }
}

# .envファイルを読み込み、ContainerDefinitionのenvironmentsのJSON形式に出力するpythonスクリプトの実行
# TBD: 複数の.envファイルを読み込むようにするか否か（.env.defaultsと.env.microserviceの2つを読み込むようにする、等）
data "external" "container_def_envs_json" {
  program = ["${var.common.repo_root}/scripts/python/aws/dotenv_to_container_def_envs_json.py", local.task_env_file]
}

resource "aws_ecs_task_definition" "this" {
  # ref: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_task_definition
  for_each = {
    for task in concat(local.ecs_services, local.ecs_schedules) : "${task.vpc.name_short}-${task.name_short}" => task
  }

  # family                   = one([for cluster in local.ecs_cluster : cluster.name if cluster.vpc.name_short == each.value.vpc.name_short])
  family                   = each.value.name
  requires_compatibilities = ["FARGATE"]
  cpu                      = each.value.cpu
  memory                   = each.value.memory
  network_mode             = "awsvpc"
  execution_role_arn       = data.aws_iam_role.this["${each.value.vpc.name_short}-${each.value.iam_role.exec.name_short}"].arn
  task_role_arn            = data.aws_iam_role.this["${each.value.vpc.name_short}-${each.value.iam_role.task.name_short}"].arn

  container_definitions = jsonencode([
    {
      name = each.value.name_short
      # TODO: revert
      # image                  = "${aws_ecr_repository.this[each.value.name_short].repository_url}:${var.image_tag}"
      image                  = "python:3.13.0-bookworm"
      essential              = true
      readOnlyRootFilesystem = false
      environment = concat(
        jsondecode(data.external.container_def_envs_json.result.json),
        [
          {
            name  = "AWS_REGION"
            value = var.common.aws.region
          },
          {
            name  = "AWS_ACCOUNT_ID"
            value = local.common.aws_account_id
          },
          {
            name  = "VPC_NAME"
            value = each.value.vpc.name
          },
          {
            name  = "VPC_NAME_SHORT"
            value = each.value.vpc.name_short
          },
          {
            name  = "DEST_DOMAIN"
            value = lookup(local.destination_endpoints[each.value.vpc.name_short], var.common.env, "misc.evems.eas-ev-dev.woven-cems.com")
          },
          {
            name  = "SERVICE_DISCOVERY_DNS_NAMESPACE"
            value = "${var.common.prefix}${each.value.vpc.vpc_resource_prefix}${var.common.domain}${var.common.suffix}.internal"
          },
        ]
      )
      # TBD:
      # secrets = [
      #   {
      #     name = "NR_LICENSE_KEY"
      #     value =  "newrelic_licence_key"
      #   }
      # ]
      linuxParameters = {
        initProcessEnabled = true
      }
      portMappings = [
        {
          containerPort = each.value.container_port
          hostPort      = each.value.host_port
          protocol      = "TCP"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.this["${each.value.vpc.name_short}-${trimprefix(each.value.name_short, "${var.common.domain}-")}"].name
          "awslogs-region"        = var.common.aws.region
          "awslogs-stream-prefix" = "${each.value.name}/"
        }
      }
      healthCheck = {
        command = flatten([
          "CMD-SHELL",
          each.value.health_check_cmd,
          "http://localhost:${each.value.container_port}${each.value.health_check.path}",
          "||",
          "exit",
          "1"
        ])
        interval    = var.common.app.default.health_check.interval     # aws default: 30, variables.tf default: 30
        timeout     = var.common.app.default.health_check.timeout      # aws default: 5, variables.tf default: 20
        retries     = var.common.app.default.health_check.retries      # aws default: 3, variables.tf default: 3
        startPeriod = var.common.app.default.health_check.start_period # aws default: off, variables.tf default: 60
      }
    },
    # TBD: NewRelic sidecar container
  ])

  tags = {
    name           = each.value.taskdef.name
    Name           = each.value.taskdef.name
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
