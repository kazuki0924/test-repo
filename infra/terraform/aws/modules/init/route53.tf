locals {
  route53 = {
    for vpc in local.context.vpc : vpc.name_short => {
      name = var.api.this.domain[var.common.env][vpc.name_short]
      vpc  = vpc
    }
  }
  create_route53_zone = !var.is_test
}

# [Route 53]
resource "aws_route53_zone" "subdomain" {
  # ref: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_zone
  for_each = {
    for vpc_name_short, route53 in local.route53 : vpc_name_short => route53
    if local.create_route53_zone
  }

  name    = each.value.name
  comment = "Subdomain Route53 Hosted Zone managed by terraform"

  tags = {
    name            = each.value.name
    Name            = each.value.name
    name_short      = each.value.vpc.name_short
    vpc_name        = each.value.vpc.name
    vpc_name_short  = each.value.vpc.name_short
    prevent_destroy = true
  }

  lifecycle {
    prevent_destroy = true
    ignore_changes = [
      tags["created_at"],
      tags["created_date"]
    ]
  }
}
