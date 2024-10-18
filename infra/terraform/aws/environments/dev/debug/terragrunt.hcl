include "root" {
  path   = "${get_repo_root()}/infra/terraform/shared/terragrunt.hcl"
  expose = true
}

terraform {
  source = "${get_path_to_repo_root()}/infra//${trimprefix(get_path_from_repo_root(), "infra")}"
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
