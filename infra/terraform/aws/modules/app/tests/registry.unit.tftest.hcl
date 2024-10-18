# requirements:
# - `terragrunt init` ran in infra/terraform/{provider}/environments/dev/{module}
# - `terraform init` ran in infra/terraform/{provider}/modules/{module}

# refs:
# - https://developer.hashicorp.com/terraform/language/tests
# - https://developer.hashicorp.com/terraform/cli/commands/test
# - https://developer.hashicorp.com/terraform/cli/test
# - https://developer.hashicorp.com/terraform/language/tests#modules

override_data {
  target = data.aws_vpc.this
  values = {
    cidr_block = "0.0.0.0/0"
  }
}

override_data {
  target = data.aws_subnets.this
}

override_data {
  target = data.aws_security_group.this
}

override_data {
  target = data.aws_lb.alb
}

override_data {
  target = data.aws_lb_listener.alb
  values = {
    arn = "arn:aws:elasticloadbalancing:::name"
  }
}

override_data {
  target = data.aws_service_discovery_dns_namespace.this
}

override_data {
  target = data.aws_s3_bucket.this
}

override_data {
  target = data.external.container_def_envs_json
  values = {
    result = { "json" : "{\"key\": \"value\"}" }
  }
}

run "unit_test_aws_ecr_registry_scanning_configuration_works" {
  # ref: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecr_registry_scanning_configuration
  command = plan

  variables {
    is_test = true
    common  = var.defaults.common
  }

  assert {
    condition = (
      aws_ecr_registry_scanning_configuration.this.scan_type == "ENHANCED"
    )
    error_message = var.defaults.error_message
  }

  assert {
    condition = (
      length(aws_ecr_registry_scanning_configuration.this.rule) == 2
    )
    error_message = var.defaults.error_message
  }

  assert {
    condition = (
      length(
        [
          for rule in aws_ecr_registry_scanning_configuration.this.rule :
          rule if rule.scan_frequency == "SCAN_ON_PUSH"
        ]
      ) == 1
    )
    error_message = var.defaults.error_message
  }

  assert {
    condition = (
      length(
        [
          for repository_filter in
          one(
            [
              for rule in aws_ecr_registry_scanning_configuration.this.rule :
              rule if rule.scan_frequency == "SCAN_ON_PUSH"
            ]
          ).repository_filter :
      repository_filter if repository_filter.filter == "*"]) == 1
    )
    error_message = var.defaults.error_message
  }

  assert {
    condition = (
      length(
        [
          for repository_filter in
          one(
            [
              for rule in aws_ecr_registry_scanning_configuration.this.rule :
              rule if rule.scan_frequency == "SCAN_ON_PUSH"
            ]
          ).repository_filter :
          repository_filter if repository_filter.filter_type == "WILDCARD"
        ]
      ) == 1
    )
    error_message = var.defaults.error_message
  }

  assert {
    condition = (
      length(
        [
          for rule in aws_ecr_registry_scanning_configuration.this.rule :
          rule if rule.scan_frequency == "CONTINUOUS_SCAN"
        ]
      ) == 1
    )
    error_message = var.defaults.error_message
  }

  assert {
    condition = (
      length(
        [
          for repository_filter in
          one(
            [
              for rule in aws_ecr_registry_scanning_configuration.this.rule :
              rule if rule.scan_frequency == "CONTINUOUS_SCAN"
            ]
          ).repository_filter :
          repository_filter if repository_filter.filter == "*"
        ]
      ) == 1
    )
    error_message = var.defaults.error_message
  }

  assert {
    condition = (
      length(
        [
          for repository_filter in
          one(
            [
              for rule in aws_ecr_registry_scanning_configuration.this.rule :
              rule if rule.scan_frequency == "CONTINUOUS_SCAN"
            ]
          ).repository_filter :
          repository_filter if repository_filter.filter_type == "WILDCARD"
        ]
      ) == 1
    )
    error_message = var.defaults.error_message
  }
}
