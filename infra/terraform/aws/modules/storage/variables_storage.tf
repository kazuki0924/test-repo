variable "s3" {
  description = "Amazon Simple Storage Service(Amazon S3)"
  sensitive   = false
  nullable    = false

  type = list(object({
    resource_prefix = optional(string, "s3-")
    name_short      = optional(string, "tfstate")
    usecase         = optional(string, "tfstate") # determine which configs/policies to apply to by this attribute. e.g. lifecycle configs
    policies        = optional(list(string), null)
    access_log = optional(object({
      prefix = optional(string, "access/bucket/tfstate")
      bucket = optional(object({
        resource_prefix = optional(string, "s3-")
        name_short      = optional(string, "ops-log")
      }), {})
      # ref: https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-properties-s3-bucket-partitionedprefix.html
      partition_date_source = optional(string, "DeliveryTime")
      lifecycle = optional(object({
        expiration = optional(object({
          days            = optional(number, 731) # 2 years
          noncurrent_days = optional(number, 30)
        }), {})
        delete = optional(object({
          days_after_initiation = optional(number, 7)
        }), {})
      }), {})
    }), {})
    ownership = optional(object({
      # ref: https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/aws-properties-s3-bucket-ownershipcontrolsrule.html
      object_ownership = optional(string, "BucketOwnerPreferred")
    }), {})
    force_destroy = optional(object({
      dev  = optional(bool, true)
      test = optional(bool, false)
      stg  = optional(bool, false)
      prod = optional(bool, false)
    }), {})
    timeouts = optional(object({
      dev = optional(object({
        create = optional(string, "10m")
        read   = optional(string, "10m")
        update = optional(string, "10m")
        delete = optional(string, "20m")
      }), {})
      test = optional(object({
        create = optional(string, "20m") # terraform's default
        read   = optional(string, "20m") # terraform's default
        update = optional(string, "20m") # terraform's default
        delete = optional(string, "60m") # terraform's default
      }), {})
      stg = optional(object({
        create = optional(string, "20m") # terraform's default
        read   = optional(string, "20m") # terraform's default
        update = optional(string, "20m") # terraform's default
        delete = optional(string, "60m") # terraform's default
      }), {})
      prod = optional(object({
        create = optional(string, "30m")
        read   = optional(string, "30m")
        update = optional(string, "30m")
        delete = optional(string, "60m")
      }), {})
    }), {})
  }))

  # バケットアクセスログは`ops-log`バケットに集約する
  # e.g.
  # - ALBアクセスログ、NLBアクセスログはaccess-log-alb、access-log-nlbに格納
  # - access-log-alb、access-log-nlbのバケットアクセスログはops-logに格納
  # - tfstateのバケットアクセスログはops-logに格納
  # - ops-log自身のバケットアクセスログもops-logに格納
  default = [
    {
      name_short = "tfstate"
      usecase    = "tfstate"
      access_log = {
        bucket = {
          name_short = "ops-log"
        }
        prefix = "access/bucket/tfstate"
      }
    },
    {
      name_short = "ops-log"
      usecase    = "log"
      access_log = {
        bucket = {
          name_short = "ops-log"
        }
        prefix = "access/bucket/ops-log"
      }
    },
  ]

  validation {
    condition = alltrue([
      for s3 in var.s3 : contains([
        "DeliveryTime",
        "EventTime",
      ], s3.access_log.partition_date_source)
    ])
    error_message = "s3.partition_date_sourceは次のいずれかを指定してください: DeliveryTime, EventTime"
  }

  validation {
    condition = alltrue([
      for s3 in var.s3 : contains([
        "ObjectWriter",
        "BucketOwnerPreferred",
        "BucketOwnerEnforced",
      ], s3.ownership.object_ownership)
    ])
    error_message = "s3.ownership.object_ownershipは次のいずれかを指定してください: ObjectWriter, BucketOwnerPreferred, BucketOwnerEnforced"
  }
}

variable "policy_sets" {
  description = "S3 Bucket Policy Sets"
  sensitive   = false
  nullable    = true

  type = object({
    default : optional(list(string), [
      "deny_outdated_tls",
      "deny_insecure_transport",
      "deny_unencrypted_object_uploads",
      "deny_incorrect_encryption_headers",
      "deny_incorrect_kms_key_sse",
      "allow_logging_s3_amazonaws_com",
      "allow_delivery_logs_amazonaws_com",
    ])
    # NOTE: terraform tfstate backend, ELB access logはAES-256のみ対応している
    tfstate : optional(list(string), [
      "deny_outdated_tls",
      "deny_insecure_transport",
      "deny_unencrypted_object_uploads",
      "deny_incorrect_encryption_headers",
      "allow_logging_s3_amazonaws_com",
      "allow_delivery_logs_amazonaws_com",
    ])
    elb : optional(list(string), [
      "deny_outdated_tls",
      "deny_insecure_transport",
      "allow_logging_s3_amazonaws_com",
      "allow_delivery_logs_amazonaws_com",
      "allow_elb_service_account",
    ])
  })

  default = {}
}
