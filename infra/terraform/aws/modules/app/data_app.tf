# symlinked from:
# - infra/terraform/{provider}/modules/{module}/{resource_group}.tf
# symlinked to:
# - src/{subdomain}/{microservice}/infra/terraform/{provider}/modules/{module}/{resource_group}.tf
# see "Override Files" on how to override this file
# https://developer.hashicorp.com/terraform/language/files/override

locals {
  subnet_groups = flatten([
    for vpc in local.context.vpc : [
      for group in vpc.subnet_groups : merge(group, { vpc = vpc })
    ]
  ])
  security_groups = flatten([
    for vpc in local.context.vpc : [
      for group in ["ecs-protected", "ecs-intra"] : merge({ name_short = group }, { vpc = vpc })
    ]
  ])
  iam_roles = flatten([
    for vpc in local.context.vpc : [
      for role in var.iam.role_names : {
        name_short = role,
        vpc        = vpc
      }
    ]
  ])
}

data "aws_vpc" "this" {
  # ref: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/vpc
  for_each = {
    for vpc in local.context.vpc : vpc.name_short => vpc
  }

  filter {
    name   = "tag:name"
    values = [each.value.name]
  }
}

data "aws_subnets" "this" {
  # ref: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/subnets
  depends_on = [data.aws_vpc.this]
  for_each = {
    for group in local.subnet_groups : "${group.vpc.name_short}-${group.group_name}" => group
  }

  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.this[each.value.vpc.name_short].id]
  }

  filter {
    name   = "tag:group_name"
    values = [each.value.group_name]
  }
}

data "aws_security_group" "this" {
  # ref: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/security_group
  depends_on = [data.aws_vpc.this]
  for_each = {
    for group in local.security_groups : "${group.vpc.name_short}-${group.name_short}" => group
  }

  tags = {
    name_short = each.value.name_short
  }

  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.this[each.value.vpc.name_short].id]
  }
}

data "aws_lb" "alb" {
  # ref: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/lb
  for_each = {
    for vpc in local.context.vpc : vpc.name_short => vpc
  }

  name = "${each.value.vpc_resource_prefix}${var.alb.resource_prefix}${var.alb.name_short}${local.common.lb.suffix}"
}

data "aws_lb_listener" "alb" {
  # ref: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/lb_listener
  for_each = {
    for vpc in local.context.vpc : vpc.name_short => vpc
  }

  load_balancer_arn = data.aws_lb.alb[each.value.name_short].arn
  port              = "443"
}

data "aws_service_discovery_dns_namespace" "this" {
  # ref: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/service_discovery_dns_namespace
  depends_on = [data.aws_vpc.this]
  for_each = {
    for vpc in local.context.vpc : vpc.name_short => vpc
  }

  name = "${var.common.prefix}${each.value.vpc_resource_prefix}${var.common.domain}${var.common.suffix}.internal"
  type = "DNS_PRIVATE"
}

data "aws_iam_role" "this" {
  # ref: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_role
  for_each = {
    for role in local.iam_roles : "${role.vpc.name_short}-${role.name_short}" => role
  }

  name = "${var.common.prefix}${each.value.vpc.vpc_resource_prefix}${var.iam.role.resource_prefix}${each.value.name_short}${var.common.suffix}"
}
