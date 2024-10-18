# [Route 53]
resource "aws_route53_zone" "domain" {
  # ref: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_zone
  name    = var.api.this.domain["prod"]["main"]
  comment = "Domain Route53 Zone managed by terraform"

  tags = {
    name = var.api.this.domain["prod"]["main"]
    Name = var.api.this.domain["prod"]["main"]
  }

  lifecycle {
    ignore_changes = [
      tags["created_at"],
      tags["created_date"]
    ]
  }
}

# ref: https://repost.aws/knowledge-center/create-subdomain-route-53
resource "aws_route53_record" "subdomain_ns" {
  # ref: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record
  depends_on = [aws_route53_zone.domain, aws_route53_zone.subdomain]
  for_each = {
    for vpc in local.context.vpc : vpc.name_short => vpc
  }

  zone_id         = aws_route53_zone.domain.zone_id
  name            = var.api.this.domain[var.common.env][each.value.name_short]
  records         = aws_route53_zone.subdomain[each.value.name_short].name_servers
  ttl             = 172800
  type            = "NS"
  allow_overwrite = true
}

resource "aws_route53domains_registered_domain" "this" {
  # ref: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53domains_registered_domain
  depends_on  = [aws_route53_zone.domain]
  domain_name = var.api.this.domain["prod"]["main"]

  dynamic "name_server" {
    for_each = aws_route53_zone.domain.name_servers

    content {
      name = name_server.value
    }
  }

  tags = {
    name = var.api.this.domain["prod"]["main"]
    Name = var.api.this.domain["prod"]["main"]
  }
}
