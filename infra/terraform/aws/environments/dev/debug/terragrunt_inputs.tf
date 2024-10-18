# This file is for debugging terragrunt only. It is not intended to be used in production.
# Running `terragrunt plan` and seeing the results of the outputs are always recommanded after making changes to any of the terragrunt.hcl files.

output "common" {
  value = jsonencode(var.common)
}

output "is_microservice" {
  value = var.is_microservice
}

output "is_ci" {
  value = var.is_ci
}

variable "system" {
  type = string
}

output "system" {
  value = var.system
}

# subsystem
variable "subsystem" {
  type = string
}

output "subsystem" {
  value = var.subsystem
}

# origin
variable "origin" {
  type = string
}

output "origin" {
  value = var.origin
}

# org
variable "org" {
  type = string
}

output "org" {
  value = var.org
}

# repo
variable "repo" {
  type = string
}

output "repo" {
  value = var.repo
}

# org_repo
variable "org_repo" {
  type = string
}

output "org_repo" {
  value = var.org_repo
}

# domain
variable "domain" {
  type = string
}

output "domain" {
  value = var.domain
}

# root_module
variable "root_module" {
  type = string
}

output "root_module" {
  value = var.root_module
}

# repo_root
variable "repo_root" {
  type = string
}

output "repo_root" {
  value = var.repo_root
}

# abspath_to_root_module_from_repo_root
variable "abspath_to_root_module_from_repo_root" {
  type = string
}

output "abspath_to_root_module_from_repo_root" {
  value = var.abspath_to_root_module_from_repo_root
}

# module
variable "module" {
  type = string
}

output "module" {
  value = var.module
}

# env
variable "env" {
  type = string
}

output "env" {
  value = var.env
}

# tf_provider
variable "tf_provider" {
  type = string
}

output "tf_provider" {
  value = var.tf_provider
}

# abspath_to_root_module_from_repo_root_forwardslash_split
variable "abspath_to_root_module_from_repo_root_forwardslash_split" {
  type = list(string)
}

output "abspath_to_root_module_from_repo_root_forwardslash_split" {
  value = var.abspath_to_root_module_from_repo_root_forwardslash_split
}

# subdomain
variable "subdomain" {
  type = string
}

output "subdomain" {
  value = var.subdomain
}

# microservice
variable "microservice" {
  type = string
}

output "microservice" {
  value = var.microservice
}

# prefix
variable "prefix" {
  type = string
}

output "prefix" {
  value = var.prefix
}

# relpath_to_repo_root_from_root_module
variable "relpath_to_repo_root_from_root_module" {
  type = string
}

output "relpath_to_repo_root_from_root_module" {
  value = var.relpath_to_repo_root_from_root_module
}

# relpath_to_repo_root_from_root_module_tests
variable "relpath_to_repo_root_from_root_module_tests" {
  type = string
}

output "relpath_to_repo_root_from_root_module_tests" {
  value = var.relpath_to_repo_root_from_root_module_tests
}

# relpath_to_repo_root_from_infra_module
variable "relpath_to_repo_root_from_infra_module" {
  type = string
}

output "relpath_to_repo_root_from_infra_module" {
  value = var.relpath_to_repo_root_from_infra_module
}

# relpath_to_repo_root_from_infra_module_tests
variable "relpath_to_repo_root_from_infra_module_tests" {
  type = string
}

output "relpath_to_repo_root_from_infra_module_tests" {
  value = var.relpath_to_repo_root_from_infra_module_tests
}

# relpath_to_infra_module_from_root_module
variable "relpath_to_infra_module_from_root_module" {
  type = string
}

output "relpath_to_infra_module_from_root_module" {
  value = var.relpath_to_infra_module_from_root_module
}

# relpath_to_provider_shared_from_root_module
variable "relpath_to_provider_shared_from_root_module" {
  type = string
}

output "relpath_to_provider_shared_from_root_module" {
  value = var.relpath_to_provider_shared_from_root_module
}

# relpath_to_provider_shared_from_root_module_tests
variable "relpath_to_provider_shared_from_root_module_tests" {
  type = string
}

output "relpath_to_provider_shared_from_root_module_tests" {
  value = var.relpath_to_provider_shared_from_root_module_tests
}

# relpath_to_provider_shared_from_infra_module
variable "relpath_to_provider_shared_from_infra_module" {
  type = string
}

output "relpath_to_provider_shared_from_infra_module" {
  value = var.relpath_to_provider_shared_from_infra_module
}

# relpath_to_provider_shared_from_infra_module_tests
variable "relpath_to_provider_shared_from_infra_module_tests" {
  type = string
}

output "relpath_to_provider_shared_from_infra_module_tests" {
  value = var.relpath_to_provider_shared_from_infra_module_tests
}

# relpath_to_microservices_shared_root_module_from_per_microservice_root_module
variable "relpath_to_microservices_shared_root_module_from_per_microservice_root_module" {
  type = string
}

output "relpath_to_microservices_shared_root_module_from_per_microservice_root_module" {
  value = var.relpath_to_microservices_shared_root_module_from_per_microservice_root_module
}

# relpath_to_microservices_shared_infra_module_from_per_microservice_infra_module
variable "relpath_to_microservices_shared_infra_module_from_per_microservice_infra_module" {
  type = string
}

output "relpath_to_microservices_shared_infra_module_from_per_microservice_infra_module" {
  value = var.relpath_to_microservices_shared_infra_module_from_per_microservice_infra_module
}

# versions
variable "versions" {
  type = any
}

output "versions" {
  value = var.versions
}

# aws
variable "aws" {
  type = any
}

output "aws" {
  value = var.aws
}

# backend
variable "backend" {
  type = any
}

output "backend" {
  value = var.backend
}

# api
output "api" {
  value = var.api
}

# is_github_oidc_provider_exists
variable "is_github_oidc_provider_exists" {
  type = bool
}

output "is_github_oidc_provider_exists" {
  value = var.is_github_oidc_provider_exists
}

# is_sops_kms_exists
variable "is_sops_kms_exists" {
  type = bool
}

output "is_sops_kms_exists" {
  value = var.is_sops_kms_exists
}

# is_subdomain_aws_route53_zone_exists
variable "is_subdomain_aws_route53_zone_exists" {
  type = bool
}

output "is_subdomain_aws_route53_zone_exists" {
  value = var.is_subdomain_aws_route53_zone_exists
}

# [executed from infra/terraform/aws/environments/dev/debug/terragrunt.hcl]

# path_relative_to_include() from root module
variable "path_relative_to_include_from_root_module" {
  type = string
}

output "path_relative_to_include_from_root_module" {
  value = var.path_relative_to_include_from_root_module
}

# path_relative_from_include() from root module
variable "path_relative_from_include_from_root_module" {
  type = string
}

output "path_relative_from_include_from_root_module" {
  value = var.path_relative_from_include_from_root_module
}

# get_repo_root() from root module
variable "get_repo_root_from_root_module" {
  type = string
}

output "get_repo_root_from_root_module" {
  value = var.get_repo_root_from_root_module
}

# get_path_from_repo_root() from root module
variable "get_path_from_repo_root_from_root_module" {
  type = string
}

output "get_path_from_repo_root_from_root_module" {
  value = var.get_path_from_repo_root_from_root_module
}

# get_path_to_repo_root() from root module
variable "get_path_to_repo_root_from_root_module" {
  type = string
}

output "get_path_to_repo_root_from_root_module" {
  value = var.get_path_to_repo_root_from_root_module
}

# get_terragrunt_dir() from root module
variable "get_terragrunt_dir_from_root_module" {
  type = string
}

output "get_terragrunt_dir_from_root_module" {
  value = var.get_terragrunt_dir_from_root_module
}

# get_working_dir() from root module
variable "get_working_dir_from_root_module" {
  type = string
}

output "get_working_dir_from_root_module" {
  value = var.get_working_dir_from_root_module
}

# get_parent_terragrunt_dir() from root module
variable "get_parent_terragrunt_dir_from_root_module" {
  type = string
}

output "get_parent_terragrunt_dir_from_root_module" {
  value = var.get_parent_terragrunt_dir_from_root_module
}

# get_original_terragrunt_dir() from root module
variable "get_original_terragrunt_dir_from_root_module" {
  type = string
}

output "get_original_terragrunt_dir_from_root_module" {
  value = var.get_original_terragrunt_dir_from_root_module
}

# [executed from infra/terraform/shared/terragrunt.hcl]

# path_relative_to_include() from terraform shared
variable "path_relative_to_include" {
  type = string
}

output "path_relative_to_include_from_terraform_shared" {
  value = var.path_relative_to_include
}

# path_relative_from_include() from terraform shared
variable "path_relative_from_include" {
  type = string
}

output "path_relative_from_include_from_terraform_shared" {
  value = var.path_relative_from_include
}

# get_repo_root() from terraform shared
variable "get_repo_root" {
  type = string
}

output "get_repo_root_from_terraform_shared" {
  value = var.get_repo_root
}

# get_path_from_repo_root() from terraform shared
variable "get_path_from_repo_root" {
  type = string
}

output "get_path_from_repo_root_from_terraform_shared" {
  value = var.get_path_from_repo_root
}

# get_path_to_repo_root() from terraform shared
variable "get_path_to_repo_root" {
  type = string
}

output "get_path_to_repo_root_from_terraform_shared" {
  value = var.get_path_to_repo_root
}

# get_terragrunt_dir() from terraform shared
variable "get_terragrunt_dir" {
  type = string
}

output "get_terragrunt_dir_from_terraform_shared" {
  value = var.get_terragrunt_dir
}

# get_working_dir() from terraform shared
variable "get_working_dir" {
  type = string
}

output "get_working_dir_from_terraform_shared" {
  value = var.get_working_dir
}

# get_parent_terragrunt_dir() from terraform shared
variable "get_parent_terragrunt_dir" {
  type = string
}

output "get_parent_terragrunt_dir_from_terraform_shared" {
  value = var.get_parent_terragrunt_dir
}

# get_original_terragrunt_dir() from terraform shared
variable "get_original_terragrunt_dir" {
  type = string
}

output "get_original_terragrunt_dir_from_terraform_shared" {
  value = var.get_original_terragrunt_dir
}
