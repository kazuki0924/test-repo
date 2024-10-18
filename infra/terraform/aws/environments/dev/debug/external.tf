data "external" "container_def_envs_json" {
  program = ["${var.common.repo_root}/scripts/python/aws/dotenv_to_container_def_envs_json.py", "${var.common.repo_root}/src/.env.defaults"]
}

output "container_def_envs_json" {
  value = data.external.container_def_envs_json.result.json
}
