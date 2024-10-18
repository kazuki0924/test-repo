# requirements:
# - `terragrunt init` ran in infra/terraform/{provider}/environments/dev/{module}
# - `terraform init` ran in infra/terraform/{provider}/modules/{module}

# refs:
# - https://developer.hashicorp.com/terraform/language/tests
# - https://developer.hashicorp.com/terraform/cli/commands/test
# - https://developer.hashicorp.com/terraform/cli/test
# - https://developer.hashicorp.com/terraform/language/tests#modules

run "unit_test_coventional_commit_regex_works" {
  command = plan

  variables {
    is_test = true
    common  = var.defaults.common
  }

  assert {
    condition = (
      can(regex(var.rulesets.conventional_commits.regex, "feat: add new feature"))
    )
    error_message = var.defaults.error_message
  }

  assert {
    condition = (
      can(regex(var.rulesets.conventional_commits.regex, "feat!: breaking change"))
    )
    error_message = var.defaults.error_message
  }

  assert {
    condition = (
      can(regex(var.rulesets.conventional_commits.regex, "fix: fixed a bug"))
    )
    error_message = var.defaults.error_message
  }

  assert {
    condition = (
      can(regex(var.rulesets.conventional_commits.regex, "docs: update README"))
    )
    error_message = var.defaults.error_message
  }

  assert {
    condition = (
      can(regex(var.rulesets.conventional_commits.regex, "feat(microservice1): with scope"))
    )
    error_message = var.defaults.error_message
  }

  assert {
    condition = (
      can(regex(var.rulesets.conventional_commits.regex, "feat(microservice1)!: scope with breaking change"))
    )
    error_message = var.defaults.error_message
  }

  assert {
    condition = (
      can(regex(var.rulesets.conventional_commits.regex, "feat(microservice1, microservice2)!: multiple scopes delimited by comma and space"))
    )
    error_message = var.defaults.error_message
  }

  assert {
    condition = (
      can(regex(var.rulesets.conventional_commits.regex, "feat(microservice1,microservice2)!: multiple scopes delimited by comma"))
    )
    error_message = var.defaults.error_message
  }

  assert {
    condition = (
      can(regex(var.rulesets.conventional_commits.regex, "feat(microservice1, microservice2, microservice3, microservice4, microservice5, microservice6, microservice7, microservice8, microservice9, microservice10, microservice11, microservice12, microservice13, microservice14, microservice15, microservice16, microservice17, microservice18, microservice19, microservice20)!: very long scope is ok"))
    )
    error_message = var.defaults.error_message
  }
}

run "unit_test_coventional_commit_regex_errors" {
  command = plan

  assert {
    condition = (
      !can(regex(var.rulesets.conventional_commits.regex, "no type"))
    )
    error_message = var.defaults.error_message
  }

  assert {
    condition = (
      !can(regex(var.rulesets.conventional_commits.regex, "hoge: invalid type"))
    )
    error_message = var.defaults.error_message
  }

  assert {
    condition = (
      !can(regex(var.rulesets.conventional_commits.regex, "feat: very loooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooong commit message"))
    )
    error_message = var.defaults.error_message
  }

  assert {
    condition = (
      !can(regex(var.rulesets.conventional_commits.regex, "feat: ends with dot."))
    )
    error_message = var.defaults.error_message
  }

  assert {
    condition = (
      !can(regex(var.rulesets.conventional_commits.regex, "feat:no spacing after colon"))
    )
    error_message = var.defaults.error_message
  }

  assert {
    condition = (
      !can(regex(var.rulesets.conventional_commits.regex, "feat (cicd): space between type and scope"))
    )
    error_message = var.defaults.error_message
  }

  assert {
    condition = (
      !can(regex(var.rulesets.conventional_commits.regex, "!feat: bad breaking change placement"))
    )
    error_message = var.defaults.error_message
  }

  assert {
    condition = (
      !can(regex(var.rulesets.conventional_commits.regex, "feat!(infra): bad breaking change placement"))
    )
    error_message = var.defaults.error_message
  }
}

run "unit_test_semver_regex_works" {
  command = plan

  assert {
    condition = (
      can(regex(var.rulesets.semver_tags.regex, "micro-service-app-v0.0.0"))
    )
    error_message = var.defaults.error_message
  }

  assert {
    condition = (
      can(regex(var.rulesets.semver_tags.regex, "micro-service-infra-v0.11.0"))
    )
    error_message = var.defaults.error_message
  }

  assert {
    condition = (
      can(regex(var.rulesets.semver_tags.regex, "infra-terraform-v0.0.111"))
    )
    error_message = var.defaults.error_message
  }

  assert {
    condition = (
      can(regex(var.rulesets.semver_tags.regex, "infra-cicd-v111.222.333"))
    )
    error_message = var.defaults.error_message
  }

  assert {
    condition = (
      can(regex(var.rulesets.semver_tags.regex, "v1.0.0"))
    )
    error_message = var.defaults.error_message
  }

  assert {
    condition = (
      can(regex(var.rulesets.semver_tags.regex, "v1.0.0-alpha"))
    )
    error_message = var.defaults.error_message
  }
}

run "unit_test_semver_regex_errors" {
  command = plan

  assert {
    condition = (
      !can(regex(var.rulesets.semver_tags.regex, "hoge"))
    )
    error_message = var.defaults.error_message
  }

  assert {
    condition = (
      !can(regex(var.rulesets.semver_tags.regex, "1.0.0"))
    )
    error_message = var.defaults.error_message
  }

  assert {
    condition = (
      !can(regex(var.rulesets.semver_tags.regex, "micro-service-app-1.0.0"))
    )
    error_message = var.defaults.error_message
  }

  assert {
    condition = (
      !can(regex(var.rulesets.semver_tags.regex, "micro-service-infra v1.0.0"))
    )
    error_message = var.defaults.error_message
  }

  assert {
    condition = (
      !can(regex(var.rulesets.semver_tags.regex, "v0.0.00"))
    )
    error_message = var.defaults.error_message
  }

  assert {
    condition = (
      !can(regex(var.rulesets.semver_tags.regex, "v0.0"))
    )
    error_message = var.defaults.error_message
  }
}
