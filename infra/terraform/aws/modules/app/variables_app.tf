variable "per_microservice_resources" {
  # マイクロサービス固有となるリソース群
  description = "Microservice specific resource names"
  sensitive   = false
  nullable    = true

  type = object({
    ecs = optional(object({
      services = optional(list(object({
        # if null, var.common.microservice is used
        name_short       = optional(string, null)
        cpu              = optional(number, 256)
        memory           = optional(number, 512)
        host_port        = optional(number, 8000)
        container_port   = optional(number, 8000)
        health_check     = optional(object({ path = optional(string, "/health") }), {})
        health_check_cmd = optional(list(string), ["wget", "--no-verbose", "--spider"])
        subnet_groups = optional(list(object({
          group_name = optional(string, "intra") # if "intra", set alb
        })), [{}])
        security_groups = optional(list(object({
          name_short = optional(string, "ecs-intra")
        })), [{}])
        iam_role = optional(object({
          exec = optional(object({
            name_short = optional(string, "ecs-exec-default")
          }), {})
          task = optional(object({
            name_short = optional(string, "ecs-task-default")
          }), {})
        }), {})
      })), [{}])
      schedules = optional(list(object({
        resource_prefix = optional(string, "schedule-")
        # if null, var.common.microservice is used
        name_short                   = optional(string, null)
        cpu                          = optional(number, 256)
        memory                       = optional(number, 512)
        enabled                      = optional(bool, true)
        description                  = optional(string, "Scheduled task")
        start_date                   = optional(string, null)
        end_date                     = optional(string, null)
        schedule_expression          = optional(string, "cron(0/1 * * * ? *)")
        schedule_expression_timezone = optional(string, "UTC")
        host_port                    = optional(number, 8000)
        container_port               = optional(number, 8000)
        health_check                 = optional(object({ path = optional(string, "/health") }), {})
        health_check_cmd             = optional(list(string), ["wget", "--no-verbose", "--spider"])
        subnet_groups = optional(list(object({
          group_name = optional(string, "intra")
        })), [{}])
        security_groups = optional(list(object({
          name_short = optional(string, "ecs-intra")
        })), [{}])
        iam_role = optional(object({
          exec = optional(object({
            name_short = optional(string, "scheduler-default")
          }), {})
          task = optional(object({
            name_short = optional(string, "ecs-task-default")
          }), {})
        }), {})
      })), null)
    }), {})
    # if null, var.common.microservice is used
    ecr = optional(object({
      repositories = optional(list(object({ name_short = optional(string, null) })), [{}])
    }), {})
    cwlogs = optional(object({
      log_groups = optional(list(object({
        # if null, var.common.microservice is used
        name_short = optional(string, null)
      })), [{}])
    }), {})
    alb = optional(object({
      target_groups = optional(list(object({
        # if null, var.common.microservice is used
        name_short   = optional(string, null)
        port         = optional(number, 8000)
        health_check = optional(object({ path = optional(string, "/health") }), {})
      })), [{}])
      listener_rules = optional(list(object({
        # if null, var.common.microservice is used
        name_short   = optional(string, null)
        path_pattern = optional(string, null)
      })), [{}])
    }), {})
  })

  default = {}
}

variable "microservices_shared_resources" {
  # マイクロサービス共有となるリソース群
  description = "Names for resources shared among microservices"
  sensitive   = false
  nullable    = true

  type = object({
    ecs = optional(object({
      services = optional(list(object({
        name_short       = optional(string, null)
        cpu              = optional(number, 256)
        memory           = optional(number, 512)
        host_port        = optional(number, 8000)
        container_port   = optional(number, 8000)
        health_check     = optional(object({ path = optional(string, "/health") }), {})
        health_check_cmd = optional(list(string), ["wget", "--no-verbose", "--spider"])
        subnet_groups = optional(list(object({
          group_name = optional(string, "intra") # if "intra", set alb
        })), [{}])
        security_groups = optional(list(object({
          name_short = optional(string, "ecs-intra")
        })), [{}])
        iam_role = optional(object({
          exec = optional(object({
            name_short = optional(string, "ecs-exec-default")
          }), {})
          task = optional(object({
            name_short = optional(string, "ecs-task-default")
          }), {})
        }), {})
      })), [{}])
      schedules = optional(list(object({
        resource_prefix              = optional(string, "schedule-")
        name_short                   = optional(string, null)
        cpu                          = optional(number, 256)
        memory                       = optional(number, 512)
        enabled                      = optional(bool, true)
        description                  = optional(string, "Scheduled task")
        start_date                   = optional(string, null)
        end_date                     = optional(string, null)
        schedule_expression          = optional(string, "cron(0/1 * * * ? *)")
        schedule_expression_timezone = optional(string, "UTC")
        host_port                    = optional(number, 8000)
        container_port               = optional(number, 8000)
        health_check                 = optional(object({ path = optional(string, "/health") }), {})
        health_check_cmd             = optional(list(string), ["wget", "--no-verbose", "--spider"])
        subnet_groups = optional(list(object({
          group_name = optional(string, "intra")
        })), [{}])
        security_groups = optional(list(object({
          name_short = optional(string, "ecs-intra")
        })), [{}])
        iam_role = optional(object({
          exec = optional(object({
            name_short = optional(string, "scheduler-default")
          }), {})
          task = optional(object({
            name_short = optional(string, "ecs-task-default")
          }), {})
        }), {})
      })), null)
    }), {})
    # if null, var.common.microservice is used
    ecr = optional(object({
      repositories = optional(list(object({ name_short = optional(string, null) })), [{}])
    }), {})
    cwlogs = optional(object({
      log_groups = optional(list(object({
        # if null, var.common.microservice is used
        name_short = optional(string, null)
      })), [{}])
    }), {})
    alb = optional(object({
      target_groups = optional(list(object({
        # if null, var.common.microservice is used
        name_short   = optional(string, null)
        port         = optional(number, 8000)
        health_check = optional(object({ path = optional(string, "/health") }), {})
      })), [{}])
      listener_rules = optional(list(object({
        # if null, var.common.microservice is used
        name_short   = optional(string, null)
        path_pattern = optional(string, null)
      })), [{}])
    }), {})
  })

  default = {}
}

variable "scheduler" {
  description = "EventBridge Scheduler Schedule"
  sensitive   = false
  nullable    = true

  type = object({
    group = optional(object({
      resource_prefix = optional(string, "ebsg-")
    }), {})
    schedule = optional(object({
      resource_prefix = optional(string, "schedule-")
    }), {})
    enable_execute_command = optional(object({
      dev  = optional(bool, true)
      test = optional(bool, false)
      stg  = optional(bool, false)
      prod = optional(bool, false)
    }), {})
    maximum_event_age_in_seconds = optional(object({
      dev  = optional(number, 86400)  # 24hr
      test = optional(number, 86400)  # 24hr
      stg  = optional(number, 86400)  # 24hr
      prod = optional(number, 864000) # 10 days
    }), {})
    maximum_retry_attempts = optional(object({
      dev  = optional(number, 5)
      test = optional(number, 10)
      stg  = optional(number, 10)
      prod = optional(number, 20)
    }), {})
    timeouts = optional(object({
      dev = optional(object({
        # TODO: revert
        create = optional(string, "1m")
        # create = optional(string, "2m")
        delete = optional(string, "2m")
      }), {})
      test = optional(object({
        create = optional(string, "5m") # terraform's default
        delete = optional(string, "5m") # terraform's default
      }), {})
      stg = optional(object({
        create = optional(string, "5m") # terraform's default
        delete = optional(string, "5m") # terraform's default
      }), {})
      prod = optional(object({
        create = optional(string, "10m")
        delete = optional(string, "10m")
      }), {})
    }), {})
  })

  default = {}
}

variable "ecr" {
  description = "Amazon Elastic Container Registry"
  sensitive   = false
  nullable    = true

  type = object({
    resource_prefix = optional(string, "")
    force_delete = optional(object({
      dev  = optional(bool, true)
      test = optional(bool, false)
      stg  = optional(bool, false)
      prod = optional(bool, false)
    }), {})
    image_tag_mutability = optional(object({
      dev  = optional(string, "MUTABLE")
      test = optional(string, "IMMUTABLE")
      stg  = optional(string, "IMMUTABLE")
      prod = optional(string, "IMMUTABLE")
    }), {})
    image_scanning_configuration = optional(object({
      scan_on_push = optional(object({
        # CONTINUOUS_SCANによってInspectorがCVEをデータベースに追加したタイミングでスキャンが実行される
        # devにマージされるという事はpush時のスキャンで検知された問題が解決されているという前提でdev以外はpush時にスキャンを実行しない事とする
        dev  = optional(bool, true)
        test = optional(bool, false)
        stg  = optional(bool, false)
        prod = optional(bool, false)
      }), {})
    }), {})
    lifecycles = optional(object({
      image_count = optional(number, 100)
    }), {})
    timeouts = optional(object({
      dev = optional(object({
        delete = optional(string, "10m")
      }), {})
      test = optional(object({
        delete = optional(string, "20m") # terraform's default
      }), {})
      stg = optional(object({
        delete = optional(string, "20m") # terraform's default
      }), {})
      prod = optional(object({
        delete = optional(string, "60m")
      }), {})
    }), {})
  })

  default = {}
}

variable "cwlogs" {
  description = "CloudWatch Logs"
  sensitive   = false
  nullable    = true

  type = object({
    log_group = optional(object({
      resource_prefix = optional(string, "cwlg-")
    }), {})
    retention_in_days = optional(number, 731) # 2 years
  })

  default = {}

  validation {
    # ref: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group#retention_in_days
    condition = contains(
      [0, 1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1096, 1827, 2192, 2557, 2922, 3288, 3653],
    var.cwlogs.retention_in_days)
    error_message = "cwlogs.retention_in_daysが指定可能な値ではありません"
  }
}

variable "image_tag" {
  description = "Docker image tag"
  sensitive   = false
  nullable    = true

  type = string

  default = "v0.1.0"
}
