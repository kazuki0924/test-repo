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

run "unit_test_aws_ecr_repository_works_microservices_shared_resources_dev" {
  # ref: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecr_registry_scanning_configuration
  command = plan

  variables {
    is_test = true
    common  = var.defaults.common
  }

  assert {
    condition = (
      aws_ecr_repository.this["baseimage"].name == "fleet-control-baseimage-delete-me"
    )
    error_message = var.defaults.error_message
  }

  assert {
    condition = (
      aws_ecr_repository.this["baseimage"].force_delete == true
    )
    error_message = var.defaults.error_message
  }

  assert {
    condition = (
      aws_ecr_repository.this["baseimage"].image_tag_mutability == "MUTABLE"
    )
    error_message = var.defaults.error_message
  }

  assert {
    condition = (
      length(aws_ecr_repository.this["baseimage"].encryption_configuration) == 1
    )
    error_message = var.defaults.error_message
  }

  assert {
    condition = (
      one(aws_ecr_repository.this["baseimage"].encryption_configuration).encryption_type == "KMS"
    )
    error_message = var.defaults.error_message
  }

  assert {
    condition = (
      length(aws_ecr_repository.this["baseimage"].image_scanning_configuration) == 1
    )
    error_message = var.defaults.error_message
  }

  assert {
    condition = (
      one(aws_ecr_repository.this["baseimage"].image_scanning_configuration).scan_on_push == true
    )
    error_message = var.defaults.error_message
  }

  assert {
    condition = (
      aws_ecr_repository.this["baseimage"].tags.name == "fleet-control-baseimage-delete-me"
    )
    error_message = var.defaults.error_message
  }

  assert {
    condition = (
      aws_ecr_repository.this["baseimage"].tags_all.env == "dev"
    )
    error_message = var.defaults.error_message
  }

  assert {
    condition = (
      aws_ecr_repository.this["stub-intra-api"].name == "fleet-control-stub-intra-api-delete-me"
    )
    error_message = var.defaults.error_message
  }

  assert {
    condition = (
      aws_ecr_repository.this["stub-intra-api"].tags.name == "fleet-control-stub-intra-api-delete-me"
    )
    error_message = var.defaults.error_message
  }
}

run "unit_test_aws_ecr_repository_works_per_microservice_resources_dev" {
  # ref: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecr_registry_scanning_configuration
  command = plan

  variables {
    is_test                    = true
    common                     = var.per_microservice.common
    per_microservice_resources = var.per_microservice.per_microservice_resources
    is_microservice            = var.per_microservice.is_microservice
  }

  assert {
    condition = (
      aws_ecr_repository.this["test-microservice"].name == "test-microservice-delete-me"
    )
    error_message = var.defaults.error_message
  }

  assert {
    condition = (
      aws_ecr_repository.this["test-microservice"].tags.name == "test-microservice-delete-me"
    )
    error_message = var.defaults.error_message
  }
}

run "unit_test_aws_ecr_repository_works_microservices_shared_resources_prod" {
  # ref: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecr_registry_scanning_configuration
  command = plan

  variables {
    is_test = true
    common  = var.prod.common
  }

  assert {
    condition = (
      aws_ecr_repository.this["baseimage"].force_delete == false
    )
    error_message = var.defaults.error_message
  }

  assert {
    condition = (
      aws_ecr_repository.this["baseimage"].image_tag_mutability == "IMMUTABLE"
    )
    error_message = var.defaults.error_message
  }

  assert {
    condition = (
      length(aws_ecr_repository.this["baseimage"].image_scanning_configuration) == 1
    )
    error_message = var.defaults.error_message
  }

  assert {
    condition = (
      one(aws_ecr_repository.this["baseimage"].image_scanning_configuration).scan_on_push == false
    )
    error_message = var.defaults.error_message
  }

  assert {
    condition = (
      aws_ecr_repository.this["baseimage"].tags_all.env == "prod"
    )
    error_message = var.defaults.error_message
  }
}

run "unit_test_aws_ecr_lifecycle_policy_works_dev" {
  # ref: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecr_lifecycle_policy
  command = plan

  variables {
    is_test = true
    common  = var.defaults.common
  }

  assert {
    condition = (
      length(jsondecode(aws_ecr_lifecycle_policy.this["baseimage"].policy).rules) == 1
    )
    error_message = var.defaults.error_message
  }

  assert {
    condition = (
      one(jsondecode(aws_ecr_lifecycle_policy.this["baseimage"].policy).rules).description == "image_count"
    )
    error_message = var.defaults.error_message
  }

  assert {
    condition = (
      one(jsondecode(aws_ecr_lifecycle_policy.this["baseimage"].policy).rules).rulePriority == 1
    )
    error_message = var.defaults.error_message
  }

  assert {
    condition = (
      one(jsondecode(aws_ecr_lifecycle_policy.this["baseimage"].policy).rules).action.type == "expire"
    )
    error_message = var.defaults.error_message
  }

  assert {
    condition = (
      one(jsondecode(aws_ecr_lifecycle_policy.this["baseimage"].policy).rules).selection.countNumber == 100
    )
    error_message = var.defaults.error_message
  }

  assert {
    condition = (
      one(jsondecode(aws_ecr_lifecycle_policy.this["baseimage"].policy).rules).selection.countType == "imageCountMoreThan"
    )
    error_message = var.defaults.error_message
  }

  assert {
    condition = (
      one(jsondecode(aws_ecr_lifecycle_policy.this["baseimage"].policy).rules).selection.tagStatus == "any"
    )
    error_message = var.defaults.error_message
  }

  assert {
    condition = (
      aws_ecr_lifecycle_policy.this["baseimage"].repository == "fleet-control-baseimage-delete-me"
    )
    error_message = var.defaults.error_message
  }
}

run "unit_test_aws_ecr_lifecycle_policy_works_prod" {
  # ref: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecr_lifecycle_policy
  command = plan

  variables {
    is_test = true
    common  = var.prod.common
  }

  assert {
    condition = (
      one(jsondecode(aws_ecr_lifecycle_policy.this["baseimage"].policy).rules).selection.countNumber == 100
    )
    error_message = var.defaults.error_message
  }
}
