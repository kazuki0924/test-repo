locals {
  kms = {
    primary = {
      name = "${var.common.prefix}${var.kms.primary.resource_prefix}${var.kms.primary.name_short}${var.common.suffix}"
    }
    replica = {
      name = "${var.common.prefix}${var.kms.replica.resource_prefix}${var.kms.replica.name_short}${var.common.suffix}"
    }
  }
  create_kms = !var.is_test
}

# [KMS (Key Management)]
resource "aws_kms_key" "sops" {
  # ref: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_key
  count = local.create_kms ? 1 : 0

  description             = "KMS Customer Managed Key for sops managed by terraform"
  enable_key_rotation     = true
  multi_region            = true
  rotation_period_in_days = 365
  deletion_window_in_days = lookup(var.kms.primary.deletion_window_in_days, var.common.env, 30)

  tags = {
    name            = local.kms.primary.name
    Name            = local.kms.primary.name
    name_short      = var.kms.primary.name_short
    alias           = "alias/${local.kms.primary.name}"
    prevent_destroy = true
  }

  lifecycle {
    prevent_destroy = true
    ignore_changes = [
      tags["created_at"],
      tags["created_date"]
    ]
  }
}

resource "aws_kms_alias" "primary" {
  # ref: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_alias
  depends_on = [aws_kms_key.sops[0]]
  count      = local.create_kms ? 1 : 0

  name          = "alias/${local.kms.primary.name}"
  target_key_id = aws_kms_key.sops[0].arn

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_kms_replica_key" "sops" {
  # ref: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_replica_key
  provider   = aws.secondary
  depends_on = [aws_kms_key.sops[0]]
  count      = local.create_kms ? 1 : 0

  description             = "Multi-Region Replica Key for sops managed by terraform"
  deletion_window_in_days = lookup(var.kms.replica.deletion_window_in_days, var.common.env, 30)
  primary_key_arn         = aws_kms_key.sops[0].arn

  tags = {
    name            = local.kms.replica.name
    Name            = local.kms.replica.name
    name_short      = var.kms.replica.name_short
    alias           = "alias/${local.kms.replica.name}"
    prevent_destroy = true
  }

  lifecycle {
    prevent_destroy = true
    ignore_changes = [
      tags["created_at"],
      tags["created_date"]
    ]
  }
}

resource "aws_kms_alias" "replica" {
  # ref: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_alias
  provider   = aws.secondary
  depends_on = [aws_kms_replica_key.sops[0]]
  count      = local.create_kms ? 1 : 0

  name          = "alias/${local.kms.replica.name}"
  target_key_id = aws_kms_replica_key.sops[0].arn

  lifecycle {
    prevent_destroy = true
  }
}
