locals {
  s3 = {
    resource_prefix = "s3-"
  }
}

data "aws_vpc" "this" {
  # ref: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/vpc
  depends_on = [aws_vpc.this]
  for_each = {
    for vpc in local.context.vpc : vpc.name_short => vpc
  }

  filter {
    name   = "tag:name"
    values = [each.value.name]
  }
}

data "aws_s3_bucket" "this" {
  # ref: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/s3_bucket
  for_each = toset([var.alb.access_log.bucket.name_short, var.nlb.access_log.bucket.name_short])

  bucket = "${var.common.prefix}${local.s3.resource_prefix}${each.value}${var.common.suffix}"
}

data "aws_route53_zone" "this" {
  # ref: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/route53_zone
  for_each = {
    for vpc in local.context.vpc : vpc.name_short => vpc
  }

  name         = var.api.this.domain[var.common.env][each.value.name_short]
  private_zone = false
}
