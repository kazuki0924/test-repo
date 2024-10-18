variable "dynamodb" {
  description = "Amazon DynamoDB"
  sensitive   = false
  nullable    = false

  type = list(object({
    resource_prefix = optional(string, "ddb-")
    # 命名規則
    name_short        = optional(string, "EVSE-NAME")
    naming_convention = optional(string, "T<02d>_SYSTEM-ENV-DDB-TABLE-NAME")
    table_number      = optional(number, null)
    hash_key          = optional(string, "chargerId")
    range_key         = optional(string, null)
    attributes = optional(list(object({
      name = optional(string, "chargerId")
      type = optional(string, "S")
    })), [])
    global_secondary_index = optional(list(object({
      name            = optional(string, "GSI-XEV-NAME")
      hash_key        = optional(string, "hashKey")
      range_key       = optional(string, null)
      projection_type = optional(string, "ALL")
    })), null)
    ttl = optional(object({
      attribute_name = optional(string, "ttlTimestamp")
      enabled        = optional(bool, true)
    }), null)
    deletion_protection_enabled = optional(object({
      dev  = optional(bool, false)
      test = optional(bool, true)
      stg  = optional(bool, true)
      prod = optional(bool, true)
    }), {})
    timeouts = optional(object({
      dev = optional(object({
        create = optional(string, "10m")
        update = optional(string, "10m")
        delete = optional(string, "10m")
      }), {})
      test = optional(object({
        create = optional(string, "30m") # terraform's default
        update = optional(string, "60m") # terraform's default
        delete = optional(string, "10m") # terraform's default
      }), {})
      stg = optional(object({
        create = optional(string, "30m") # terraform's default
        update = optional(string, "60m") # terraform's default
        delete = optional(string, "10m") # terraform's default
      }), {})
      prod = optional(object({
        create = optional(string, "60m")
        update = optional(string, "60m")
        delete = optional(string, "60m")
      }), {})
    }), {})
  }))

  validation {
    condition = anytrue([
      for dynamodb in var.dynamodb : dynamodb.naming_convention == null ? true :
      contains([
        # インフラ管理のDynamoDBテーブル
        # e.g. xev-vpp-evems-dev-tfstate-lock
        "system-subsystem-env-table-name",
        # アプリケーションのDynamoDBテーブル
        # e.g. T01_WVPP-XEV-DEV-DDB-EVSE-MASTER
        "T<02d>_SYSTEM-ENV-DDB-TABLE-NAME",
      ], dynamodb.naming_convention)
    ])
    error_message = "dynamodb.naming_conventionは次のいずれかを指定してください: system-subsystem-env-table-name, T<02d>_SYSTEM-ENV-DDB-TABLE-NAME"
  }

  default = [
    {
      naming_convention = "system-subsystem-env-table-name"
      name_short        = "tfstate-lock"
      hash_key          = "LockID"
      attributes = [
        {
          name = "LockID"
          type = "S"
        }
      ]
    }
  ]
}
