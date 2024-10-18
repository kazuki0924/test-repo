# [IAM (Identity & Access Management)]

# vpc, vpc_endpointの値を参照するIAMの作成

locals {
  statements = {
    logs = [
      {
        sid    = "AllowLogs"
        effect = "Allow"
        actions = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams"
        ]
        resources = ["arn:aws:logs:${var.common.aws.region}:${local.common.aws_account_id}:log-group:/aws/ecs/*"]
      },
      {
        sid       = "AllowLogsDescribeLogGroups"
        effect    = "Allow"
        actions   = ["logs:DescribeLogGroups"]
        resources = ["*"]
      },
    ]
  }
  iam = {
    policies = flatten([
      for vpc in local.context.vpc : [
        for policy in [
          {
            name_short  = "ecs-task-default"
            description = "Default ECS Task Role Policy"
            statements = flatten(
              [
                local.statements.logs,
                {
                  sid    = "AllowDynamoDB"
                  effect = "Allow"
                  actions = [
                    "dynamodb:BatchGetItem",
                    "dynamodb:BatchWriteItem",
                    "dynamodb:PutItem",
                    "dynamodb:DeleteItem",
                    "dynamodb:GetItem",
                    "dynamodb:Scan",
                    "dynamodb:Query",
                    "dynamodb:UpdateItem"
                  ]
                  resources = ["arn:aws:dynamodb:${var.common.aws.region}:${local.common.aws_account_id}:table/*"]
                }
              ]
            )
          },
          {
            name_short  = "ecs-exec-default"
            description = "Default ECS Task-Exec Role Policy"
            statements = flatten(
              [
                {
                  sid    = "AllowECSExec"
                  effect = "Allow"
                  actions = [
                    "ssmmessages:CreateControlChannel",
                    "ssmmessages:CreateDataChannel",
                    "ssmmessages:OpenControlChannel",
                    "ssmmessages:OpenDataChannel"
                  ]
                  resources = ["arn:aws:ecs:${var.common.aws.region}:${local.common.aws_account_id}:task/*"]
                },
                {
                  sid       = "AllowECRGetAuthorizationToken"
                  effect    = "Allow"
                  actions   = ["ecr:GetAuthorizationToken"]
                  resources = ["*"]
                  conditions = [
                    {
                      test     = "StringEquals"
                      variable = "aws:SourceVpce"
                      values   = [aws_vpc_endpoint.this["${vpc.name_short}-ecr-api"].id]
                    },
                    {
                      test     = "StringEquals"
                      variable = "aws:SourceVpc"
                      values   = [aws_vpc.this[vpc.name_short].id]
                    }
                  ]
                },
                {
                  sid    = "AllowECR"
                  effect = "Allow"
                  actions = [
                    "ecr:GetDownloadUrlForLayer",
                    "ecr:BatchCheckLayerAvailability",
                    "ecr:BatchGetImage"
                  ]
                  resources = ["*"]
                  conditions = [
                    {
                      test     = "StringEquals"
                      variable = "aws:SourceVpce"
                      values   = [aws_vpc_endpoint.this["${vpc.name_short}-ecr-dkr"].id]
                    },
                    {
                      test     = "StringEquals"
                      variable = "aws:SourceVpc"
                      values   = [aws_vpc.this[vpc.name_short].id]
                    }
                  ]
                },
                {
                  sid    = "AllowForContainerInsights"
                  effect = "Allow"
                  actions = [
                    "events:PutRule",
                    "events:PutTargets",
                    "logs:CreateLogGroup"
                  ]
                  resources = ["*"]
                },
                {
                  sid    = "AllowForECSLifecycleEvents"
                  effect = "Allow"
                  actions = [
                    "events:DescribeRule",
                    "events:ListTargetsByRule"
                  ]
                  resources = ["*"]
                }
              ]
            )
          },
          {
            name_short  = "scheduler-default"
            description = "Default Scheduler Role Policy"
            statements = [
              {
                sid    = "AllowScheduler"
                effect = "Allow"
                actions = [
                  "ecs:RunTask",
                  "ecs:DescribeTasks",
                  "ec2:DescribeNetworkInterfaces",
                  "logs:CreateLogStream",
                  "logs:PutLogEvents",
                  "lambda:InvokeFunction"
                ]
                resources = [
                  "arn:aws:ecs:${var.common.aws.region}:${local.common.aws_account_id}:*",
                  "arn:aws:iam::${local.common.aws_account_id}:role/*"
                ]
              }
            ]
          },
          {
            name_short  = "ecs-assume-role"
            description = "ECS Assume Role Policy"
            statements = [
              {
                sid     = "AssumeECSTasks"
                effect  = "Allow"
                actions = ["sts:AssumeRole"]
                principals = [
                  {
                    type        = "Service"
                    identifiers = ["ecs-tasks.amazonaws.com"]
                  }
                ]
              },
            ]
          },
          {
            name_short  = "scheduler-assume-role"
            description = "Scheduler Assume Role Policy"
            statements = [
              {
                sid     = "AssumeScheduler"
                effect  = "Allow"
                actions = ["sts:AssumeRole"]
                principals = [
                  {
                    type        = "Service"
                    identifiers = ["scheduler.amazonaws.com"]
                  }
                ]
              }
            ]
          }
        ] :
        merge(
          policy, {
            name = "${var.common.prefix}${vpc.vpc_resource_prefix}${var.iam.policy.resource_prefix}${policy.name_short}${var.common.suffix}"
            vpc  = vpc
          }
        )
      ]
    ])
    roles = flatten([
      for vpc in local.context.vpc : [
        for role in [
          {
            name_short         = "ecs-task-default"
            description        = "Default ECS Task Role"
            assume_role_policy = "ecs-assume-role"
            policies = [
              { name_short = "ecs-task-default" }
            ],
          },
          {
            name_short         = "ecs-exec-default"
            description        = "Default ECS Task Execution Role"
            assume_role_policy = "ecs-assume-role"
            managed_policies = [
              {
                name_short = "AmazonECSTaskExecutionRolePolicy"
                arn        = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy",
              }
            ]
            policies = [
              { name_short = "ecs-exec-default" }
            ],
          },
          {
            name_short         = "scheduler-default"
            description        = "Default Scheduler Role"
            assume_role_policy = "scheduler-assume-role"
            policies = [
              { name_short = "scheduler-default" }
            ],
          },
        ] :
        merge(
          role, {
            name = "${var.common.prefix}${vpc.vpc_resource_prefix}${var.iam.role.resource_prefix}${role.name_short}${var.common.suffix}"
            vpc  = vpc
          }
        )
      ]
    ])
  }
  role_policy_attachments = flatten([
    for role in local.iam.roles : [
      for policy in concat(role.policies, try(role.managed_policies, [])) : {
        role   = role
        policy = policy
        vpc    = try(role.vpc, policy.vpc)
      }
    ]
  ])
}

data "aws_iam_policy_document" "this" {
  # ref: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document
  for_each = {
    for policy in local.iam.policies : "${policy.vpc.name_short}-${policy.name_short}" => policy
  }

  version = "2012-10-17"

  dynamic "statement" {
    for_each = each.value.statements
    content {
      sid       = statement.value.sid
      effect    = statement.value.effect
      actions   = statement.value.actions
      resources = try(statement.value.resources, null)

      dynamic "principals" {
        for_each = try(statement.value.principals, [])

        content {
          type        = principals.value.type
          identifiers = principals.value.identifiers
        }
      }

      dynamic "condition" {
        for_each = try(statement.value.conditions, [])

        content {
          test     = condition.value.test
          variable = condition.value.variable
          values   = condition.value.values
        }
      }
    }
  }
}

resource "aws_iam_policy" "this" {
  # ref: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy
  depends_on = [data.aws_iam_policy_document.this]
  for_each = {
    for policy in local.iam.policies : "${policy.vpc.name_short}-${policy.name_short}" => policy
    if !strcontains(policy.name_short, "assume-role")
  }

  name        = each.value.name
  description = each.value.description
  policy      = data.aws_iam_policy_document.this["${each.value.vpc.name_short}-${each.value.name_short}"].json

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

resource "aws_iam_role" "this" {
  # ref: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role
  depends_on = [data.aws_iam_policy_document.this]
  for_each = {
    for role in local.iam.roles : "${role.vpc.name_short}-${role.name_short}" => role
  }

  name               = each.value.name
  assume_role_policy = data.aws_iam_policy_document.this["${each.value.vpc.name_short}-${each.value.assume_role_policy}"].json

  tags = {
    name           = each.value.name
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

resource "aws_iam_role_policy_attachment" "this" {
  # ref: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment
  depends_on = [aws_iam_policy.this, aws_iam_role.this]
  for_each = {
    for attachment in local.role_policy_attachments : "${attachment.vpc.name_short}-${attachment.role.name_short}-${attachment.policy.name_short}" => attachment
  }

  role       = aws_iam_role.this["${each.value.vpc.name_short}-${each.value.role.name_short}"].name
  policy_arn = try(aws_iam_policy.this["${each.value.vpc.name_short}-${each.value.policy.name_short}"].arn, each.value.policy.arn, null)
}
