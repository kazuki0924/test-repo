# [ECR (Elastic Container Registry)]

# refs:
# - https://docs.aws.amazon.com/AmazonECR/latest/userguide/image-scanning-enhanced-enabling.html
# - https://aws.amazon.com/blogs/containers/container-scanning-updates-in-amazon-ecr-private-registries-using-amazon-inspector/
# - https://docs.aws.amazon.com/AmazonECR/latest/APIReference/API_RegistryScanningRule.html
resource "aws_ecr_registry_scanning_configuration" "this" {
  # ref: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecr_registry_scanning_configuration
  scan_type = "ENHANCED"

  rule {
    scan_frequency = "SCAN_ON_PUSH"
    repository_filter {
      filter      = "*"
      filter_type = "WILDCARD"
    }
  }

  rule {
    scan_frequency = "CONTINUOUS_SCAN"
    repository_filter {
      filter      = "*"
      filter_type = "WILDCARD"
    }
  }
}

# NOTE: WONT_DO
# - aws_ecr_pull_through_cache_rule
#   - https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecr_pull_through_cache_rule
# - aws_ecr_repository_creation_template
#   -https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecr_repository_creation_template
