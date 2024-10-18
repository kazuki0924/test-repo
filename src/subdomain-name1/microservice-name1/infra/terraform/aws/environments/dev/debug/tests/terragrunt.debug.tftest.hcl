# !CAUTION this test only works with `terragrunt test` command

# refs:
# - https://developer.hashicorp.com/terraform/language/tests
# - https://developer.hashicorp.com/terraform/cli/commands/test
# - https://developer.hashicorp.com/terraform/cli/test
# - https://developer.hashicorp.com/terraform/language/tests#modules

run "output_terragrunt_inputs" {
  command = plan

  variables {
    is_test = true
    common  = var.defaults.common
  }

  # common
  assert {
    condition = output.common == jsonencode({
      system       = "xev-vpp"
      subsystem    = "evems"
      env          = "dev"
      provider     = "aws"
      module       = "app"
      domain       = "fleet-control"
      subdomain    = null
      microservice = null
      prefix       = "xev-vpp-evems-dev-"
      repo_root    = "/home/devcontainer/workspace"
      suffix       = "-delete-me"
      aws = {
        region = "ap-northeast-1"
        default_tags = {
          system       = "xev-vpp"
          subsystem    = "evems"
          env          = "dev"
          domain       = "fleet-control"
          subdomain    = null
          microservice = null
          owner        = "wcm-eas"
          repo         = "xev-vpp-evems-fleet-control"
          managed_by   = "terraform"
          wrapped_by   = "terragrunt"
          created_at   = null
          created_date = null
        }
      }
      github = {
        org   = "wcm-eas"
        repo  = "xev-vpp-evems-fleet-control"
        phase = "IN_ACTIVE_DEVELOPMENT"
      }
      ecs = {
        default = {
          port = 8000
        }
      }
    })
    error_message = var.defaults.error_message
  }

  # is_ci
  assert {
    condition     = output.is_ci == false
    error_message = var.defaults.error_message
  }

  # is_microservice
  assert {
    condition     = output.is_microservice == true
    error_message = var.defaults.error_message
  }

  # module
  assert {
    condition     = output.module == "debug"
    error_message = var.defaults.error_message
  }

  # env
  assert {
    condition     = output.env == "dev"
    error_message = var.defaults.error_message
  }

  # provider
  assert {
    condition     = output.tf_provider == "aws"
    error_message = var.defaults.error_message
  }

  # subdomain
  assert {
    condition     = output.subdomain == "subdomain-name1"
    error_message = var.defaults.error_message
  }

  # microservice
  assert {
    condition     = output.microservice == "microservice-name1"
    error_message = var.defaults.error_message
  }

  # relative path to repo root from root module
  assert {
    condition     = output.relpath_to_repo_root_from_root_module == "../../../../../../../../.."
    error_message = var.defaults.error_message
  }

  # relative path to repo root from root module tests
  assert {
    condition     = output.relpath_to_repo_root_from_root_module_tests == "../../../../../../../../../.."
    error_message = var.defaults.error_message
  }

  # relative path to repo root from infra module
  assert {
    condition     = output.relpath_to_repo_root_from_infra_module == "../../../../../../../.."
    error_message = var.defaults.error_message
  }

  # relative path to repo root from infra module tests
  assert {
    condition     = output.relpath_to_repo_root_from_infra_module_tests == "../../../../../../../../.."
    error_message = var.defaults.error_message
  }

  # relative path to infra module from root module
  assert {
    condition     = output.relpath_to_infra_module_from_root_module == "../../../modules/debug"
    error_message = var.defaults.error_message
  }

  # relative path to provider shared from root module
  assert {
    condition     = output.relpath_to_provider_shared_from_root_module == "../../../shared"
    error_message = var.defaults.error_message
  }

  # relative path to provider shared from root module tests
  assert {
    condition     = output.relpath_to_provider_shared_from_root_module_tests == "../../../../shared"
    error_message = var.defaults.error_message
  }

  # relative path to provider shared from infra module
  assert {
    condition     = output.relpath_to_provider_shared_from_infra_module == "../../shared"
    error_message = var.defaults.error_message
  }

  # relative path to provider shared from infra module tests
  assert {
    condition     = output.relpath_to_provider_shared_from_infra_module_tests == "../../../shared"
    error_message = var.defaults.error_message
  }

  # relative path to microservices shared root module from per microservice root module
  assert {
    condition     = output.relpath_to_microservices_shared_root_module_from_per_microservice_root_module == "../../../../../../../../../infra/terraform/aws/environments/dev/debug"
    error_message = var.defaults.error_message
  }

  # relative path to microservices shared infra module from per microservice infra module
  assert {
    condition     = output.relpath_to_microservices_shared_infra_module_from_per_microservice_infra_module == "../../../../../../../../infra/terraform/aws/modules/debug"
    error_message = var.defaults.error_message
  }

  # get_repo_root()
  assert {
    condition     = output.get_repo_root_from_root_module == output.get_repo_root_from_terraform_shared
    error_message = var.defaults.error_message
  }

  # path_relative_to_include()
  # NOTE: if running terragrunt command from the root module, the output will be in the contex of the root module no matter where the terragrunt.hcl is
  # repository-level modules: "../../../../shared"
  assert {
    condition     = output.path_relative_from_include_from_root_module == "../../../../../../../../../infra/terraform/shared"
    error_message = var.defaults.error_message
  }

  assert {
    condition     = output.path_relative_from_include_from_terraform_shared == "../../../../../../../../../infra/terraform/shared"
    error_message = var.defaults.error_message
  }

  # path_relative_from_include()
  # NOTE: if running terragrunt command from the root module, the output will be in the contex of the root module no matter where the terragrunt.hcl is
  # repository-level modules: "../aws/environments/dev/debug"
  assert {
    condition     = output.path_relative_to_include_from_root_module == "../../../src/subdomain-name1/microservice-name1/infra/terraform/aws/environments/dev/debug"
    error_message = var.defaults.error_message
  }

  assert {
    condition     = output.path_relative_to_include_from_terraform_shared == "../../../src/subdomain-name1/microservice-name1/infra/terraform/aws/environments/dev/debug"
    error_message = var.defaults.error_message
  }

  # get_path_from_repo_root()
  # NOTE: if running terragrunt command from the root module, the output will be in the contex of the root module no matter where the terragrunt.hcl is
  # repository-level modules: "infra/terraform/aws/environments/dev/debug"
  assert {
    condition     = output.get_path_from_repo_root_from_root_module == "src/subdomain-name1/microservice-name1/infra/terraform/aws/environments/dev/debug"
    error_message = var.defaults.error_message
  }

  assert {
    condition     = output.get_path_from_repo_root_from_terraform_shared == "src/subdomain-name1/microservice-name1/infra/terraform/aws/environments/dev/debug"
    error_message = var.defaults.error_message
  }

  # get_path_to_repo_root()
  # NOTE: if running terragrunt command from the root module, the output will be in the contex of the root module no matter where the terragrunt.hcl is
  # repository-level modules: "../../../../../.."
  assert {
    condition     = output.get_path_to_repo_root_from_root_module == "../../../../../../../../.."
    error_message = var.defaults.error_message
  }

  assert {
    condition     = output.get_path_to_repo_root_from_terraform_shared == "../../../../../../../../.."
    error_message = var.defaults.error_message
  }

  # get_terragrunt_dir()
  # NOTE: if running terragrunt command from the root module, the output will be the root module absolute path
  # repository-level modules: format("%s/infra/terraform/aws/environments/dev/debug", output.get_repo_root_from_root_module)
  assert {
    condition = output.get_terragrunt_dir_from_root_module == format(
      "%s/src/subdomain-name1/microservice-name1/infra/terraform/aws/environments/dev/debug", output.get_repo_root_from_root_module
    )
    error_message = var.defaults.error_message
  }

  assert {
    condition = output.get_terragrunt_dir_from_terraform_shared == format(
      "%s/src/subdomain-name1/microservice-name1/infra/terraform/aws/environments/dev/debug", output.get_repo_root_from_terraform_shared
    )
    error_message = var.defaults.error_message
  }

  # get_working_dir()
  # NOTE: this is not the actual working directory of the terragrunt, if download_dir is set
  # repository-level modules: ".*/infra/terraform/aws/environments/dev/debug/\\.terragrunt-cache/[^/]+/[^/]+/terraform/aws/environments/dev/debug$",
  assert {
    # e.g. "/home/devcontainer/workspace/src/subdomain-name1/microservice-name1/infra/terraform/aws/environments/dev/debug/.terragrunt-cache/wlKE4IArwyQwe7Ifq5JT5VupUAI/MhNVwQsjzW20-UVD8TmHF5QXs-A/subdomain-name1/microservice-name1/infra/terraform/aws/environments/dev/debug"
    condition = can(
      regex(
        ".*/src/subdomain-name1/microservice-name1/infra/terraform/aws/environments/dev/debug/\\.terragrunt-cache/[^/]+/[^/]+/subdomain-name1/microservice-name1/infra/terraform/aws/environments/dev/debug$",
        output.get_working_dir_from_root_module
      )
    )
    error_message = var.defaults.error_message
  }

  assert {
    # e.g. "/home/devcontainer/workspace/src/subdomain-name1/microservice-name1/infra/terraform/aws/environments/dev/debug/.terragrunt-cache/wlKE4IArwyQwe7Ifq5JT5VupUAI/MhNVwQsjzW20-UVD8TmHF5QXs-A/subdomain-name1/microservice-name1/infra/terraform/aws/environments/dev/debug"
    condition = can(
      regex(
        ".*/src/subdomain-name1/microservice-name1/infra/terraform/aws/environments/dev/debug/\\.terragrunt-cache/[^/]+/[^/]+/subdomain-name1/microservice-name1/infra/terraform/aws/environments/dev/debug$",
        output.get_working_dir_from_root_module
      )
    )
    error_message = var.defaults.error_message
  }

  # get_original_terragrunt_dir()
  # NOTE: if running terragrunt command from the root module, the output will be the root module absolute path
  # repository-level modules: format("%s/infra/terraform/aws/environments/dev/debug", output.get_repo_root_from_root_module)
  assert {
    condition = output.get_original_terragrunt_dir_from_root_module == format(
      "%s/src/subdomain-name1/microservice-name1/infra/terraform/aws/environments/dev/debug", output.get_repo_root_from_root_module
    )
    error_message = var.defaults.error_message
  }

  assert {
    condition = output.get_original_terragrunt_dir_from_terraform_shared == format(
      "%s/src/subdomain-name1/microservice-name1/infra/terraform/aws/environments/dev/debug", output.get_repo_root_from_terraform_shared
    )
    error_message = var.defaults.error_message
  }

  # get_parent_terragrunt_dir()
  # NOTE: returns the directory included terragrunt.hcl(infra/terraform/shared/terragrunt.hcl) is in
  assert {
    condition     = output.get_parent_terragrunt_dir_from_root_module == format("%s/infra/terraform/shared", output.get_repo_root_from_root_module)
    error_message = var.defaults.error_message
  }

  assert {
    condition     = output.get_parent_terragrunt_dir_from_terraform_shared == format("%s/infra/terraform/shared", output.get_repo_root_from_terraform_shared)
    error_message = var.defaults.error_message
  }
}
