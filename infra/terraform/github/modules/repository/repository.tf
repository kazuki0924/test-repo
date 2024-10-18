locals {
  reviewer_teams = (
    var.repository.environments != null ? flatten(
      [
        for environment, values in var.repository.environments : values != null ? [
          for team in var.repository.environments[environment].reviewers.teams :
          var.repository.environments[environment].reviewers != null &&
          var.repository.environments[environment].reviewers.teams != null ? {
            environment = environment
            team        = team
          } : null
        ] : []
      ]
    ) : []
  )
  reviewer_users = (
    var.repository.environments != null ? flatten(
      [
        for environment, values in var.repository.environments : values != null ? [
          for user in var.repository.environments[environment].reviewers.users :
          var.repository.environments[environment].reviewers != null &&
          var.repository.environments[environment].reviewers.users != null ? {
            environment = environment
            user        = user
          } : null
        ] : []
      ]
    ) : []
  )
}

# ref: https://docs.github.com/en/rest/repos/repos?apiVersion=2022-11-28#create-an-organization-repository
resource "github_repository" "this" {
  # ref: https://registry.terraform.io/providers/integrations/github/latest/docs/resources/repository
  name                                    = var.common.github.repo
  description                             = var.repository.description
  homepage_url                            = null
  visibility                              = coalesce(var.repository.visibility, "private")
  has_issues                              = true
  has_discussions                         = true
  has_projects                            = true
  has_wiki                                = true
  is_template                             = var.repository.is_template
  allow_merge_commit                      = false
  allow_squash_merge                      = true
  allow_rebase_merge                      = false
  allow_auto_merge                        = true
  squash_merge_commit_title               = "PR_TITLE"
  squash_merge_commit_message             = "COMMIT_MESSAGES"
  merge_commit_title                      = null
  merge_commit_message                    = null
  delete_branch_on_merge                  = var.repository.git_branching_model == "GitFeatureFlow" ? false : true
  web_commit_signoff_required             = false
  auto_init                               = true
  gitignore_template                      = null
  license_template                        = null
  archived                                = false
  archive_on_destroy                      = true
  vulnerability_alerts                    = var.repository.enable_vulnerability_alerts
  ignore_vulnerability_alerts_during_read = false
  allow_update_branch                     = true

  # GitHub Advanced Security
  # dynamic "security_and_analysis" {
  #   for_each = var.repository.enable_advanced_security == true ? [1] : []

  #   content {
  #     advanced_security {
  #       status = "enabled"
  #     }

  #     secret_scanning {
  #       status = "enabled"
  #     }

  #     secret_scanning_push_protection {
  #       status = "enabled"
  #     }
  #   }
  # }
}

data "github_team" "reviewers" {
  # ref: https://registry.terraform.io/providers/integrations/github/latest/docs/data-sources/team
  for_each = {
    for item in local.reviewer_teams : "${item.environment}_${item.team}" => item if item != null
  }

  slug = each.value.team
}

data "github_user" "reviewers" {
  # ref: https://registry.terraform.io/providers/integrations/github/latest/docs/data-sources/user
  for_each = {
    for item in local.reviewer_users : "${item.environment}_${item.user}" => item if item != null
  }

  username = each.value.user
}

resource "github_repository_environment" "this" {
  # ref: https://registry.terraform.io/providers/integrations/github/latest/docs/resources/repository_environment
  depends_on = [github_repository.this]

  for_each = var.repository.environments != null ? {
    for environment, value in var.repository.environments : environment => value if value != null
  } : {}

  environment         = each.key
  repository          = github_repository.this.name
  can_admins_bypass   = true
  prevent_self_review = true

  dynamic "reviewers" {
    for_each = (
      each.value.reviewers != null ?
      [each.value.reviewers] :
      []
    )

    content {
      teams = (
        reviewers.value.teams != null ?
        [
          for team in reviewers.value.teams :
          data.github_team.reviewers["${each.key}_${team}"].id
        ] : []
      )
      users = (
        reviewers.value.users != null ?
        [
          for user in reviewers.value.users :
          data.github_user.reviewers["${each.key}_${user}"].id
        ] : []
      )
    }
  }

  deployment_branch_policy {
    # only one of the following can be set to true:
    protected_branches     = false
    custom_branch_policies = true
  }
}

# resource "github_repository_collaborators" "this" {
#   # ref: https://registry.terraform.io/providers/integrations/github/latest/docs/resources/repository_collaborators
#   depends_on = [github_repository.this]

#   repository = github_repository.this.name

#   dynamic "user" {
#     for_each = toset(var.repository.collaborators)

#     content {
#       username   = user.value.username
#       permission = user.value.permission
#     }
#   }

#   dynamic "team" {
#     for_each = toset(var.repository.teams)

#     content {
#       team_id    = team.value.slug
#       permission = team.value.permission
#     }
#   }
# }

# # dependabot
# resource "github_repository_dependabot_security_updates" "this" {
#   # ref: https://registry.terraform.io/providers/integrations/github/latest/docs/resources/repository_dependabot_security_updates
#   depends_on = [github_repository.this]
#   count      = var.repository.enable_advanced_security == true ? 1 : 0

#   repository = github_repository.this.id
#   enabled    = true
# }

# # RepositoryのTopics（メインページのdescriptionの下に表示される区分）
# resource "github_repository_topics" "this" {
#   # ref: https://registry.terraform.io/providers/integrations/github/latest/docs/resources/repository_topics
#   depends_on = [github_repository.this]

#   repository = github_repository.this.name
#   topics = concat(
#     compact(var.repository.topics),
#     compact([
#       var.common.system,
#       var.common.subsystem,
#       var.common.domain,
#     ])
#   )
# }

# # メインブランチをdevに変更
# resource "github_branch_default" "this" {
#   # ref: https://registry.terraform.io/providers/integrations/github/latest/docs/resources/branch_default
#   depends_on = [github_branch.this]

#   repository = github_repository.this.name
#   branch     = "dev"
#   rename     = true
# }


# # 各環境ごとのブランチを作成
# resource "github_branch" "this" {
#   # ref: https://registry.terraform.io/providers/integrations/github/latest/docs/resources/branch
#   depends_on = [github_repository.this]
#   for_each   = toset([for environment in var.enum.environments : environment if environment != "dev"])

#   repository = github_repository.this.name
#   branch     = each.key
# }

# # GitHub Repository Environmentにデプロイ可能なブランチの設定
# # ref: https://docs.github.com/en/rest/deployments/branch-policies?apiVersion=2022-11-28#create-a-deployment-branch-policy
# resource "github_repository_environment_deployment_policy" "this" {
#   # ref: https://registry.terraform.io/providers/integrations/github/latest/docs/resources/repository_environment_deployment_policy
#   depends_on = [github_repository_environment.this]
#   for_each = {
#     for environment, _ in var.repository.environments : environment => var.repository.environments[environment].deployment_policy
#   }

#   repository     = github_repository.this.name
#   environment    = each.key
#   branch_pattern = each.value.branch_pattern
# }

# # Autolink設定
# resource "github_repository_autolink_reference" "this" {
#   # ref: https://registry.terraform.io/providers/integrations/github/latest/docs/resources/repository_autolink_reference
#   for_each = {
#     for autolink in var.repository.autolinks : autolink.key_prefix => autolink
#   }

#   repository          = github_repository.this.name
#   key_prefix          = each.value.key_prefix
#   target_url_template = each.value.target_url_template
#   is_alphanumeric     = true
# }
