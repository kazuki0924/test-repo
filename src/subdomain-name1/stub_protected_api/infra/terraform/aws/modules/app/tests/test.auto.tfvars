defaults = {
  error_message = "The value is not as expected."
  common = {
    suffix       = "-delete-me"
    microservice = "microservice1"
  }
  per_microservice_resources = {
    alb = {
      listener_rules = [
        {
          path_pattern = "/api/vi/resourcePath*"
        }
      ]
    }
  }
}
