data "aws_ecs_cluster" "this" {
  # ref: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ecs_cluster
  for_each = {
    for cluster in local.ecs_cluster : cluster.vpc.name_short => cluster
  }

  cluster_name = each.value.name
}
