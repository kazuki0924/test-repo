tflint {
  required_version = "0.53.0"
}

config {
  format              = "default"
  call_module_type    = "all"
  force               = false
  disabled_by_default = false
  plugin_dir          = "./.tflint.d/plugins"
}

plugin "terraform" {
  enabled = true
  preset  = "all"
}

plugin "aws" {
  enabled = true
  version = "0.32.0"
  source  = "github.com/terraform-linters/tflint-ruleset-aws"

  deep_check = true
  region     = "ap-northeast-1"
}
