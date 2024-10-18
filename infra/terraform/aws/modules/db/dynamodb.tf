# symlinked from:
# - infra/terraform/aws/modules/db/dynamodb.tf
# symlinked to:
# - infra/terraform/aws/modules/init/dynamodb.tf
# see "Override Files" on how to override this file
# https://developer.hashicorp.com/terraform/language/files/override

# AWS Managed Keyでは出来なくてCustomer Managed Keyでは出来るKMSの細かい制御を必要とする要件が無い為、Risk Acceptedとする
# trivy:ignore:AVD-AWS-0025

locals {
  dynamodb_tables = [
    for dynamodb in var.dynamodb : merge(dynamodb, {
      name = (
        dynamodb.naming_convention == "T<02d>_SYSTEM-ENV-DDB-TABLE-NAME" ?
        "${format("T%02d_%s-%s-DDB-%s",
          index(var.dynamodb, dynamodb) + 1,
          "WVPP-XEV",
          upper(var.common.env),
        dynamodb.name_short)}${var.common.suffix}" :
        "${var.common.prefix}${dynamodb.resource_prefix}${dynamodb.name_short}${var.common.suffix}"
      )
    })
  ]
}

resource "aws_dynamodb_table" "this" {
  # ref: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/dynamodb_table
  for_each = { for dynamodb in local.dynamodb_tables : dynamodb.name_short => dynamodb }

  name                        = each.value.name
  billing_mode                = "PAY_PER_REQUEST"
  deletion_protection_enabled = lookup(each.value.deletion_protection_enabled, var.common.env, true)
  hash_key                    = each.value.hash_key
  range_key                   = each.value.range_key

  dynamic "attribute" {
    for_each = each.value.attributes

    content {
      name = attribute.value.name
      type = attribute.value.type
    }
  }

  dynamic "global_secondary_index" {
    for_each = each.value.global_secondary_index != null ? each.value.global_secondary_index : []

    content {
      name            = global_secondary_index.value.name
      hash_key        = global_secondary_index.value.hash_key
      range_key       = global_secondary_index.value.range_key
      projection_type = global_secondary_index.value.projection_type
    }
  }

  dynamic "ttl" {
    for_each = each.value.ttl != null ? [each.value.ttl] : []

    content {
      attribute_name = ttl.value.attribute_name
      enabled        = ttl.value.enabled
    }
  }

  point_in_time_recovery {
    enabled = true
  }

  server_side_encryption {
    enabled     = true
    kms_key_arn = null # default aws/dynamodb AWS managed key
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
    create = each.value.timeouts[var.common.env].create
    update = each.value.timeouts[var.common.env].update
    delete = each.value.timeouts[var.common.env].delete
  }
}
