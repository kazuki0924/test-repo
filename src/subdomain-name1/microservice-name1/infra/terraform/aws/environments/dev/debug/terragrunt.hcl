include "root" {
  path   = "${get_repo_root()}/infra/terraform/shared/terragrunt.hcl"
  expose = true
}

terraform {
  source = "${get_path_to_repo_root()}/src//${trimprefix(get_path_from_repo_root(), "src")}"

  # [terragrunt_inputs.tf]
  # infra/terraform/aws/environments/dev/debug/terragrunt_inputs.tf ->
  # src/subdomain-name1/microservice-name1/infra/terraform/aws/environments/dev/debug/terragrunt_inputs.tf
  after_hook "symlink_terragrunt_inputs_tf_from_microservices_shared_debug_root_module_to_per_microservice_debug_root_module" {
    commands = ["terragrunt-read-config"]
    execute = [
      "ln",
      "-s", # create symlink
      "-f", # force
      "-v", # verbose
      "${include.root.locals.relpath_to_repo_root_from_root_module}/infra/terraform/${include.root.locals.tf_provider}/environments/${include.root.locals.env}/debug/terragrunt_inputs.tf",
      "${include.root.locals.root_module}/terragrunt_inputs.tf"
    ]
    suppress_stdout = true
  }
}

inputs = merge(
  include.root.locals,
  {
    path_relative_to_include_from_root_module    = path_relative_to_include()
    path_relative_from_include_from_root_module  = path_relative_from_include()
    get_repo_root_from_root_module               = get_repo_root()
    get_path_from_repo_root_from_root_module     = get_path_from_repo_root()
    get_path_to_repo_root_from_root_module       = get_path_to_repo_root()
    get_terragrunt_dir_from_root_module          = get_terragrunt_dir()
    get_working_dir_from_root_module             = get_working_dir()
    get_parent_terragrunt_dir_from_root_module   = get_parent_terragrunt_dir()
    get_original_terragrunt_dir_from_root_module = get_original_terragrunt_dir()
  }
)
