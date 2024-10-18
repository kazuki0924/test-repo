locals {
  # cidrsubnet()に渡すためのnewbits, netnumを算出
  # https://developer.hashicorp.com/terraform/language/functions/cidrsubnet
  subnets = flatten([
    for vpc in local.context.vpc : [
      for group_index, group in vpc.subnet_groups : [
        for subnet in [
          for az_index, az in group.az : merge(group, {
            name_short = "${group.group_name}-${substr(az, length(az) - 1, 1)}"
            cidr = {
              newbits = group.cidr.prefix - vpc.cidr.prefix
              netnum  = az_index + (group_index * length(group))
            }
            az  = az
            vpc = vpc
          })
        ] :
        merge(
          subnet,
          { name = "${var.common.prefix}${vpc.vpc_resource_prefix}${subnet.resource_prefix}${subnet.name_short}${var.common.suffix}" }
        )
      ]
    ]
  ])
  client_vpc_endpoint_service_names = {
    for vpc in local.context.vpc : vpc.name_short => {
      dev = {
        resource_prefix     = "vpce-"
        name_short          = "e2e-testing"
        service_name        = aws_vpc_endpoint_service.nlb[one(setsubtract(["main", "misc"], [vpc.name_short]))].service_name
        private_dns_enabled = false
      }
      # TBD:
      # test = var.api.destinations.xev_vpp_doms["test"].vpc_endpoint,
      # stg  = var.api.destinations.xev_vpp_doms["stg"].vpc_endpoint,
      # prod = var.api.destinations.xev_vpp_doms["prod"].vpc_endpoint
    }
  }
  vpc_endpoint_services = {
    for vpc in local.context.vpc : vpc.name_short => {
      Interface = concat(
        [
          for service in [
            "ecr.api",     # Amazon ECR
            "ecr.dkr",     # Amazon ECR
            "execute-api", # Amazon API Gateway
            "logs",        # Amazon CloudWatch Logs
            "ssmmessages", # Amazon Systems Manager
          ] :
          {
            resource_prefix     = "vpce-"
            name_short          = replace(service, ".", "-")
            service_name        = "com.amazonaws.${var.common.aws.region}.${service}"
            private_dns_enabled = true
          }
        ],
        [local.client_vpc_endpoint_service_names[vpc.name_short][var.common.env]],
      ),
      Gateway = [
        for service in [
          "s3",      # Amazon S3
          "dynamodb" # Amazon DynamoDB
        ] :
        {
          resource_prefix     = "vpce-"
          name_short          = replace(service, ".", "-")
          service_name        = "com.amazonaws.${var.common.aws.region}.${service}"
          private_dns_enabled = false
        }
      ]
    }
  }
  vpc_endpoints = flatten([
    for vpc in local.context.vpc : [
      for type, endpoint in local.vpc_endpoint_services[vpc.name_short] : [
        for e in endpoint : [
          merge(
            e,
            {
              name = "${var.common.prefix}${vpc.vpc_resource_prefix}${e.resource_prefix}${e.name_short}${var.common.suffix}"
              type = type
              vpc  = vpc
            }
          )
        ]
      ]
    ]
  ])
  # refs:
  # - https://repost.aws/questions/QU_CqSibvbRRaWI-TS43EYAw/how-to-enable-vpc-endpoint-setting-about-multiple-private-subnet-per-az
  # - https://docs.aws.amazon.com/vpc/latest/privatelink/create-interface-endpoint.html#considerations-interface-endpoints
  # - https://docs.aws.amazon.com/vpc/latest/privatelink/privatelink-access-aws-services.html
  aws_vpc_endpoint_subnet_associations = flatten([
    for subnet in local.subnets : [
      for endpoint in local.vpc_endpoint_services[subnet.vpc.name_short]["Interface"] : [
        merge(endpoint, {
          vpc = subnet.vpc
          subnet = merge(subnet, {
            id = aws_subnet.this["${subnet.vpc.name_short}-${subnet.name_short}"].id
          })
        })
      ]
    ] if subnet.group_name == "intra"
  ])
  aws_vpc_endpoint_security_group_associations = flatten([
    for endpoint in local.vpc_endpoints :
    merge(endpoint, {
      security_group = { id = aws_security_group.this["${endpoint.vpc.name_short}-vpce"].id }
    })
    if endpoint.type == "Interface"
  ])
  aws_vpc_endpoint_route_table_associations = flatten([
    for endpoint in local.vpc_endpoints :
    merge(endpoint, {
      route_table = { id = aws_route_table.this[endpoint.vpc.name_short].id }
    })
    if endpoint.type == "Gateway"
  ])
}

resource "aws_vpc" "this" {
  # ref: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc
  for_each = {
    for vpc in local.context.vpc : vpc.name_short => vpc
  }

  cidr_block           = each.value.cidr_block
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    name = each.value.name
    # tag:Nameがマネコン上のNameとなっている為、Nameを設定
    Name           = each.value.name
    name_short     = each.value.name_short
    vpc_name       = each.value.name
    vpc_name_short = each.value.name_short
  }

  lifecycle {
    ignore_changes = [
      tags["created_at"],
      tags["created_date"]
    ]
  }
}

resource "aws_subnet" "this" {
  # ref: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet
  depends_on = [aws_vpc.this]
  for_each = {
    for subnet in local.subnets : "${subnet.vpc.name_short}-${subnet.name_short}" => subnet
  }

  vpc_id                  = aws_vpc.this[each.value.vpc.name_short].id
  cidr_block              = cidrsubnet(each.value.vpc.cidr_block, each.value.cidr.newbits, each.value.cidr.netnum)
  availability_zone       = each.value.az
  map_public_ip_on_launch = false

  tags = {
    name = each.value.name
    # tag:Nameがマネコン上のNameとなっている為、Nameを設定
    Name           = each.value.name
    name_short     = each.value.name_short # e.g. "intra-a", "intra-c", "intra-d", "protected-a", "protected-c", "protected-d"
    group_name     = each.value.group_name # e.g. "intra", "protected"
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

resource "aws_route_table" "this" {
  # ref: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table
  depends_on = [aws_vpc.this]
  for_each = {
    for vpc in local.context.vpc : vpc.name_short => vpc
  }

  vpc_id = aws_vpc.this[each.value.name_short].id

  route {
    cidr_block = aws_vpc.this[each.value.name_short].cidr_block
    gateway_id = "local"
  }

  tags = {
    name           = each.value.route_table.name
    Name           = each.value.route_table.name
    name_short     = each.value.route_table.name_short
    vpc_name       = each.value.name
    vpc_name_short = each.value.name_short
  }

  lifecycle {
    ignore_changes = [
      tags["created_at"],
      tags["created_date"]
    ]
  }
}

resource "aws_route_table_association" "this" {
  # ref: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association
  depends_on = [aws_subnet.this, aws_route_table.this]
  for_each = {
    for subnet in local.subnets : "${subnet.vpc.name_short}-${subnet.name_short}" => subnet
  }

  route_table_id = aws_route_table.this[each.value.vpc.name_short].id
  subnet_id      = aws_subnet.this[each.key].id
}

resource "aws_vpc_endpoint" "this" {
  # ref: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_endpoint
  depends_on = [aws_vpc.this, aws_subnet.this]
  for_each = {
    for endpoint in local.vpc_endpoints : "${endpoint.vpc.name_short}-${endpoint.name_short}" => endpoint
  }

  vpc_id              = aws_vpc.this[each.value.vpc.name_short].id
  service_name        = each.value.service_name
  vpc_endpoint_type   = each.value.type
  private_dns_enabled = each.value.private_dns_enabled

  tags = {
    name           = each.value.name
    Name           = each.value.name
    name_short     = each.value.name_short
    service_name   = each.value.service_name
    type           = each.value.type
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

resource "aws_vpc_endpoint_subnet_association" "this" {
  # ref: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_endpoint_subnet_association
  depends_on = [aws_vpc_endpoint.this, aws_security_group.this]
  for_each = {
    for endpoint in local.aws_vpc_endpoint_subnet_associations :
    "${endpoint.vpc.name_short}-${endpoint.name_short}-${endpoint.subnet.name_short}" => endpoint
  }

  vpc_endpoint_id = aws_vpc_endpoint.this["${each.value.vpc.name_short}-${each.value.name_short}"].id
  subnet_id       = each.value.subnet.id
}

resource "aws_vpc_endpoint_security_group_association" "this" {
  # ref: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_endpoint_security_group_association
  depends_on = [aws_vpc_endpoint.this, aws_security_group.this]
  for_each = {
    for endpoint in local.aws_vpc_endpoint_security_group_associations :
    "${endpoint.vpc.name_short}-${endpoint.name_short}" => endpoint
  }

  vpc_endpoint_id   = aws_vpc_endpoint.this["${each.value.vpc.name_short}-${each.value.name_short}"].id
  security_group_id = each.value.security_group.id
}

resource "aws_vpc_endpoint_route_table_association" "this" {
  # ref: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_endpoint_route_table_association
  depends_on = [aws_route_table.this, aws_vpc_endpoint.this]
  for_each = {
    for endpoint in local.aws_vpc_endpoint_route_table_associations :
    "${endpoint.vpc.name_short}-${endpoint.name_short}" => endpoint
  }

  vpc_endpoint_id = aws_vpc_endpoint.this["${each.value.vpc.name_short}-${each.value.name_short}"].id
  route_table_id  = each.value.route_table.id
}

# TODO: fix trivy or tflint warnings/errors
# create vpc flow logs
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/flow_log
# https://avd.aquasec.com/misconfig/aws/ec2/avd-aws-0178/
