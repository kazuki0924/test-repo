variable "nlb" {
  description = "Elastic Load Balancing: Network Load Balancer"
  sensitive   = false
  nullable    = true

  type = object({
    name_short      = optional(string, "fleet") # var.common.subsystem + name_short has to be less than 16 characters
    resource_prefix = optional(string, "nlb-")
    enable_deletion_protection = optional(object({
      dev  = optional(bool, false)
      test = optional(bool, true)
      stg  = optional(bool, true)
      prod = optional(bool, true)
    }), {})
    enforce_security_group_inbound_rules_on_private_link_traffic = optional(object({
      dev  = optional(string, "off")
      test = optional(string, "on")
      stg  = optional(string, "on")
      prod = optional(string, "on")
    }), {})
    vpc_endpoint_service = optional(object({
      resource_prefix = optional(string, "nlb-vpce-")
      acceptance_required = optional(object({
        dev  = optional(bool, false)
        test = optional(bool, true)
        stg  = optional(bool, true)
        prod = optional(bool, true)
      }), {})
    }), {})
    listener = optional(object({
      resource_prefix = optional(string, "nlb-l-")
    }), {})
    listener_rule = optional(object({
      resource_prefix = optional(string, "nlb-lr-")
    }), {})
    target_group = optional(object({
      resource_prefix = optional(string, "ntg-")
    }), {})
    access_log = optional(object({
      prefix = optional(string, "access/nlb")
      bucket = optional(object({
        resource_prefix = optional(string, "s3-")
        name_short      = optional(string, "nlb-access-log")
      }), {})
    }), {})
    connection_log = optional(object({
      prefix = optional(string, "connection/nlb")
      bucket = optional(object({
        resource_prefix = optional(string, "s3-")
        name_short      = optional(string, "nlb-access-log")
      }), {})
    }), {})
  })

  validation {
    condition     = length(var.common.subsystem) + length(var.nlb.name_short) < 16
    error_message = "var.common.subsystem + var.nlb.name_short must be less than 16 characters"
  }

  default = {}
}

variable "route53" {
  description = "Amazon Route 53"
  sensitive   = false
  nullable    = true

  type = object({
    enable_deletion_protection = optional(object({
      dev  = optional(bool, false)
      test = optional(bool, true)
      stg  = optional(bool, true)
      prod = optional(bool, true)
    }), {})
  })

  default = {}
}

variable "acm" {
  description = "AWS Certificate Manager"
  sensitive   = false
  nullable    = true

  # TODO: implement
  # type = object({
  #   timeouts = optional(object({
  #     dev  = optional(bool, false)
  #     test = optional(bool, true)
  #     stg  = optional(bool, true)
  #     prod = optional(bool, true)
  #   }), {})
  # })

  default = {}
}
