# requirements:
# - `terragrunt init` ran in infra/terraform/{provider}/environments/dev/{module}
# - `terraform init` ran in infra/terraform/{provider}/modules/{module}

# refs:
# - https://developer.hashicorp.com/terraform/language/tests
# - https://developer.hashicorp.com/terraform/cli/commands/test
# - https://developer.hashicorp.com/terraform/cli/test
# - https://developer.hashicorp.com/terraform/language/tests#modules

run "setup-init" {
  command = apply

  variables {
    is_test  = true
    common   = var.defaults.common
    s3       = null
    dynamodb = null
  }

  module {
    source = "../../../modules/init"
  }
}

run "setup-storage" {
  command = apply

  variables {
    is_test = true
    common  = var.defaults.common
  }

  module {
    source = "../storage"
  }
}

run "integration_test_aws_subnet_works" {
  # ref: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet
  command = apply

  variables {
    is_test = true
    common  = var.defaults.common
  }

  module {
    source = "../../../modules/network"
  }

  assert {
    condition = (
      aws_subnet.this["main-intra-a"].vpc_id == aws_vpc.this["main"].id
    )
    error_message = var.defaults.error_message
  }

  assert {
    condition = (
      aws_subnet.this["main-intra-c"].vpc_id == aws_vpc.this["main"].id
    )
    error_message = var.defaults.error_message
  }

  assert {
    condition = (
      aws_subnet.this["main-intra-d"].vpc_id == aws_vpc.this["main"].id
    )
    error_message = var.defaults.error_message
  }

  assert {
    condition = (
      aws_subnet.this["main-protected-a"].vpc_id == aws_vpc.this["main"].id
    )
    error_message = var.defaults.error_message
  }

  assert {
    condition = (
      aws_subnet.this["main-protected-c"].vpc_id == aws_vpc.this["main"].id
    )
    error_message = var.defaults.error_message
  }

  assert {
    condition = (
      aws_subnet.this["main-protected-d"].vpc_id == aws_vpc.this["main"].id
    )
    error_message = var.defaults.error_message
  }

  assert {
    condition = (
      aws_subnet.this["misc-intra-a"].vpc_id == aws_vpc.this["misc"].id
    )
    error_message = var.defaults.error_message
  }

  assert {
    condition = (
      aws_subnet.this["misc-intra-c"].vpc_id == aws_vpc.this["misc"].id
    )
    error_message = var.defaults.error_message
  }

  assert {
    condition = (
      aws_subnet.this["misc-intra-d"].vpc_id == aws_vpc.this["misc"].id
    )
    error_message = var.defaults.error_message
  }
}

run "integration_test_aws_route_table_works" {
  # ref: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table
  command = apply

  assert {
    condition = (
      aws_route_table.this["main"].vpc_id == aws_vpc.this["main"].id
    )
    error_message = var.defaults.error_message
  }

  assert {
    condition = (
      aws_route_table.this["misc"].vpc_id == aws_vpc.this["misc"].id
    )
    error_message = var.defaults.error_message
  }
}

run "integration_test_aws_route_table_association_works" {
  # ref: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association
  command = apply

  assert {
    condition = (
      aws_route_table_association.this["main-protected-a"].subnet_id == aws_subnet.this["main-protected-a"].id
    )
    error_message = var.defaults.error_message
  }

  assert {
    condition = (
      aws_route_table_association.this["main-protected-a"].route_table_id == aws_route_table.this["main"].id
    )
    error_message = var.defaults.error_message
  }

  assert {
    condition = (
      aws_route_table_association.this["main-protected-c"].subnet_id == aws_subnet.this["main-protected-c"].id
    )
    error_message = var.defaults.error_message
  }

  assert {
    condition = (
      aws_route_table_association.this["main-protected-c"].route_table_id == aws_route_table.this["main"].id
    )
    error_message = var.defaults.error_message
  }

  assert {
    condition = (
      aws_route_table_association.this["main-protected-d"].subnet_id == aws_subnet.this["main-protected-d"].id
    )
    error_message = var.defaults.error_message
  }

  assert {
    condition = (
      aws_route_table_association.this["main-protected-d"].route_table_id == aws_route_table.this["main"].id
    )
    error_message = var.defaults.error_message
  }
  assert {
    condition = (
      aws_route_table_association.this["misc-intra-a"].subnet_id == aws_subnet.this["misc-intra-a"].id
    )
    error_message = var.defaults.error_message
  }

  assert {
    condition = (
      aws_route_table_association.this["misc-intra-a"].route_table_id == aws_route_table.this["misc"].id
    )
    error_message = var.defaults.error_message
  }

  assert {
    condition = (
      aws_route_table_association.this["misc-intra-c"].subnet_id == aws_subnet.this["misc-intra-c"].id
    )
    error_message = var.defaults.error_message
  }

  assert {
    condition = (
      aws_route_table_association.this["misc-intra-c"].route_table_id == aws_route_table.this["misc"].id
    )
    error_message = var.defaults.error_message
  }

  assert {
    condition = (
      aws_route_table_association.this["misc-intra-d"].subnet_id == aws_subnet.this["misc-intra-d"].id
    )
    error_message = var.defaults.error_message
  }

  assert {
    condition = (
      aws_route_table_association.this["misc-intra-d"].route_table_id == aws_route_table.this["misc"].id
    )
    error_message = var.defaults.error_message
  }
}

run "integration_test_aws_vpc_endpoint_interface_works" {
  command = apply

  assert {
    condition = (
      aws_vpc_endpoint.interface["main-ecr-api"].vpc_id == aws_vpc.this["main"].id
    )
    error_message = var.defaults.error_message
  }

  assert {
    condition = (
      aws_vpc_endpoint.interface["main-ecr-dkr"].vpc_id == aws_vpc.this["main"].id
    )
    error_message = var.defaults.error_message
  }

  assert {
    condition = (
      aws_vpc_endpoint.interface["misc-ecr-api"].vpc_id == aws_vpc.this["misc"].id
    )
    error_message = var.defaults.error_message
  }

  assert {
    condition = (
      aws_vpc_endpoint.interface["misc-ecr-dkr"].vpc_id == aws_vpc.this["misc"].id
    )
    error_message = var.defaults.error_message
  }
}
