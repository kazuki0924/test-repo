# [ELB (Elastic Load Balancing)] - Application Load Balancer - app module

# symlinked from:
# - infra/terraform/{provider}/modules/{module}/{resource_group}.tf
# symlinked to:
# - src/{subdomain}/{microservice}/infra/terraform/{provider}/modules/{module}/{resource_group}.tf
# see "Override Files" on how to override this file
# https://developer.hashicorp.com/terraform/language/files/override

# microservice specific resources and test api ALB resources

# マイクロサービス毎となるリソース、及びE2Eテスト用のALBリソースを配置
# マイクロサービス共通となるALBリソースは、./infra/terraform/aws/modules/network/elb.tfに配置

locals {
  alb = {
    target_groups = flatten([
      for vpc in local.context.vpc : [
        for tg in [
          for g in local.app_common.resources.alb.target_groups :
          g.name_short != null ?
          g :
          merge(g, { name_short = var.common.microservice })
        ] :
        merge(tg, {
          # name cannot be longer than 32 characters
          name = "${vpc.vpc_resource_prefix}${var.alb.target_group.resource_prefix}${tg.name_short}${local.common.lb.suffix}"
          vpc  = vpc
        })
      ]
    ])
    listener_rules = flatten([
      for vpc in local.context.vpc : [
        for rule in [
          for r in local.app_common.resources.alb.listener_rules :
          r.name_short != null ?
          r :
          merge(r, { name_short = var.common.microservice })
        ] :
        merge(rule, {
          name       = "${var.common.prefix}${vpc.vpc_resource_prefix}${var.alb.listener_rule.resource_prefix}${rule.name_short}${var.common.suffix}"
          name_short = "${local.app_common.resource_prefix}${rule.name_short}"
          tg = {
            name_short = rule.name_short
          }
          vpc = vpc
        })
      ]
    ])
  }
}

resource "aws_lb_target_group" "alb" {
  # ref: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_target_group
  depends_on = [data.aws_vpc.this]
  for_each = {
    for tg in local.alb.target_groups : "${tg.vpc.name_short}-${tg.name_short}" => tg
  }

  name              = each.value.name
  port              = coalesce(each.value.port, 8000)
  protocol          = "HTTPS"
  target_type       = "ip"
  proxy_protocol_v2 = false
  vpc_id            = data.aws_vpc.this[each.value.vpc.name_short].id

  health_check {
    port                = "traffic-port"
    path                = each.value.health_check.path                            # aws default: "/", variables.tf default: "/health"
    protocol            = var.common.app.default.health_check.protocol            # aws default: "HTTP", variables.tf default: "HTTPS"
    matcher             = var.common.app.default.health_check.matcher             # aws default: "200", variables.tf default: "200"
    interval            = var.common.app.default.health_check.interval            # aws default: 30, variables.tf default: 30
    timeout             = var.common.app.default.health_check.timeout             # aws default: 5, variables.tf default: 20
    healthy_threshold   = var.common.app.default.health_check.healthy_threshold   # aws default: 3, variables.tf default: 3
    unhealthy_threshold = var.common.app.default.health_check.unhealthy_threshold # aws default: 3, variables.tf default: 3
  }

  tags = {
    name                = each.value.name
    Name                = each.value.name
    name_before_trimmed = "${var.common.prefix}${each.value.vpc.vpc_resource_prefix}${var.alb.target_group.resource_prefix}${each.value.name_short}${var.common.suffix}"
    name_short          = each.value.name_short
    vpc_name            = each.value.vpc.name
    vpc_name_short      = each.value.vpc.name_short
  }

  lifecycle {
    ignore_changes = [
      tags["created_at"],
      tags["created_date"]
    ]
  }
}

resource "aws_lb_listener_rule" "alb" {
  # ref: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener_rule
  depends_on = [data.aws_lb_listener.alb, aws_lb_target_group.alb]
  for_each = {
    for rule in local.alb.listener_rules : "${rule.vpc.name_short}-${rule.name_short}" => rule
  }

  listener_arn = data.aws_lb_listener.alb[each.value.vpc.name_short].arn

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alb["${each.value.vpc.name_short}-${each.value.tg.name_short}"].arn
  }

  condition {
    path_pattern {
      values = [each.value.path_pattern] # e.g. "/dummy_endpoint", "/api/v1/resourcePath*"
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
