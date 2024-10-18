# requirements:
# - `terragrunt init` ran in infra/terraform/{provider}/environments/dev/{module}
# - `terraform init` ran in infra/terraform/{provider}/modules/{module}

# refs:
# - https://developer.hashicorp.com/terraform/language/tests
# - https://developer.hashicorp.com/terraform/cli/commands/test
# - https://developer.hashicorp.com/terraform/cli/test
# - https://developer.hashicorp.com/terraform/language/tests#modules

override_data {
  target = data.aws_s3_bucket.this
}

run "unit_test_aws_vpc_works" {
  # ref: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc
  command = plan

  variables {
    is_test = true
    common  = var.defaults.common
  }

  assert {
    condition = (
      aws_vpc.this["main"].cidr_block == "172.16.0.0/21"
    )
    error_message = var.defaults.error_message
  }

  assert {
    condition = (
      aws_vpc.this["main"].enable_dns_hostnames == true
    )
    error_message = var.defaults.error_message
  }

  assert {
    condition = (
      aws_vpc.this["main"].enable_dns_support == true
    )
    error_message = var.defaults.error_message
  }

  assert {
    condition = (
      aws_vpc.this["main"].tags.name == "xev-vpp-evems-dev-vpc-main-delete-me"
    )
    error_message = var.defaults.error_message
  }

  assert {
    condition = (
      aws_vpc.this["main"].tags.name_short == "main"
    )
    error_message = var.defaults.error_message
  }

  assert {
    condition = (
      aws_vpc.this["misc"].cidr_block == "172.16.8.0/21"
    )
    error_message = var.defaults.error_message
  }

  assert {
    condition = (
      aws_vpc.this["misc"].enable_dns_hostnames == true
    )
    error_message = var.defaults.error_message
  }

  assert {
    condition = (
      aws_vpc.this["misc"].enable_dns_support == true
    )
    error_message = var.defaults.error_message
  }

  assert {
    condition = (
      aws_vpc.this["misc"].tags.name == "xev-vpp-evems-dev-vpc-misc-delete-me"
    )
    error_message = var.defaults.error_message
  }

  assert {
    condition = (
      aws_vpc.this["misc"].tags.name_short == "misc"
    )
    error_message = var.defaults.error_message
  }
}

run "unit_test_aws_subnet_works" {
  # ref: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet
  command = plan

  variables {
    is_test = true
    common  = var.defaults.common
  }

  assert {
    condition = (
      aws_subnet.this["main-intra-a"].availability_zone == "ap-northeast-1a"
    )
    error_message = var.defaults.error_message
  }

  assert {
    condition = (
      aws_subnet.this["main-intra-a"].cidr_block == "172.16.0.0/24"
    )
    error_message = var.defaults.error_message
  }

  assert {
    condition = (
      aws_subnet.this["main-intra-a"].map_public_ip_on_launch == false
    )
    error_message = var.defaults.error_message
  }

  assert {
    condition = (
      aws_subnet.this["main-intra-a"].tags.name == "xev-vpp-evems-dev-main-subnet-intra-a-delete-me"
    )
    error_message = var.defaults.error_message
  }

  assert {
    condition = (
      aws_subnet.this["main-intra-a"].tags.group_name == "intra"
    )
    error_message = var.defaults.error_message
  }

  assert {
    condition = (
      aws_subnet.this["main-intra-c"].availability_zone == "ap-northeast-1c"
    )
    error_message = var.defaults.error_message
  }

  assert {
    condition = (
      aws_subnet.this["main-intra-c"].cidr_block == "172.16.1.0/24"
    )
    error_message = var.defaults.error_message
  }

  assert {
    condition = (
      aws_subnet.this["main-intra-c"].map_public_ip_on_launch == false
    )
    error_message = var.defaults.error_message
  }

  assert {
    condition = (
      aws_subnet.this["main-intra-c"].tags.name == "xev-vpp-evems-dev-main-subnet-intra-c-delete-me"
    )
    error_message = var.defaults.error_message
  }

  assert {
    condition = (
      aws_subnet.this["main-intra-c"].tags.group_name == "intra"
    )
    error_message = var.defaults.error_message
  }

  assert {
    condition = (
      aws_subnet.this["main-intra-d"].availability_zone == "ap-northeast-1d"
    )
    error_message = var.defaults.error_message
  }

  assert {
    condition = (
      aws_subnet.this["main-intra-d"].cidr_block == "172.16.2.0/24"
    )
    error_message = var.defaults.error_message
  }

  assert {
    condition = (
      aws_subnet.this["main-intra-d"].map_public_ip_on_launch == false
    )
    error_message = var.defaults.error_message
  }

  assert {
    condition = (
      aws_subnet.this["main-intra-d"].tags.name == "xev-vpp-evems-dev-main-subnet-intra-d-delete-me"
    )
    error_message = var.defaults.error_message
  }

  assert {
    condition = (
      aws_subnet.this["main-intra-d"].tags.group_name == "intra"
    )
    error_message = var.defaults.error_message
  }

  assert {
    condition = (
      aws_subnet.this["main-protected-a"].availability_zone == "ap-northeast-1a"
    )
    error_message = var.defaults.error_message
  }

  assert {
    condition = (
      aws_subnet.this["main-protected-a"].cidr_block == "172.16.4.0/24"
    )
    error_message = var.defaults.error_message
  }

  assert {
    condition = (
      aws_subnet.this["main-protected-a"].map_public_ip_on_launch == false
    )
    error_message = var.defaults.error_message
  }

  assert {
    condition = (
      aws_subnet.this["main-protected-a"].tags.name == "xev-vpp-evems-dev-main-subnet-protected-a-delete-me"
    )
    error_message = var.defaults.error_message
  }

  assert {
    condition = (
      aws_subnet.this["main-protected-a"].tags.group_name == "protected"
    )
    error_message = var.defaults.error_message
  }

  assert {
    condition = (
      aws_subnet.this["main-protected-c"].availability_zone == "ap-northeast-1c"
    )
    error_message = var.defaults.error_message
  }

  assert {
    condition = (
      aws_subnet.this["main-protected-c"].cidr_block == "172.16.5.0/24"
    )
    error_message = var.defaults.error_message
  }

  assert {
    condition = (
      aws_subnet.this["main-protected-c"].map_public_ip_on_launch == false
    )
    error_message = var.defaults.error_message
  }

  assert {
    condition = (
      aws_subnet.this["main-protected-c"].tags.name == "xev-vpp-evems-dev-main-subnet-protected-c-delete-me"
    )
    error_message = var.defaults.error_message
  }

  assert {
    condition = (
      aws_subnet.this["main-protected-c"].tags.group_name == "protected"
    )
    error_message = var.defaults.error_message
  }

  assert {
    condition = (
      aws_subnet.this["main-protected-d"].availability_zone == "ap-northeast-1d"
    )
    error_message = var.defaults.error_message
  }

  assert {
    condition = (
      aws_subnet.this["main-protected-d"].cidr_block == "172.16.6.0/24"
    )
    error_message = var.defaults.error_message
  }

  assert {
    condition = (
      aws_subnet.this["main-protected-d"].map_public_ip_on_launch == false
    )
    error_message = var.defaults.error_message
  }

  assert {
    condition = (
      aws_subnet.this["main-protected-d"].tags.name == "xev-vpp-evems-dev-main-subnet-protected-d-delete-me"
    )
    error_message = var.defaults.error_message
  }

  assert {
    condition = (
      aws_subnet.this["main-protected-d"].tags.group_name == "protected"
    )
    error_message = var.defaults.error_message
  }

  assert {
    condition = (
      aws_subnet.this["misc-intra-a"].availability_zone == "ap-northeast-1a"
    )
    error_message = var.defaults.error_message
  }

  assert {
    condition = (
      aws_subnet.this["misc-intra-a"].cidr_block == "172.16.8.0/24"
    )
    error_message = var.defaults.error_message
  }

  assert {
    condition = (
      aws_subnet.this["misc-intra-a"].map_public_ip_on_launch == false
    )
    error_message = var.defaults.error_message
  }

  assert {
    condition = (
      aws_subnet.this["misc-intra-a"].tags.name == "xev-vpp-evems-dev-misc-subnet-intra-a-delete-me"
    )
    error_message = var.defaults.error_message
  }

  assert {
    condition = (
      aws_subnet.this["misc-intra-a"].tags.group_name == "intra"
    )
    error_message = var.defaults.error_message
  }

  assert {
    condition = (
      aws_subnet.this["misc-intra-c"].availability_zone == "ap-northeast-1c"
    )
    error_message = var.defaults.error_message
  }

  assert {
    condition = (
      aws_subnet.this["misc-intra-c"].cidr_block == "172.16.9.0/24"
    )
    error_message = var.defaults.error_message
  }

  assert {
    condition = (
      aws_subnet.this["misc-intra-c"].map_public_ip_on_launch == false
    )
    error_message = var.defaults.error_message
  }

  assert {
    condition = (
      aws_subnet.this["misc-intra-c"].tags.name == "xev-vpp-evems-dev-misc-subnet-intra-c-delete-me"
    )
    error_message = var.defaults.error_message
  }

  assert {
    condition = (
      aws_subnet.this["misc-intra-c"].tags.group_name == "intra"
    )
    error_message = var.defaults.error_message
  }

  assert {
    condition = (
      aws_subnet.this["misc-intra-d"].availability_zone == "ap-northeast-1d"
    )
    error_message = var.defaults.error_message
  }

  assert {
    condition = (
      aws_subnet.this["misc-intra-d"].cidr_block == "172.16.10.0/24"
    )
    error_message = var.defaults.error_message
  }

  assert {
    condition = (
      aws_subnet.this["misc-intra-d"].map_public_ip_on_launch == false
    )
    error_message = var.defaults.error_message
  }

  assert {
    condition = (
      aws_subnet.this["misc-intra-d"].tags.name == "xev-vpp-evems-dev-misc-subnet-intra-d-delete-me"
    )
    error_message = var.defaults.error_message
  }

  assert {
    condition = (
      aws_subnet.this["misc-intra-d"].tags.group_name == "intra"
    )
    error_message = var.defaults.error_message
  }

  assert {
    condition = (
      aws_subnet.this["misc-protected-a"].availability_zone == "ap-northeast-1a"
    )
    error_message = var.defaults.error_message
  }

  assert {
    condition = (
      aws_subnet.this["misc-protected-a"].cidr_block == "172.16.12.0/24"
    )
    error_message = var.defaults.error_message
  }

  assert {
    condition = (
      aws_subnet.this["misc-protected-a"].map_public_ip_on_launch == false
    )
    error_message = var.defaults.error_message
  }

  assert {
    condition = (
      aws_subnet.this["misc-protected-a"].tags.name == "xev-vpp-evems-dev-misc-subnet-protected-a-delete-me"
    )
    error_message = var.defaults.error_message
  }

  assert {
    condition = (
      aws_subnet.this["misc-protected-a"].tags.group_name == "protected"
    )
    error_message = var.defaults.error_message
  }

  assert {
    condition = (
      aws_subnet.this["misc-protected-c"].availability_zone == "ap-northeast-1c"
    )
    error_message = var.defaults.error_message
  }

  assert {
    condition = (
      aws_subnet.this["misc-protected-c"].cidr_block == "172.16.13.0/24"
    )
    error_message = var.defaults.error_message
  }

  assert {
    condition = (
      aws_subnet.this["misc-protected-c"].map_public_ip_on_launch == false
    )
    error_message = var.defaults.error_message
  }

  assert {
    condition = (
      aws_subnet.this["misc-protected-c"].tags.name == "xev-vpp-evems-dev-misc-subnet-protected-c-delete-me"
    )
    error_message = var.defaults.error_message
  }

  assert {
    condition = (
      aws_subnet.this["misc-protected-c"].tags.group_name == "protected"
    )
    error_message = var.defaults.error_message
  }

  assert {
    condition = (
      aws_subnet.this["misc-protected-d"].availability_zone == "ap-northeast-1d"
    )
    error_message = var.defaults.error_message
  }

  assert {
    condition = (
      aws_subnet.this["misc-protected-d"].cidr_block == "172.16.14.0/24"
    )
    error_message = var.defaults.error_message
  }

  assert {
    condition = (
      aws_subnet.this["misc-protected-d"].map_public_ip_on_launch == false
    )
    error_message = var.defaults.error_message
  }

  assert {
    condition = (
      aws_subnet.this["misc-protected-d"].tags.name == "xev-vpp-evems-dev-misc-subnet-protected-d-delete-me"
    )
    error_message = var.defaults.error_message
  }

  assert {
    condition = (
      aws_subnet.this["misc-protected-d"].tags.group_name == "protected"
    )
    error_message = var.defaults.error_message
  }
}

run "unit_test_aws_route_table_works" {
  # ref: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table
  command = plan

  variables {
    is_test = true
    common  = var.defaults.common
  }

  assert {
    condition = (
      length([for route in aws_route_table.this["main"].route : route if route.cidr_block == "172.16.0.0/21"]) == 1
    )
    error_message = var.defaults.error_message
  }

  assert {
    condition = (
      length([for route in aws_route_table.this["main"].route : route if route.gateway_id == "local"]) == 1
    )
    error_message = var.defaults.error_message
  }

  assert {
    condition = (
      aws_route_table.this["main"].tags.name == "xev-vpp-evems-dev-main-rt-delete-me"
    )
    error_message = var.defaults.error_message
  }

  assert {
    condition = (
      length([for route in aws_route_table.this["misc"].route : route if route.cidr_block == "172.16.8.0/21"]) == 1
    )

    error_message = var.defaults.error_message
  }

  assert {
    condition = (
      length([for route in aws_route_table.this["misc"].route : route if route.gateway_id == "local"]) == 1
    )
    error_message = var.defaults.error_message
  }

  assert {
    condition = (
      aws_route_table.this["misc"].tags.name == "xev-vpp-evems-dev-misc-rt-delete-me"
    )
    error_message = var.defaults.error_message
  }
}

run "unit_test_aws_vpc_endpoint_works" {
  # ref: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_endpoint
  command = plan

  variables {
    is_test = true
    common  = var.defaults.common
  }

  assert {
    condition = (
      aws_vpc_endpoint.this["main-ecr-api"].vpc_endpoint_type == "Interface"
    )
    error_message = var.defaults.error_message
  }

  assert {
    condition = (
      aws_vpc_endpoint.this["main-ecr-api"].service_name == "com.amazonaws.ap-northeast-1.ecr.api"
    )
    error_message = var.defaults.error_message
  }

  assert {
    condition = (
      aws_vpc_endpoint.this["main-ecr-api"].private_dns_enabled == true
    )
    error_message = var.defaults.error_message
  }

  assert {
    condition = (
      aws_vpc_endpoint.this["main-ecr-api"].tags["name"] == "xev-vpp-evems-dev-main-vpce-ecr-api-delete-me"
    )
    error_message = var.defaults.error_message
  }

  assert {
    condition = (
      aws_vpc_endpoint.this["main-ecr-dkr"].vpc_endpoint_type == "Interface"
    )
    error_message = var.defaults.error_message
  }

  assert {
    condition = (
      aws_vpc_endpoint.this["main-ecr-dkr"].service_name == "com.amazonaws.ap-northeast-1.ecr.dkr"
    )
    error_message = var.defaults.error_message
  }

  assert {
    condition = (
      aws_vpc_endpoint.this["main-ecr-dkr"].private_dns_enabled == true
    )
    error_message = var.defaults.error_message
  }

  assert {
    condition = (
      aws_vpc_endpoint.this["main-ecr-dkr"].tags["name"] == "xev-vpp-evems-dev-main-vpce-ecr-dkr-delete-me"
    )
    error_message = var.defaults.error_message
  }

  assert {
    condition = (
      aws_vpc_endpoint.this["misc-ecr-api"].vpc_endpoint_type == "Interface"
    )
    error_message = var.defaults.error_message
  }

  assert {
    condition = (
      aws_vpc_endpoint.this["misc-ecr-api"].service_name == "com.amazonaws.ap-northeast-1.ecr.api"
    )
    error_message = var.defaults.error_message
  }

  assert {
    condition = (
      aws_vpc_endpoint.this["misc-ecr-api"].private_dns_enabled == true
    )
    error_message = var.defaults.error_message
  }

  assert {
    condition = (
      aws_vpc_endpoint.this["misc-ecr-api"].tags["name"] == "xev-vpp-evems-dev-misc-vpce-ecr-api-delete-me"
    )
    error_message = var.defaults.error_message
  }

  assert {
    condition = (
      aws_vpc_endpoint.this["misc-ecr-dkr"].vpc_endpoint_type == "Interface"
    )
    error_message = var.defaults.error_message
  }

  assert {
    condition = (
      aws_vpc_endpoint.this["misc-ecr-dkr"].service_name == "com.amazonaws.ap-northeast-1.ecr.dkr"
    )
    error_message = var.defaults.error_message
  }

  assert {
    condition = (
      aws_vpc_endpoint.this["misc-ecr-dkr"].private_dns_enabled == true
    )
    error_message = var.defaults.error_message
  }

  assert {
    condition = (
      aws_vpc_endpoint.this["misc-ecr-dkr"].tags["name"] == "xev-vpp-evems-dev-misc-vpce-ecr-dkr-delete-me"
    )
    error_message = var.defaults.error_message
  }

  # TODO:
  # vpc endpoint for s3, dynamodb etc.
  # nlb, alb
}
