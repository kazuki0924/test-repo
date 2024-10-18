# ref: https://developer.hashicorp.com/terraform/language/providers/configuration
provider "aws" {
  # ref: https://registry.terraform.io/providers/hashicorp/aws/latest/docs
  region = var.common.aws.region

  default_tags {
    tags = merge({ region = var.common.aws.region }, var.common.aws.default_tags)
  }
}

provider "aws" {
  alias = "secondary"
  # ref: https://registry.terraform.io/providers/hashicorp/aws/latest/docs
  region = var.common.aws.secondary_region

  default_tags {
    tags = merge({ region = var.common.aws.secondary_region }, var.common.aws.default_tags)
  }
}
