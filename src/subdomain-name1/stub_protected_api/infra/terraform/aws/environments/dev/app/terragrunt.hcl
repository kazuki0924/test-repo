include "root" {
  path   = "${get_repo_root()}/infra/terraform/shared/terragrunt.hcl"
  expose = true
}

terraform {
  source = "${get_path_to_repo_root()}/src//${trimprefix(get_path_from_repo_root(), "src")}"

  # [main.tf]
  # infra/terraform/aws/environments/dev/app/main.tf ->
  # src/subdomain-name1/microservice-name1/iinfra/terraform/aws/environments/dev/app/main.tf
  after_hook "symlink_main_tf_from_microservices_shared_app_root_module_dev_to_per_microservice_app_root_module" {
    commands = ["terragrunt-read-config"]
    execute = [
      "ln",
      "-s", # create symlink
      "-f", # force
      "-v", # verbose
      "${include.root.locals.relpath_to_repo_root_from_root_module}/infra/terraform/aws/environments/dev/app/main.tf",
      "${include.root.locals.root_module}/main.tf"
    ]
    suppress_stdout = true
  }

  # [variables_app.tf]
  # infra/terraform/aws/modules/app/variables_app.tf ->
  # src/subdomain-name1/microservice-name1/infra/terraform/aws/environments/dev/app/variables_app.tf
  after_hook "symlink_variables_app_tf_from_microservices_shared_app_root_module_to_per_microservice_app_root_module" {
    commands = ["terragrunt-read-config"]
    execute = [
      "ln",
      "-s", # create symlink
      "-f", # force
      "-v", # verbose
      "${include.root.locals.relpath_to_repo_root_from_root_module}/infra/terraform/aws/modules/app/variables_app.tf",
      "${include.root.locals.root_module}/variables_app.tf"
    ]
    suppress_stdout = true
  }

  # infra/terraform/aws/modules/app/variables_app.tf ->
  # src/subdomain-name1/microservice-name1/infra/terraform/aws/modules/app/variables_app.tf
  after_hook "symlink_variables_app_tf_from_microservices_shared_app_infra_module_to_per_microservice_app_infra_module" {
    commands = ["terragrunt-read-config"]
    execute = [
      "ln",
      "-s", # create symlink
      "-f", # force
      "-v", # verbose
      "${include.root.locals.relpath_to_repo_root_from_infra_module}/infra/terraform/aws/modules/app/variables_app.tf",
      "${include.root.locals.relpath_to_infra_module_from_root_module}/variables_app.tf"
    ]
    suppress_stdout = true
  }

  # [locals_app.tf]
  # infra/terraform/aws/modules/app/locals_app.tf ->
  # src/subdomain-name1/microservice-name1/infra/terraform/aws/environments/dev/app/locals_app.tf
  after_hook "symlink_locals_app_tf_from_microservices_shared_app_root_module_to_per_microservice_app_root_module" {
    commands = ["terragrunt-read-config"]
    execute = [
      "ln",
      "-s", # create symlink
      "-f", # force
      "-v", # verbose
      "${include.root.locals.relpath_to_repo_root_from_root_module}/infra/terraform/aws/modules/app/locals_app.tf",
      "${include.root.locals.root_module}/locals_app.tf"
    ]
    suppress_stdout = true
  }

  # infra/terraform/aws/modules/app/locals_app.tf ->
  # src/subdomain-name1/microservice-name1/infra/terraform/aws/modules/app/locals_app.tf
  after_hook "symlink_locals_app_tf_from_microservices_shared_app_infra_module_to_per_microservice_app_infra_module" {
    commands = ["terragrunt-read-config"]
    execute = [
      "ln",
      "-s", # create symlink
      "-f", # force
      "-v", # verbose
      "${include.root.locals.relpath_to_repo_root_from_infra_module}/infra/terraform/aws/modules/app/locals_app.tf",
      "${include.root.locals.relpath_to_infra_module_from_root_module}/locals_app.tf"
    ]
    suppress_stdout = true
  }

  # [data_app.tf]
  # infra/terraform/aws/modules/app/data_app.tf ->
  # src/subdomain-name1/microservice-name1/infra/terraform/aws/environments/dev/app/data_app.tf
  after_hook "symlink_data_app_tf_from_microservices_shared_app_root_module_to_per_microservice_app_root_module" {
    commands = ["terragrunt-read-config"]
    execute = [
      "ln",
      "-s", # create symlink
      "-f", # force
      "-v", # verbose
      "${include.root.locals.relpath_to_repo_root_from_root_module}/infra/terraform/aws/modules/app/data_app.tf",
      "${include.root.locals.root_module}/data_app.tf"
    ]
    suppress_stdout = true
  }

  # infra/terraform/aws/modules/app/data_app.tf ->
  # src/subdomain-name1/microservice-name1/infra/terraform/aws/modules/app/data_app.tf
  after_hook "symlink_data_app_tf_from_microservices_shared_app_infra_module_to_per_microservice_app_infra_module" {
    commands = ["terragrunt-read-config"]
    execute = [
      "ln",
      "-s", # create symlink
      "-f", # force
      "-v", # verbose
      "${include.root.locals.relpath_to_repo_root_from_infra_module}/infra/terraform/aws/modules/app/data_app.tf",
      "${include.root.locals.relpath_to_infra_module_from_root_module}/data_app.tf"
    ]
    suppress_stdout = true
  }

  # [data_per_microservice.tf]
  # src/subdomain-name1/microservice-name1/infra/terraform/shared/data_per_microservice.tf ->
  # src/subdomain-name1/microservice-name1/infra/terraform/aws/environments/dev/app/data_per_microservice.tf
  after_hook "symlink_data_per_microservice_tf_from_terraform_shared_to_per_microservice_root_module" {
    commands = ["terragrunt-read-config"]
    execute = [
      "ln",
      "-s", # create symlink
      "-f", # force
      "-v", # verbose
      "${include.root.locals.relpath_to_repo_root_from_root_module}/infra/terraform/shared/data_per_microservice.tf",
      "${include.root.locals.root_module}/data_per_microservice.tf"
    ]
    suppress_stdout = true
  }

  after_hook "symlink_data_per_microservice_tf_from_terraform_shared_to_per_microservice_infra_module" {
    commands = ["terragrunt-read-config"]
    execute = [
      "ln",
      "-s", # create symlink
      "-f", # force
      "-v", # verbose
      "${include.root.locals.relpath_to_repo_root_from_infra_module}/infra/terraform/shared/data_per_microservice.tf",
      "${include.root.locals.relpath_to_infra_module_from_root_module}/data_per_microservice.tf"
    ]
    suppress_stdout = true
  }

  # [locals_per_microservice.tf]
  # src/subdomain-name1/microservice-name1/infra/terraform/shared/locals_per_microservice.tf ->
  # src/subdomain-name1/microservice-name1/infra/terraform/aws/environments/dev/app/locals_per_microservice.tf
  after_hook "symlink_locals_per_microservice_tf_from_terraform_shared_to_per_microservice_root_module" {
    commands = ["terragrunt-read-config"]
    execute = [
      "ln",
      "-s", # create symlink
      "-f", # force
      "-v", # verbose
      "${include.root.locals.relpath_to_repo_root_from_root_module}/infra/terraform/shared/locals_per_microservice.tf",
      "${include.root.locals.root_module}/locals_per_microservice.tf"
    ]
    suppress_stdout = true
  }

  after_hook "symlink_locals_per_microservice_tf_from_terraform_shared_to_per_microservice_infra_module" {
    commands = ["terragrunt-read-config"]
    execute = [
      "ln",
      "-s", # create symlink
      "-f", # force
      "-v", # verbose
      "${include.root.locals.relpath_to_repo_root_from_infra_module}/infra/terraform/shared/locals_per_microservice.tf",
      "${include.root.locals.relpath_to_infra_module_from_root_module}/locals_per_microservice.tf"
    ]
    suppress_stdout = true
  }

  # [alb.tf]
  # infra/terraform/aws/modules/app/alb.tf ->
  # src/subdomain-name1/microservice-name1/infra/terraform/aws/modules/app/alb.tf
  after_hook "symlink_alb_tf_from_microservices_shared_app_infra_module_to_per_microservice_app_infra_module" {
    commands = ["terragrunt-read-config"]
    execute = [
      "ln",
      "-s", # create symlink
      "-f", # force
      "-v", # verbose
      "${include.root.locals.relpath_to_repo_root_from_infra_module}/infra/terraform/aws/modules/app/alb.tf",
      "${include.root.locals.relpath_to_infra_module_from_root_module}/alb.tf"
    ]
    suppress_stdout = true
  }

  # [cwlogs.tf]
  # infra/terraform/aws/modules/app/cwlogs.tf ->
  # src/subdomain-name1/microservice-name1/infra/terraform/aws/modules/app/cwlogs.tf
  after_hook "symlink_cwlogs_tf_from_microservices_shared_app_infra_module_to_per_microservice_app_infra_module" {
    commands = ["terragrunt-read-config"]
    execute = [
      "ln",
      "-s", # create symlink
      "-f", # force
      "-v", # verbose
      "${include.root.locals.relpath_to_repo_root_from_infra_module}/infra/terraform/aws/modules/app/cwlogs.tf",
      "${include.root.locals.relpath_to_infra_module_from_root_module}/cwlogs.tf"
    ]
    suppress_stdout = true
  }

  # [ecr_repository.tf]
  # infra/terraform/aws/modules/app/ecr_repository.tf ->
  # src/subdomain-name1/microservice-name1/infra/terraform/aws/modules/app/ecr_repository.tf
  after_hook "symlink_ecr_repository_tf_from_microservices_shared_app_infra_module_to_per_microservice_app_infra_module" {
    commands = ["terragrunt-read-config"]
    execute = [
      "ln",
      "-s", # create symlink
      "-f", # force
      "-v", # verbose
      "${include.root.locals.relpath_to_repo_root_from_infra_module}/infra/terraform/aws/modules/app/ecr_repository.tf",
      "${include.root.locals.relpath_to_infra_module_from_root_module}/ecr_repository.tf"
    ]
    suppress_stdout = true
  }

  # [ecs_service.tf]
  # infra/terraform/aws/modules/app/ecs_service.tf ->
  # src/subdomain-name1/microservice-name1/infra/terraform/aws/modules/app/ecs_service.tf
  after_hook "symlink_ecs_service_tf_from_microservices_shared_app_infra_module_to_per_microservice_app_infra_module" {
    commands = ["terragrunt-read-config"]
    execute = [
      "ln",
      "-s", # create symlink
      "-f", # force
      "-v", # verbose
      "${include.root.locals.relpath_to_repo_root_from_infra_module}/infra/terraform/aws/modules/app/ecs_service.tf",
      "${include.root.locals.relpath_to_infra_module_from_root_module}/ecs_service.tf"
    ]
    suppress_stdout = true
  }

  # [ecs_scheduler.tf]
  # infra/terraform/aws/modules/app/ecs_scheduler.tf ->
  # src/subdomain-name1/microservice-name1/infra/terraform/aws/modules/app/ecs_scheduler.tf
  after_hook "symlink_ecs_scheduler_tf_from_microservices_shared_app_infra_module_to_per_microservice_app_infra_module" {
    commands = ["terragrunt-read-config"]
    execute = [
      "ln",
      "-s", # create symlink
      "-f", # force
      "-v", # verbose
      "${include.root.locals.relpath_to_repo_root_from_infra_module}/infra/terraform/aws/modules/app/ecs_scheduler.tf",
      "${include.root.locals.relpath_to_infra_module_from_root_module}/ecs_scheduler.tf"
    ]
    suppress_stdout = true
  }

  # [ecs_task_def.tf]
  # infra/terraform/aws/modules/app/ecs_task_def.tf ->
  # src/subdomain-name1/microservice-name1/infra/terraform/aws/modules/app/ecs_task_def.tf
  after_hook "symlink_ecs_task_def_tf_from_microservices_shared_app_infra_module_to_per_microservice_app_infra_module" {
    commands = ["terragrunt-read-config"]
    execute = [
      "ln",
      "-s", # create symlink
      "-f", # force
      "-v", # verbose
      "${include.root.locals.relpath_to_repo_root_from_infra_module}/infra/terraform/aws/modules/app/ecs_task_def.tf",
      "${include.root.locals.relpath_to_infra_module_from_root_module}/ecs_task_def.tf"
    ]
    suppress_stdout = true
  }
}

inputs = {
  # provided from release-please in CI/CD
  image_tag = get_env("CONTAINER_DEFINITIONS_IMAGE_TAG", "v0.1.0")
  per_microservice_resources = {
    alb = {
      listener_rules = [
        {
          # source .env.microservice
          path_pattern = get_env("LISTENER_RULE_PATH_PATTERN", "/api/vi/resourcePath*") # microservices should follow /api/v1/{resource_path} pattern
        }
      ]
    }
  }
}
