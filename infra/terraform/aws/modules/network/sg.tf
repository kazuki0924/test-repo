locals {
  cidr_blocks = {
    for vpc in local.context.vpc : vpc.name_short => {
      self      = "${vpc.cidr.network_address}/${vpc.cidr.prefix}"
      intra     = "${vpc.cidr.network_address}/${one([for group in vpc.subnet_groups : group.cidr.prefix if group.group_name == "intra"])}"
      protected = "${vpc.cidr.network_address}/${one([for group in vpc.subnet_groups : group.cidr.prefix if group.group_name == "protected"])}"
    }
  }
  destinations = {
    for vpc in local.context.vpc : vpc.name_short => {
      dev = {
        ingress = [
          {
            resource_prefix = "sg-ingress-"
            name_short      = "allow-tcp-ingress-traffics-from-e2e-testing-vpc"
            description     = "Allow TCP ingress traffics from E2E Testing VPC"
            from_port       = 443
            to_port         = 443
            ip_protocol     = "TCP"
            # cidr_blocks of the opposing vpc in e2e test
            cidr_blocks = ["${data.aws_vpc.this[one(setsubtract(["main", "misc"], [vpc.name_short]))].cidr_block}"]
          }
        ]
        egress = [
          {
            resource_prefix = "sg-egress-"
            name_short      = "allow-tcp-egress-traffics-to-e2e-testing-vpc"
            description     = "Allow TCP egress traffics to E2E Testing VPC"
            from_port       = 443
            to_port         = 443
            ip_protocol     = "TCP"
            # cidr_blocks of the opposing vpc in e2e test
            cidr_blocks = ["${data.aws_vpc.this[one(setsubtract(["main", "misc"], [vpc.name_short]))].cidr_block}"]
          }
        ]
      },
      test = {
        ingress = [
          {
            resource_prefix = "sg-ingress-"
            name_short      = "allow-tcp-ingress-traffics-from-xev-vpp-doms"
            description     = "Allow TCP ingress traffics from xev-vpp-doms"
            from_port       = 443
            to_port         = 443
            ip_protocol     = "TCP"
            cidr_blocks     = var.api.destinations.xev_vpp_doms.test.cidr_blocks
          }
        ]
        egress = [
          {
            resource_prefix = "sg-egress-"
            name_short      = "allow-tcp-egress-traffics-to-xev-vpp-doms"
            description     = "Allow TCP egress traffics to xev-vpp-doms"
            from_port       = 443
            to_port         = 443
            ip_protocol     = "TCP"
            cidr_blocks     = var.api.destinations.xev_vpp_doms.test.cidr_blocks
          }
        ]
      },
      stg = {
        ingress = [
          {
            resource_prefix = "sg-ingress-"
            name_short      = "allow-tcp-ingress-traffics-from-xev-vpp-doms"
            description     = "Allow TCP ingress traffics from xev-vpp-doms"
            from_port       = 443
            to_port         = 443
            ip_protocol     = "TCP"
            cidr_blocks     = var.api.destinations.xev_vpp_doms.stg.cidr_blocks
          }
        ]
        egress = [
          {
            resource_prefix = "sg-egress-"
            name_short      = "allow-tcp-egress-traffics-to-xev-vpp-doms"
            description     = "Allow TCP egress traffics to xev-vpp-doms"
            from_port       = 443
            to_port         = 443
            ip_protocol     = "TCP"
            cidr_blocks     = var.api.destinations.xev_vpp_doms.stg.cidr_blocks
          }
        ]
      },
      prod = {
        ingress = [
          {
            resource_prefix = "sg-ingress-"
            name_short      = "allow-tcp-ingress-traffics-from-xev-vpp-doms"
            description     = "Allow TCP ingress traffics from xev-vpp-doms"
            from_port       = 443
            to_port         = 443
            ip_protocol     = "TCP"
            cidr_blocks     = var.api.destinations.xev_vpp_doms.prod.cidr_blocks
          }
        ]
        egress = [
          {
            resource_prefix = "sg-egress-"
            name_short      = "allow-tcp-egress-traffics-to-xev-vpp-doms"
            description     = "Allow TCP egress traffics to xev-vpp-doms"
            from_port       = 443
            to_port         = 443
            ip_protocol     = "TCP"
            cidr_blocks     = var.api.destinations.xev_vpp_doms.prod.cidr_blocks
          }
        ]
      },
    }
  }
  security_groups = flatten([
    for vpc in local.context.vpc : [
      for sg in [
        {
          resource_prefix = "sg-"
          name_short      = "nlb"
          description     = "Security group for NLB"
          egress = concat(
            [
              {
                resource_prefix = "sg-egress-"
                name_short      = "allow-tcp-egress-traffics-to-vpc"
                description     = "Allow TCP egress traffics to VPC"
                to_port         = 443
                from_port       = 443
                ip_protocol     = "TCP"
                cidr_blocks     = [local.cidr_blocks[vpc.name_short].self]
              },
            ],
            local.destinations[vpc.name_short][var.common.env].egress
          )
          ingress = concat(
            [
              {
                resource_prefix = "sg-ingress-"
                name_short      = "allow-tcp-ingress-traffic-from-vpc"
                description     = "Allow TCP ingress traffic from VPC"
                from_port       = 443
                to_port         = 443
                ip_protocol     = "TCP"
                cidr_blocks     = [local.cidr_blocks[vpc.name_short].self]
              },
            ],
            local.destinations[vpc.name_short][var.common.env].ingress
          )
          vpc = vpc,
        },
        {
          resource_prefix = "sg-"
          name_short      = "alb"
          description     = "Security group for ALB"
          egress = concat(
            [
              {
                resource_prefix = "sg-egress-"
                name_short      = "allow-tcp-egress-traffics-to-intra"
                description     = "Allow TCP egress traffics to intra subnets"
                to_port         = 443
                from_port       = 443
                ip_protocol     = "TCP"
                cidr_blocks     = [local.cidr_blocks[vpc.name_short].intra]
              },
            ],
            local.destinations[vpc.name_short][var.common.env].egress
          )
          ingress = concat(
            [
              {
                resource_prefix           = "sg-ingress-"
                name_short                = "allow-tcp-ingress-traffic-from-nlb"
                description               = "Allow TCP ingress traffic from NLB"
                from_port                 = 443
                to_port                   = 443
                ip_protocol               = "TCP"
                referenced_security_group = { name_short = "nlb" }
              },
            ],
            local.destinations[vpc.name_short][var.common.env].ingress
          )
          vpc = vpc,
        },
        {
          resource_prefix = "sg-"
          name_short      = "ecs-intra"
          description     = "Security group for ECS tasks in intra subnets"
          egress = concat(
            [
              {
                resource_prefix = "sg-egress-"
                name_short      = "allow-tcp-egress-traffics-to-vpc"
                description     = "Allow TCP egress traffics to VPC"
                to_port         = 443
                from_port       = 443
                ip_protocol     = "TCP"
                cidr_blocks     = [local.cidr_blocks[vpc.name_short].self]
              },
            ],
            local.destinations[vpc.name_short][var.common.env].egress
          )
          ingress = concat(
            [
              {
                resource_prefix           = "sg-ingress-"
                name_short                = "allow-tcp-traffics-from-protected"
                description               = "Allow TCP ingress traffics from protected subnets"
                from_port                 = 443
                to_port                   = 443
                ip_protocol               = "TCP"
                referenced_security_group = { name_short = "ecs-protected" }
              },
              {
                resource_prefix           = "sg-ingress-"
                name_short                = "allow-tcp-traffics-from-alb"
                description               = "Allow TCP ingress traffics from ALB"
                from_port                 = 443
                to_port                   = 443
                ip_protocol               = "TCP"
                referenced_security_group = { name_short = "alb" }
              }
            ],
            local.destinations[vpc.name_short][var.common.env].ingress
          )
          vpc = vpc,
        },
        {
          resource_prefix = "sg-"
          name_short      = "ecs-protected"
          description     = "Security group for ECS tasks in protected subnets"
          egress = [
            {
              resource_prefix = "sg-egress-"
              name_short      = "allow-tcp-egress-traffics-to-vpc"
              description     = "Allow TCP egress traffics to VPC"
              to_port         = 443
              from_port       = 443
              ip_protocol     = "TCP"
              cidr_blocks     = [local.cidr_blocks[vpc.name_short].self]
            },
          ],
          ingress = [
            {
              resource_prefix           = "sg-ingress-"
              name_short                = "allow-tcp-traffics-from-intra"
              description               = "Allow TCP ingress traffics from intra subnets"
              from_port                 = 443
              to_port                   = 443
              ip_protocol               = "TCP"
              referenced_security_group = { name_short = "ecs-intra" }
            },
          ],
          vpc = vpc,
        },
        {
          resource_prefix = "sg-"
          name_short      = "vpce"
          description     = "Security group for VPC Endpoints"
          egress = concat(
            [
              {
                resource_prefix = "sg-egress-"
                name_short      = "allow-tcp-egress-traffics-to-vpc"
                description     = "Allow TCP egress traffics to VPC"
                to_port         = 443
                from_port       = 443
                ip_protocol     = "TCP"
                cidr_blocks     = [local.cidr_blocks[vpc.name_short].self]
              },
            ],
            local.destinations[vpc.name_short][var.common.env].egress
          )
          ingress = concat(
            [
              {
                resource_prefix           = "sg-ingress-"
                name_short                = "allow-tcp-traffics-from-intra"
                description               = "Allow TCP ingress traffics from intra subnets"
                from_port                 = 443
                to_port                   = 443
                ip_protocol               = "TCP"
                referenced_security_group = { name_short = "ecs-intra" }
              },
              {
                resource_prefix           = "sg-ingress-"
                name_short                = "allow-tcp-traffics-from-protected"
                description               = "Allow TCP ingress traffics from protected subnets"
                from_port                 = 443
                to_port                   = 443
                ip_protocol               = "TCP"
                referenced_security_group = { name_short = "ecs-protected" }
              },
            ],
            local.destinations[vpc.name_short][var.common.env].ingress
          )
          vpc = vpc,
        },
        var.common.env == "dev" ? {
          # ! CAUTION this sg should only be used in dev for debugging purposes only.
          resource_prefix = "sg-"
          name_short      = "ecs-default"
          description     = "Default security group for ECS tasks."
          egress = concat(
            [
              {
                resource_prefix = "sg-egress-"
                name_short      = "allow-all-egress-traffics"
                description     = "Allow all egress traffics"
                to_port         = -1
                from_port       = -1
                ip_protocol     = "-1"
                cidr_blocks     = ["0.0.0.0/0"]
              }
            ],
            local.destinations[vpc.name_short][var.common.env].egress
          )
          ingress = concat(
            [
              {
                resource_prefix = "sg-ingress-"
                name_short      = "allow-tcp-ingress-traffics-from-vpc"
                description     = "Allow TCP ingress traffics from VPC"
                to_port         = 443
                from_port       = 443
                ip_protocol     = "TCP"
                cidr_blocks     = [local.cidr_blocks[vpc.name_short].self]
              }
            ],
            local.destinations[vpc.name_short][var.common.env].ingress
          )
          vpc = vpc,
        } : null,
      ] :
      merge(
        sg,
        { name = "${var.common.prefix}${vpc.vpc_resource_prefix}${sg.resource_prefix}${sg.name_short}${var.common.suffix}" }
      )
      if sg != null
    ]
  ])
  egress_rules = flatten([
    for sg in local.security_groups : [
      for egress in sg.egress : merge(egress, {
        name = "${var.common.prefix}${sg.vpc.vpc_resource_prefix}${egress.resource_prefix}${sg.name_short}-${egress.name_short}${var.common.suffix}"
        sg   = sg,
        vpc  = sg.vpc
      })
    ]
  ])
  ingress_rules = flatten([
    for sg in local.security_groups : [
      for ingress in sg.ingress : merge(ingress, {
        name = "${var.common.prefix}${sg.vpc.vpc_resource_prefix}${ingress.resource_prefix}${sg.name_short}-${ingress.name_short}${var.common.suffix}"
        sg   = sg,
        vpc  = sg.vpc
      })
    ]
  ])
}

resource "aws_security_group" "this" {
  # ref: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group
  depends_on = [aws_vpc.this]
  for_each = {
    for sg in local.security_groups : "${sg.vpc.name_short}-${sg.name_short}" => sg
  }

  name        = each.value.name
  vpc_id      = aws_vpc.this[each.value.vpc.name_short].id
  description = each.value.description

  tags = {
    name           = each.value.name
    Name           = each.value.name
    name_short     = each.value.name_short
    vpc_name       = each.value.vpc.name
    vpc_name_short = each.value.vpc.name_short
  }

  lifecycle {
    create_before_destroy = true
    ignore_changes = [
      tags["created_at"],
      tags["created_date"]
    ]
  }

  timeouts {
    create = "60m"
    delete = "2m"
  }
}

resource "aws_vpc_security_group_egress_rule" "this" {
  # ref: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_egress_rule
  depends_on = [aws_security_group.this]
  for_each = {
    for rule in local.egress_rules : "${rule.vpc.name_short}-${rule.sg.name_short}-${rule.name_short}" => rule
  }

  security_group_id = aws_security_group.this["${each.value.vpc.name_short}-${each.value.sg.name_short}"].id
  description       = each.value.description
  to_port           = each.value.to_port
  from_port         = each.value.from_port
  ip_protocol       = each.value.ip_protocol
  cidr_ipv4         = try(one(each.value.cidr_blocks), null)
  referenced_security_group_id = try(
    aws_security_group.this["${each.value.vpc.name_short}-${each.value.referenced_security_group.name_short}"].id,
    null
  )

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

resource "aws_vpc_security_group_ingress_rule" "this" {
  # ref: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_ingress_rule
  depends_on = [aws_security_group.this]
  for_each = {
    for rule in local.ingress_rules : "${rule.vpc.name_short}-${rule.sg.name_short}-${rule.name_short}" => rule
  }

  security_group_id = aws_security_group.this["${each.value.vpc.name_short}-${each.value.sg.name_short}"].id
  description       = each.value.description
  to_port           = each.value.to_port
  from_port         = each.value.from_port
  ip_protocol       = each.value.ip_protocol
  cidr_ipv4         = try(one(each.value.cidr_blocks), null)
  referenced_security_group_id = try(
    aws_security_group.this["${each.value.vpc.name_short}-${each.value.referenced_security_group.name_short}"].id,
    null
  )

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
