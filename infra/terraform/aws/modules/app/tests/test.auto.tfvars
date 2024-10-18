defaults = {
  error_message = "The value is not as expected."
  common = {
    # 消し損じがあっても明らかに削除対象だと分かる名前にする
    suffix = "-delete-me"
  }
}

prod = {
  common = {
    # 消し損じがあっても明らかに削除対象だと分かる名前にする
    suffix = "-delete-me"
    env    = "prod"
    aws = {
      default_tags = {
        env = "prod"
      }
    }
  }
}

per_microservice = {
  common = {
    suffix       = "-delete-me"
    microservice = "test-microservice"
  }
  is_microservice = true
  per_microservice_resources = {
    ecs = {
      services = [
        {
          name_short   = "test-microservice"
          health_check = { path = "/dummy_endpoint" }
        }
      ]
    }
    ecr = {
      repositories = [
        { name_short = "test-microservice" }
      ]
    }
    cwlogs = {
      log_groups = [
        { name_short = "ecs-execute-command" }, # for testing
        { name_short = "test-microservice" }
      ]
    }
    alb = {
      target_groups = [
        {
          name_short   = "test-microservice"
          health_check = { path = "/dummy_endpoint" }
        }
      ]
      listener_rules = [
        {
          name_short   = "test-microservice"
          path_pattern = "/dummy_endpoint"
        }
      ]
    }
  }
}
