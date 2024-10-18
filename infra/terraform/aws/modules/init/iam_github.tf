# GitHub Actionsの認証の為に手動で作成したOIDCプロバイダーとIAMロールをimportしてよりセキュアな設定で上書きする為に用意

# ref:
# stargate-welcome-guides: Setup Github OIDC in AWS
# https://portal.tmc-stargate.com/docs/default/component/stargate-welcome-guides/non-mandatory-docs/tool-docs/github-emu-actions/manuals/using-github-oidc-aws/#step-4-setting-up-github-actions-workflow
# OIDC Woven Sample Terraform Codes
# https://github.com/wp-prodsec/github-oidc-sample/blob/main/aws/oidc.tf

locals {
  iam_role = {
    name = "${var.common.prefix}${var.iam.role.resource_prefix}${var.github.iam_role.name_short}${var.common.suffix}"
  }
  oidc_provider = {
    name = "${var.oidc_provider}${var.common.suffix}"
  }
}

resource "aws_iam_openid_connect_provider" "github" {
  # ref: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_openid_connect_provider
  url = "https://${local.oidc_provider.name}"
  client_id_list = [
    "sts.amazonaws.com",
  ]
  # https://github.blog/changelog/2023-06-27-github-actions-update-on-oidc-integration-with-aws/
  thumbprint_list = [
    "6938fd4d98bab03faadb97b34396831e3780aea1",
    "1c58a3a8518e8759bf075b76b750d4f2df264fcd"
  ]

  tags = {
    name       = local.oidc_provider.name
    Name       = local.oidc_provider.name
    name_short = local.oidc_provider.name
    url        = "https://${local.oidc_provider.name}"
  }

  lifecycle {
    ignore_changes = [
      tags["created_at"],
      tags["created_date"]
    ]
  }
}

data "aws_iam_policy_document" "github_assume_role" {
  # ref: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document
  statement {
    sid     = "GitHubActionsAssumeRole"
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringLike"
      variable = "${local.oidc_provider.name}:sub"
      values = (
        [
          for pattern in var.github.repository_allow_list :
          "repo:${var.common.github.org}/${pattern}"
        ]
      )
    }
  }
}

resource "aws_iam_role" "github_actions" {
  # ref: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role
  name               = local.iam_role.name
  assume_role_policy = data.aws_iam_policy_document.github_assume_role.json
  managed_policy_arns = [
    # AdministratorAccessからaccount, organizationsリソースのwrite操作を抜いたもの
    "arn:aws:iam::aws:policy/PowerUserAccess",
    "arn:aws:iam::aws:policy/IAMFullAccess"
  ]

  tags = {
    # tag names are case-insensitive
    name       = local.iam_role.name
    name_short = var.github.iam_role.name_short
  }

  lifecycle {
    ignore_changes = [
      tags["created_at"],
      tags["created_date"]
    ]
  }
}
