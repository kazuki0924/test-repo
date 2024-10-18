locals {
  alb = [
    for vpc in local.context.vpc : {
      # name cannot be longer than 32 characters
      name = "${vpc.vpc_resource_prefix}${var.alb.resource_prefix}${var.alb.name_short}${local.common.lb.suffix}"
      listener = {
        name       = "${var.common.prefix}${vpc.vpc_resource_prefix}${var.alb.listener.resource_prefix}${var.alb.name_short}${var.common.suffix}"
        name_short = var.alb.name_short
      }
      vpc = vpc
    }
  ]
  nlb = [
    for vpc in local.context.vpc : {
      # name cannot be longer than 32 characters
      name = "${vpc.vpc_resource_prefix}${var.nlb.resource_prefix}${var.nlb.name_short}${local.common.lb.suffix}"
      listener = {
        name       = "${var.common.prefix}${vpc.vpc_resource_prefix}${var.nlb.listener.resource_prefix}${var.nlb.name_short}${var.common.suffix}"
        name_short = var.nlb.name_short
      }
      taget_group = {
        # name cannot be longer than 32 characters
        name       = "${vpc.vpc_resource_prefix}${var.nlb.target_group.resource_prefix}${var.nlb.name_short}${local.common.lb.suffix}"
        name_short = var.nlb.name_short
      }
      vpc_endpoint_service = {
        name       = "${var.common.prefix}${vpc.vpc_resource_prefix}${var.nlb.vpc_endpoint_service.resource_prefix}${var.nlb.name_short}${var.common.suffix}"
        name_short = var.nlb.name_short
        allowed_principals = {
          dev = [{
            name_short = "vpce-e2e-testing"
            arn        = "arn:aws:iam::${local.common.aws_account_id}:root"
          }]
          # TBD:
          # test = [{
          #   name_short = "vpce-xev-vpp-doms-test"
          #   arn        = "arn:aws:iam::${var.api.destinations.xev_vpp_doms["test"].account_id}:root"
          # }]
          # stg = [{
          #   name_short = "vpce-xev-vpp-doms-stg"
          #   arn        = "arn:aws:iam::${var.api.destinations.xev_vpp_doms["stg"].account_id}:root"
          # }]
          # prod = [{
          #   name_short = "vpce-xev-vpp-doms-prod"
          #   arn        = "arn:aws:iam::${var.api.destinations.xev_vpp_doms["prod"].account_id}:root"
          # }]
        }
      }
      vpc = vpc
    }
  ]
  vpces_allowed_pricipals = flatten([
    for nlb in local.nlb : [
      for principal in nlb.vpc_endpoint_service.allowed_principals[var.common.env] :
      merge(principal, {
        vpc_endpoint_service_id = aws_vpc_endpoint_service.nlb[nlb.vpc.name_short].id
        nlb                     = nlb
      })
    ]
  ])
  acm = [
    for vpc in local.context.vpc :
    {
      domain_name = "${var.api.this.domain[var.common.env][vpc.name_short]}"
      alt_name    = "*.${var.api.this.domain[var.common.env][vpc.name_short]}"
      vpc         = vpc
    }
  ]
}

# [ACM (Certificate Manager)]
resource "aws_acm_certificate" "this" {
  # ref: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/acm_certificate
  for_each = {
    for acm in local.acm : acm.vpc.name_short => acm
  }

  domain_name               = each.value.domain_name
  subject_alternative_names = [each.value.alt_name]
  validation_method         = "DNS"

  tags = {
    name           = each.value.domain_name
    Name           = each.value.domain_name
    name_short     = var.common.domain
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
}

# [Route 53]
resource "aws_route53_record" "validation" {
  # ref: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record
  depends_on = [aws_acm_certificate.this, data.aws_route53_zone.this]
  for_each = {
    for acm in local.acm : acm.vpc.name_short => acm
  }

  zone_id = data.aws_route53_zone.this[each.value.vpc.name_short].zone_id
  name    = each.value.alt_name
  type = one(
    [for option in aws_acm_certificate.this[each.value.vpc.name_short].domain_validation_options : option.resource_record_type if option.domain_name == each.value.alt_name]
  )
  records = [for option in aws_acm_certificate.this[each.value.vpc.name_short].domain_validation_options : option.resource_record_value if option.domain_name == each.value.alt_name]

  ttl             = 60
  allow_overwrite = true
}

# [ACM (Certificate Manager)]
resource "aws_acm_certificate_validation" "this" {
  # ref: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/acm_certificate_validation
  depends_on = [aws_acm_certificate.this, aws_route53_record.validation]
  for_each = {
    for acm in local.acm : acm.vpc.name_short => acm
  }

  certificate_arn = aws_acm_certificate.this[each.value.vpc.name_short].arn
  validation_record_fqdns = [
    for fqdn in [
      for record in aws_route53_record.validation[each.value.vpc.name_short] : try(record.fqdn, null)
    ] :
    fqdn if fqdn != null
  ]

  timeouts {
    create = "60m" # default: 75m
  }
}

# [ELB (Elastic Load Balancing)]
resource "aws_lb" "alb" {
  # ref: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb
  depends_on = [
    aws_security_group.this,
    data.aws_s3_bucket.this
  ]
  for_each = {
    for alb in local.alb : alb.vpc.name_short => alb
  }

  name               = each.value.name
  internal           = true
  load_balancer_type = "application"
  security_groups    = [aws_security_group.this["${each.value.vpc.name_short}-alb"].id]
  subnets            = [for az in ["a", "c", "d"] : aws_subnet.this["${each.value.vpc.name_short}-intra-${az}"].id]

  enable_deletion_protection       = lookup(var.alb.enable_deletion_protection, var.common.env, true)
  drop_invalid_header_fields       = true
  enable_cross_zone_load_balancing = true
  desync_mitigation_mode           = "defensive"

  access_logs {
    bucket  = data.aws_s3_bucket.this[var.alb.access_log.bucket.name_short].id
    prefix  = "${var.alb.access_log.prefix}/${each.value.name}"
    enabled = true
  }

  connection_logs {
    bucket  = data.aws_s3_bucket.this[var.alb.connection_log.bucket.name_short].id
    prefix  = "${var.alb.connection_log.prefix}/${each.value.name}"
    enabled = true
  }

  tags = {
    name                = each.value.name
    Name                = each.value.name
    name_before_trimmed = "${var.common.prefix}${each.value.vpc.vpc_resource_prefix}${var.alb.resource_prefix}${var.alb.name_short}${var.common.suffix}"
    name_short          = var.alb.name_short
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

resource "aws_lb_listener" "alb" {
  # ref: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener
  depends_on = [aws_lb.alb, aws_acm_certificate.this, aws_acm_certificate_validation.this]
  for_each = {
    for alb in local.alb : alb.vpc.name_short => alb
  }

  load_balancer_arn = aws_lb.alb[each.value.vpc.name_short].arn
  port              = 443
  protocol          = "HTTPS"
  # ref: https://docs.aws.amazon.com/elasticloadbalancing/latest/application/describe-ssl-policies.html
  ssl_policy      = "ELBSecurityPolicy-TLS13-1-3-2021-06"
  certificate_arn = aws_acm_certificate.this[each.value.vpc.name_short].arn

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "application/json"
      # TBD: temp
      message_body = jsonencode({
        error = "Error: Access to root path is not allowed."
      })
      status_code = "403"
    }
  }

  tags = {
    name           = each.value.listener.name
    Name           = each.value.listener.name
    name_short     = each.value.listener.name_short
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
}

resource "aws_lb" "nlb" {
  # ref: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb
  depends_on = [
    aws_security_group.this,
    data.aws_s3_bucket.this
  ]
  for_each = {
    for nlb in local.nlb : nlb.vpc.name_short => nlb
  }

  # name cannot be longer than 32 characters
  name               = each.value.name
  internal           = true
  load_balancer_type = "network"
  security_groups    = [aws_security_group.this["${each.value.vpc.name_short}-nlb"].id]
  subnets            = [for az in ["a", "c", "d"] : aws_subnet.this["${each.value.vpc.name_short}-intra-${az}"].id]

  enable_deletion_protection = lookup(var.nlb.enable_deletion_protection, var.common.env, true)
  enforce_security_group_inbound_rules_on_private_link_traffic = lookup(
    var.nlb.enforce_security_group_inbound_rules_on_private_link_traffic,
    var.common.env,
    "on"
  )
  drop_invalid_header_fields = true
  desync_mitigation_mode     = "defensive"

  access_logs {
    bucket  = data.aws_s3_bucket.this[var.nlb.access_log.bucket.name_short].id
    prefix  = "${var.nlb.access_log.prefix}/${each.value.name}"
    enabled = true
  }

  connection_logs {
    bucket  = data.aws_s3_bucket.this[var.nlb.connection_log.bucket.name_short].id
    prefix  = "${var.nlb.connection_log.prefix}/${each.value.name}"
    enabled = true
  }

  tags = {
    name                = each.value.name
    Name                = each.value.name
    name_before_trimmed = "${var.common.prefix}${each.value.vpc.vpc_resource_prefix}${var.nlb.resource_prefix}${var.nlb.name_short}${local.common.lb.suffix}"
    name_short          = var.nlb.name_short
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

resource "aws_lb_target_group" "nlb" {
  # ref:https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_target_group
  depends_on = [aws_vpc.this]
  for_each = {
    for nlb in local.nlb : nlb.vpc.name_short => nlb
  }

  name        = each.value.taget_group.name
  target_type = "alb"
  port        = 443

  protocol          = "TCP"
  proxy_protocol_v2 = false
  vpc_id            = aws_vpc.this[each.value.vpc.name_short].id

  health_check {
    path                = "/"
    protocol            = "HTTPS"
    port                = 443
    matcher             = var.common.app.default.health_check.matcher             # aws default: "200", variables.tf default: "200"
    interval            = var.common.app.default.health_check.interval            # aws default: 30, variables.tf default: 30
    timeout             = var.common.app.default.health_check.timeout             # aws default: 5, variables.tf default: 20
    healthy_threshold   = var.common.app.default.health_check.healthy_threshold   # aws default: 3, variables.tf default: 3
    unhealthy_threshold = var.common.app.default.health_check.unhealthy_threshold # aws default: 3, variables.tf default: 3
  }

  tags = {
    name                = each.value.taget_group.name
    Name                = each.value.taget_group.name
    name_before_trimmed = "${var.common.prefix}${each.value.vpc.vpc_resource_prefix}${var.nlb.target_group.resource_prefix}${var.nlb.name_short}${var.common.suffix}"
    name_short          = each.value.taget_group.name_short
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

resource "aws_lb_target_group_attachment" "nlb" {
  # ref: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_target_group_attachment
  depends_on = [aws_lb_target_group.nlb, aws_lb.alb, aws_lb_listener.alb]
  for_each = {
    for nlb in local.nlb : nlb.vpc.name_short => nlb
  }

  target_group_arn = aws_lb_target_group.nlb[each.value.vpc.name_short].arn
  target_id        = aws_lb.alb[each.value.vpc.name_short].id
  port             = 443
}

resource "aws_lb_listener" "nlb" {
  # ref: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener
  depends_on = [aws_lb.nlb, aws_lb_target_group.nlb]
  for_each = {
    for nlb in local.nlb : nlb.vpc.name_short => nlb
  }

  load_balancer_arn = aws_lb.nlb[each.value.vpc.name_short].id
  port              = 443
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.nlb[each.value.vpc.name_short].arn
  }

  tags = {
    name           = each.value.listener.name
    Name           = each.value.listener.name
    name_short     = each.value.listener.name_short
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
}

# [Route 53]
resource "aws_route53_record" "a" {
  # ref: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record
  depends_on = [aws_lb.nlb, data.aws_route53_zone.this]
  for_each = {
    for nlb in local.nlb : nlb.vpc.name_short => nlb
  }

  type    = "A"
  name    = data.aws_route53_zone.this[each.value.vpc.name_short].name
  zone_id = data.aws_route53_zone.this[each.value.vpc.name_short].zone_id

  alias {
    name                   = aws_lb.nlb[each.value.vpc.name_short].dns_name
    zone_id                = aws_lb.nlb[each.value.vpc.name_short].zone_id
    evaluate_target_health = true
  }
}

# [VPC (Virtual Private Cloud)]
resource "aws_vpc_endpoint_service" "nlb" {
  # ref: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_endpoint_service
  depends_on = [aws_lb.nlb, data.aws_route53_zone.this]
  for_each = {
    for nlb in local.nlb : nlb.vpc.name_short => nlb
  }

  acceptance_required        = lookup(var.nlb.vpc_endpoint_service.acceptance_required, var.common.env, true)
  network_load_balancer_arns = [aws_lb.nlb[each.value.vpc.name_short].arn]
  private_dns_name           = data.aws_route53_zone.this[each.value.vpc.name_short].name

  tags = {
    name           = each.value.vpc_endpoint_service.name
    Name           = each.value.vpc_endpoint_service.name
    name_short     = each.value.vpc_endpoint_service.name_short
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

resource "aws_vpc_endpoint_service_allowed_principal" "nlb" {
  # ref: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_endpoint_service_allowed_principal
  depends_on = [aws_vpc_endpoint_service.nlb]
  for_each = {
    for principal in local.vpces_allowed_pricipals : "${principal.nlb.vpc.name_short}-${principal.name_short}" => principal
  }

  vpc_endpoint_service_id = each.value.vpc_endpoint_service_id
  # ref: https://docs.aws.amazon.com/vpc/latest/privatelink/configure-endpoint-service.html
  principal_arn = each.value.arn
}

resource "aws_vpc_endpoint_service_private_dns_verification" "nlb" {
  # ref: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_endpoint_service_private_dns_verification
  depends_on = [aws_vpc_endpoint_service.nlb]
  for_each = {
    for nlb in local.nlb : nlb.vpc.name_short => nlb
  }

  service_id = aws_vpc_endpoint_service.nlb[each.value.vpc.name_short].id
}
