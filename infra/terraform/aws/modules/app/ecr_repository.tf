# [ECR (Elastic Container Registry)]

# symlinked from:
# - infra/terraform/{provider}/modules/{module}/{resource_group}.tf
# symlinked to:
# - src/{subdomain}/{microservice}/infra/terraform/{provider}/modules/{module}/{resource_group}.tf
# see "Override Files" on how to override this file
# https://developer.hashicorp.com/terraform/language/files/override

locals {
  ecr = {
    repositories = flatten([
      for repository in [
        for r in local.app_common.resources.ecr.repositories : (
          r.name_short != null ?
          merge(r, { name_short = "${local.app_common.resource_prefix}${r.name_short}" }) :
          merge(r, { name_short = var.common.microservice })
        )
      ] :
      merge(repository, {
        name = "${var.common.prefix}${local.app_common.resource_prefix}${repository.name_short}${var.common.suffix}"
      })
    ])
  }
}

# 作業ブランチの動作確認用に"latest", "{branch}-latest"タグの上書きをdev環境では許可する
# trivy:ignore:AVD-AWS-0031
resource "aws_ecr_repository" "this" {
  # ref: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecr_repository
  for_each = {
    for repository in local.ecr.repositories : repository.name_short => repository
  }

  name                 = each.value.name
  force_delete         = lookup(var.ecr.force_delete, var.common.env, false)
  image_tag_mutability = lookup(var.ecr.image_tag_mutability, var.common.env, "IMMUTABLE")

  encryption_configuration {
    encryption_type = "KMS"
    kms_key         = null # default AWS managed key
  }

  image_scanning_configuration {
    scan_on_push = lookup(
      var.ecr.image_scanning_configuration.scan_on_push,
      var.common.env,
      false
    )
  }

  tags = {
    name       = each.value.name
    Name       = each.value.name
    name_short = each.value.name_short
  }

  lifecycle {
    ignore_changes = [
      tags["created_at"],
      tags["created_date"]
    ]
  }

  timeouts {
    delete = var.ecr.timeouts[var.common.env].delete
  }
}

# ライフサイクルポリシーの設定
data "aws_ecr_lifecycle_policy_document" "this" {
  # ref: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ecr_lifecycle_policy_document
  rule {
    priority    = 1
    description = "image_count"

    selection {
      tag_status   = "any"
      count_type   = "imageCountMoreThan"
      count_number = var.ecr.lifecycles.image_count # e.g. 100
    }

    action {
      type = "expire"
    }
  }
}

resource "aws_ecr_lifecycle_policy" "this" {
  # ref: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecr_lifecycle_policy
  depends_on = [aws_ecr_repository.this, data.aws_ecr_lifecycle_policy_document.this]
  for_each   = aws_ecr_repository.this

  repository = each.value.name
  policy     = data.aws_ecr_lifecycle_policy_document.this.json
}

# NOTE: WON'T_DO:
# aws_ecr_replication_configuration
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecr_replication_configuration
# aws_ecr_registry_policy
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecr_registry_policy
