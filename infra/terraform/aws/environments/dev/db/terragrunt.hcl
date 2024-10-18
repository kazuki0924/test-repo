include "root" {
  path   = "${get_repo_root()}/infra/terraform/shared/terragrunt.hcl"
  expose = true
}

terraform {
  source = "${get_path_to_repo_root()}/infra//${trimprefix(get_path_from_repo_root(), "infra")}"

  # [variables_{module}.tf]
  # e.g. infra/terraform/aws/modules/app/variables_app.tf -> infra/terraform/aws/environments/dev/app/variables_app.tf
  after_hook "symlink_varibales_module_tf_from_infra_module_to_root_module" {
    commands = ["terragrunt-read-config"]
    execute = [
      "ln",
      "-s", # create symlink
      "-f", # force
      "-v", # verbose
      "${include.root.locals.relpath_to_infra_module_from_root_module}/variables_${include.root.locals.module}.tf",
      "${include.root.locals.root_module}/variables_${include.root.locals.module}.tf"
    ]
    suppress_stdout = true
  }
}

dependencies {
  paths = [
    # tfstate backends, etc. needs to be created
    "../init"
  ]
}
