variable "github" {
  description = "GitHub"
  sensitive   = false
  nullable    = true

  type = object({
    # OIDC対象とするリポジトリ一覧の指定
    repository_allow_list = optional(set(string), ["*"])
    iam_role = optional(object({
      name_short = optional(string, "github-actions")
    }), {})
  })

  default = {}
}

variable "oidc_provider" {
  description = "OpenID Connect Provider"
  sensitive   = false
  nullable    = true

  type = string

  # default = "token.actions.githubusercontent.com/stargate"
  default = null
}

variable "kms" {
  description = "AWS Key Management Service"
  sensitive   = false
  nullable    = true

  type = object({
    primary = optional(object({
      resource_prefix = optional(string, "kms-")
      name_short      = optional(string, "sops")
      deletion_window_in_days = optional(object({
        dev  = optional(number, 7)
        test = optional(number, 7)
        stg  = optional(number, 30)
        prod = optional(number, 30)
      }), {})
    }), {})
    replica = optional(object({
      resource_prefix = optional(string, "kms-replica-")
      name_short      = optional(string, "sops")
      deletion_window_in_days = optional(object({
        dev  = optional(number, 7)
        test = optional(number, 7)
        stg  = optional(number, 30)
        prod = optional(number, 30)
      }), {})
    }), {})
  })

  default = {}
}
