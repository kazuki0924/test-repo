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

run "unit_test_aws_ecs_cluster_works" {
  # ref: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group
  command = plan

  variables {
    is_test = true
    common  = var.defaults.common
  }

  assert {
    condition = (
      aws_ecs_cluster.this["main"].name == "xev-vpp-evems-dev-main-fleet-control-cluster-delete-me"
    )
    error_message = var.defaults.error_message
  }
}