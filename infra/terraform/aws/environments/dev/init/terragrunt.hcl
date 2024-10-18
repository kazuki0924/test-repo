include "root" {
  path   = "${get_repo_root()}/infra/terraform/shared/terragrunt.hcl"
  expose = true
}

locals {
  sops = {
    kms = {
      primary = {
        resource_prefix = "kms-"
        name_short      = "sops"
      }
      replica = {
        resource_prefix = "kms-replica-"
        name_short      = "sops"
      }
    }
  }
  kms_sops_alias = {
    primary = "${include.root.locals.prefix}${local.sops.kms.primary.resource_prefix}${local.sops.kms.primary.name_short}"
    replica = "${include.root.locals.prefix}${local.sops.kms.replica.resource_prefix}${local.sops.kms.replica.name_short}"
  }
  is_github_oidc_provider_exists = run_cmd(
    "--terragrunt-quiet",
    "bash",
    "-c",
    "[[ -n $(aws iam list-open-id-connect-providers --query 'OpenIDConnectProviderList[?ends_with(Arn, `oidc-provider/${include.root.locals.github.oidc.provider}`)]' --output text) ]] && echo true || echo false"
  )
  is_sops_kms_exists = run_cmd(
    "--terragrunt-quiet",
    "bash",
    "-c",
    "[[ -n $(aws kms list-aliases --query 'Aliases[?ends_with(AliasName, `sops`)]' --output text) ]] && echo true || echo false"
  )
  sops_kms_key_id = local.is_sops_kms_exists == "true" ? run_cmd(
    "--terragrunt-quiet",
    "bash",
    "-c",
    "aws kms describe-key --key-id alias/${local.kms_sops_alias.primary} --query KeyMetadata.KeyId --output text"
  ) : ""
  is_subdomain_aws_route53_zone_exists = run_cmd(
    "--terragrunt-quiet",
    "bash",
    "-c",
    "[[ -n $(aws route53 list-hosted-zones --query 'HostedZones[?starts_with(Name, `${include.root.locals.api.this.domain[include.root.locals.env].main}`) == `true`]' --output text) ]] && echo true || echo false"
  )
  route53_zone_subdomain_id = local.is_subdomain_aws_route53_zone_exists == "true" ? trimprefix(run_cmd(
    "--terragrunt-quiet",
    "bash",
    "-c",
    "aws route53 list-hosted-zones --query 'HostedZones[?starts_with(Name, `${include.root.locals.api.this.domain[include.root.locals.env].main}`) == `true`].Id' --output text"
  ), "/hostedzone/") : ""
}

# [import.tf]
# e.g. infra/terraform/aws/modules/init/shared/import.tf.tftpl -> infra/terraform/aws/environments/dev/init/import.tf
generate "import_tf_from_provider_shared_to_infra_module" {
  path      = "${include.root.locals.root_module}/import_generated.tf"
  if_exists = "overwrite_terragrunt"
  contents = templatefile("${get_repo_root()}/infra/terraform/${include.root.locals.tf_provider}/shared/templatefile/${include.root.locals.module}/import.tf.tftpl", {
    s3_bucket_tfstate_id                  = include.root.locals.s3_bucket_tfstate_id
    dynamodb_table_tfstate_lock_id        = include.root.locals.dynamodb_table_tfstate_lock_id
    is_github_oidc_provider_exists        = local.is_github_oidc_provider_exists
    iam_role_github_actions_id            = "${include.root.locals.prefix}${include.root.locals.github.iam_role.resource_prefix}${include.root.locals.github.iam_role.name_short}"
    iam_openid_connect_provider_github_id = "arn:aws:iam::${include.root.locals.aws.account_id}:oidc-provider/${include.root.locals.github.oidc.provider}"
    is_sops_kms_exist                     = local.is_sops_kms_exists
    kms_sops_alias_primary                = local.kms_sops_alias.primary
    kms_sops_alias_replica                = local.kms_sops_alias.replica
    sops_kms_key_id                       = local.sops_kms_key_id
    is_subdomain_aws_route53_zone_exists  = local.is_subdomain_aws_route53_zone_exists
    route53_zone_subdomain_id             = local.route53_zone_subdomain_id
  })
}

terraform {
  source = "${get_path_to_repo_root()}/infra/terraform//${trimprefix(get_path_from_repo_root(), "infra/terraform/")}"

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

  # [dynamodb.tf]
  # infra/terraform/aws/modules/db/dynamodb.tf -> infra/terraform/aws/modules/init/dynamodb.tf
  after_hook "symlink_dynamodb_tf_from_db_infra_module_to_init_infra_module" {
    commands = ["terragrunt-read-config"]
    execute = [
      "ln",
      "-s", # create symlink
      "-f", # force
      "-v", # verbose
      "${include.root.locals.relpath_to_repo_root_from_infra_module}/infra/terraform/aws/modules/db/dynamodb.tf",
      "${include.root.locals.relpath_to_infra_module_from_root_module}/dynamodb.tf"
    ]
    suppress_stdout = true
  }

  # [variables_db.tf]
  # infra/terraform/aws/modules/db/variables_db.tf -> infra/terraform/aws/modules/init/varibales_db.tf
  after_hook "symlink_variables_db_tf_from_db_infra_module_to_init_infra_module" {
    commands = ["terragrunt-read-config"]
    execute = [
      "ln",
      "-s", # create symlink
      "-f", # force
      "-v", # verbose
      "${include.root.locals.relpath_to_repo_root_from_infra_module}/infra/terraform/aws/modules/db/variables_db.tf",
      "${include.root.locals.relpath_to_infra_module_from_root_module}/variables_db.tf"
    ]
    suppress_stdout = true
  }

  # infra/terraform/aws/modules/db/variables_db.tf -> infra/terraform/aws/environments/dev/init/varibales_db.tf
  after_hook "symlink_variables_db_tf_from_db_infra_module_to_init_root_module" {
    commands = ["terragrunt-read-config"]
    execute = [
      "ln",
      "-s", # create symlink
      "-f", # force
      "-v", # verbose
      "${include.root.locals.relpath_to_repo_root_from_root_module}/infra/terraform/aws/modules/db/variables_db.tf",
      "${include.root.locals.root_module}/variables_db.tf"
    ]
    suppress_stdout = true
  }

  # [s3.tf]
  # infra/terraform/aws/modules/storage/s3.tf -> infra/terraform/aws/modules/init/s3.tf
  after_hook "symlink_s3_tf_from_storage_infra_module_to_init_infra_module" {
    commands = ["terragrunt-read-config"]
    execute = [
      "ln",
      "-s", # create symlink
      "-f", # force
      "-v", # verbose
      "${include.root.locals.relpath_to_repo_root_from_infra_module}/infra/terraform/aws/modules/storage/s3.tf",
      "${include.root.locals.relpath_to_infra_module_from_root_module}/s3.tf"
    ]
    suppress_stdout = true
  }

  # [variables_storage.tf]
  # infra/terraform/aws/modules/storage/variables_storage.tf -> infra/terraform/aws/modules/init/variables_storage.tf
  after_hook "symlink_variables_storage_tf_from_storage_infra_module_to_init_infra_module" {
    commands = ["terragrunt-read-config"]
    execute = [
      "ln",
      "-s", # create symlink
      "-f", # force
      "-v", # verbose
      "${include.root.locals.relpath_to_repo_root_from_infra_module}/infra/terraform/aws/modules/storage/variables_storage.tf",
      "${include.root.locals.relpath_to_infra_module_from_root_module}/variables_storage.tf"
    ]
    suppress_stdout = true
  }

  # infra/terraform/aws/modules/storage/variables_storage.tf -> infra/terraform/aws/environments/dev/init/variables_storage.tf
  after_hook "symlink_variables_storage_tf_from_storage_infra_module_to_init_root_module" {
    commands = ["terragrunt-read-config"]
    execute = [
      "ln",
      "-s", # create symlink
      "-f", # force
      "-v", # verbose
      "${include.root.locals.relpath_to_repo_root_from_root_module}/infra/terraform/aws/modules/storage/variables_storage.tf",
      "${include.root.locals.root_module}/variables_storage.tf"
    ]
    suppress_stdout = true
  }
}

inputs = {
  oidc_provider = include.root.locals.github.oidc.provider
}
