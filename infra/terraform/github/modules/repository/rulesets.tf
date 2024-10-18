
# ブランチ命名規則
# resource "github_repository_ruleset" "branch_name_patterns" {
#   # ref: https://registry.terraform.io/providers/integrations/github/latest/docs/resources/repository_ruleset
#   depends_on = [github_repository.this]

#   name        = "branch-name-pattern"
#   repository  = github_repository.this.name
#   target      = "branch"
#   enforcement = "active"

#   conditions {
#     ref_name {
#       include = ["~ALL"]
#       exclude = []
#     }
#   }

#   rules {
#     branch_name_pattern {
#       name     = "hotfix/, feature/"
#       operator = "regex"
#       pattern  = "^(hotfix/|feature/)"
#     }
#   }
# }

# git tag命名規則(docker image tagとは別)
# resource "github_repository_ruleset" "tag_name_pattern" {
#   # ref: https://registry.terraform.io/providers/integrations/github/latest/docs/resources/repository_ruleset
#   count = var.rulesets.semver_tags.enabled ? 1 : 0

#   name        = "tag-name-pattern"
#   repository  = github_repository.this.name
#   target      = "tag"
#   enforcement = "active"

#   rules {
#     tag_name_pattern {
#       name     = "tag created by release-please: {component-name}-v{Semantic Versioning 2.0.0}"
#       operator = "regex"
#       # refs:
#       # - https://semver.org/
#       # - https://github.com/googleapis/release-please
#       pattern = var.rulesets.semver_tags.regex
#     }
#   }
# }


# コミットメッセージ規則
# resource "github_repository_ruleset" "commit" {
#   # ref: https://registry.terraform.io/providers/integrations/github/latest/docs/resources/repository_ruleset
#   depends_on = [github_repository.this]
#   count      = var.rulesets.conventional_commits.enabled ? 1 : 0

#   name        = "commit-rules"
#   repository  = github_repository.this.name
#   target      = "branch"
#   enforcement = "active"

#   conditions {
#     ref_name {
#       include = ["~ALL"]
#       exclude = []
#     }
#   }

#   rules {
#     commit_message_pattern {
#       # ref: https://www.conventionalcommits.org/en/v1.0.0/
#       name     = "Conventioanal Commit v1.0.0"
#       operator = "regex"
#       pattern  = var.rulesets.conventional_commits.regex
#     }
#   }
# }

# ブランチプロテクションルール
# resource "github_repository_ruleset" "branch_protection" {
#   # ref: https://registry.terraform.io/providers/integrations/github/latest/docs/resources/repository_ruleset
#   depends_on = [github_repository.this, github_branch.this]
#   for_each = {
#     for environment, value in var.repository.environments : environment => value
#   }

#   name        = format("%s-branch-protection-rules", each.key)
#   repository  = github_repository.this.name
#   target      = "branch"
#   enforcement = "active"

#   conditions {
#     ref_name {
#       include = [format("refs/heads/%s", each.key)]
#       exclude = []
#     }
#   }

#   bypass_actors {
#     actor_id    = 1 # organization_admin
#     actor_type  = "OrganizationAdmin"
#     bypass_mode = "always"
#   }

#   bypass_actors {
#     actor_id    = 5 # admin
#     actor_type  = "RepositoryRole"
#     bypass_mode = "always"
#   }

#   rules {
#     creation                      = true  # bypass_actorsのみ作成が可能
#     deletion                      = true  # bypass_actorsのみ削除が可能
#     update                        = true  # bypass_actorsのみ更新が可能
#     update_allows_fetch_and_merge = false # forked repository向け設定
#     non_fast_forward              = false # force push禁止
#     required_linear_history       = true  # merge commit禁止
#     required_signatures           = false # signatures必須

#     pull_request {
#       dismiss_stale_reviews_on_push = true # 新しいpushで古い承認が無効となる
#       require_code_owner_review     = true # CODEOWNERSからの承認必須
#       require_last_push_approval    = true # 最後にpushした人以外からの承認必須
#       required_approving_review_count = (
#         each.key == "prod" ? 2 :
#         each.key == "stg" ? 1 :
#         0
#       )                                        # 承認必須のレビュー数
#       required_review_thread_resolution = true # レビューコメントの解決必須
#     }

#     required_deployments {
#       required_deployment_environments = (
#         each.key == "prod" ? ["stg"] :
#         each.key == "stg" ? ["test"] :
#         []
#       )
#     }

#     dynamic "required_status_checks" {
#       for_each = (
#         (each.key == "prod" || each.key == "stg") &&
#         var.rulesets.required_status_checks.enabled ?
#         [1] :
#         []
#       )

#       content {
#         strict_required_status_checks_policy = true

#         dynamic "required_check" {
#           for_each = (
#             var.rulesets.required_status_checks
#           )

#           content {
#             context = required_check.value
#           }
#         }
#       }
#     }
#   }
# }
