#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

usage() {
  cat << EOF
NAME

  iam_oidc_provider_and_role_for_github_action.sh

DESCRIPTION

  GitHub ActionsでAWSを操作するためのIAM RoleとOIDC Providerを作成するスクリプト

  IAM Roleは作成された後、Terraformのawsプロジェクトモジュールでimportし、そこで中身を上書きして権限を絞る想定
  その為、あくまでGitHub Actionsの初回実行を通す事を目的として強い権限と広いリポジトリ対象を指定している

  作成されるIAM Roleは以下の命名となる
  {prefix}-iamr-github-actions

  下記のGitHub Actionを利用するのに必要となる

  GitHub Actions: "Configure AWS Credentials" Action for GitHub Actions
  https://github.com/marketplace/actions/configure-aws-credentials-action-for-github-actions

  aws sso loginした端末、またはAWS CloudShellでの実行を想定

  e.g. CloudShellでの実行例(vim)
  CloudShellのvimでインデントズレ無く貼り付けるためにpasteモードにする
  $ echo "set paste" >> ~/.vimrc
  このスクリプトの中身を貼り付けた後、:wqで保存して終了
  $ vim script.sh
  その後、以下のように実行
  $ bash script.sh --prefix=system-subsystem-dev

  e.g. aws sso loginを実行した端末での実行例
  $ aws sso login
  $ bash ./scripts/bash/aws/iam_oidc_provider_and_role_for_github_action.sh --prefix=system-subsystem-dev

SYNOPSIS:

  iam_oidc_provider_and_role_for_github_action.sh [OPTION]...

Usage:

  -h | --help: このヘルプの表示
  -p | --prefix: IAMロールのリソース名のprefixの指定. e.g. -p system-subsystem-dev, --env=system-subsystem-dev
  -g | --github-owner: GitHubのOwner/Organization名の指定. default: wcm-eas
  -o | --oidc-provider: OIDC ProviderのURLの指定. deault: token.actions.githubusercontent.com/stargate
EOF
}

# default values
PREFIX=""
GITHUB_OWNER="wcm-eas"
OIDC_PROVIDER="token.actions.githubusercontent.com/stargate"
REPOSITORY_PATTERN="*"
IAM_ROLE_NAME="iamr-github-actions"

# dependencies
REQUIREMENTS=(
  "aws"
)

for CMD in "${REQUIREMENTS[@]}"; do
  if ! command -v "${CMD}" &> /dev/null; then
    echo "Error: ${CMD} がインストールされていません" >&2
    exit 1
  fi
done

# 引数
ARGS=("$@")
INDEX_TO_SKIP=""
for i in "${!ARGS[@]}"; do
  FLAG="${ARGS["${i}"]}"
  if [[ "${i}" == "${INDEX_TO_SKIP}" ]]; then
    continue
  fi
  case "${FLAG}" in
    -h | --help)
      usage
      exit 0
      ;;
    --prefix=*)
      PREFIX="${FLAG#*=}"
      ;;
    -p | --prefix)
      INDEX_TO_SKIP="$((i + 1))"
      ARGS_LENGTH="${#ARGS[@]}"
      if [[ "${INDEX_TO_SKIP}" -lt "${ARGS_LENGTH}" ]]; then
        NEXT_ARG="${ARGS["${INDEX_TO_SKIP}"]}"
        PREFIX="${NEXT_ARG}"
      fi
      ;;
    --github-owner=*)
      GITHUB_OWNER="${FLAG#*=}"
      ;;
    -g | --github-owner)
      INDEX_TO_SKIP="$((i + 1))"
      ARGS_LENGTH="${#ARGS[@]}"
      if [[ "${INDEX_TO_SKIP}" -lt "${ARGS_LENGTH}" ]]; then
        NEXT_ARG="${ARGS["${INDEX_TO_SKIP}"]}"
        GITHUB_OWNER="${NEXT_ARG}"
      fi
      ;;
    --oidc-provider=*)
      OIDC_PROVIDER="${FLAG#*=}"
      ;;
    -o | --oidc-provider)
      INDEX_TO_SKIP="$((i + 1))"
      ARGS_LENGTH="${#ARGS[@]}"
      if [[ "${INDEX_TO_SKIP}" -lt "${ARGS_LENGTH}" ]]; then
        NEXT_ARG="${ARGS["${INDEX_TO_SKIP}"]}"
        OIDC_PROVIDER="${NEXT_ARG}"
      fi
      ;;
  esac
done

# 必須引数
if [[ "${PREFIX}" == "" ]]; then
  echo "Error: prefixが指定されていません" >&2
  exit 1
fi

ROLE_NAME="${PREFIX}-${IAM_ROLE_NAME}"
# IAM RoleにAdministratorAccessポリシーをアタッチ
# セキュリティーの観点で、少なくとも本番環境向けではterraformでIAM Roleをimportして構成管理化に置いた後にAdministratorAccessを外し
# Least Privilegeとなるように権限を絞る事が推奨される
POLICY_ARN="arn:aws:iam::aws:policy/AdministratorAccess"

export AWS_DEFAULT_OUTPUT="text"

echo "*** GitHub Actions用IAM Role作成スクリプトを開始します ***"
echo ""

function get_oidc_provider_arns() {
  aws iam list-open-id-connect-providers --query 'OpenIDConnectProviderList[*].Arn' --output text
}

function list_matching_iam_role() {
  aws iam list-roles --query "Roles[?contains(RoleName, '${1}')]"
}

# OIDC Providerの作成
echo "OIDCプロバイダーが作成済みかを確認中..."

PROVIDER_FOUND=false

if [[ -n $(get_oidc_provider_arns) ]]; then
  read -r -a PROVIDERS < <(get_oidc_provider_arns)

  for ARN in "${PROVIDERS[@]}"; do
    if [[ ${ARN} == *"${OIDC_PROVIDER}" ]]; then
      echo "OIDCプロバイダーは既に作成済みです。"
      PROVIDER_FOUND=true
      break
    fi
  done
fi

if [[ "${PROVIDER_FOUND}" == false ]]; then
  echo "OIDCプロバイダーを作成します。"
  # 参考:
  # https://github.com/marketplace/actions/configure-aws-credentials-action-for-github-actions#configuring-iam-to-trust-github
  aws iam create-open-id-connect-provider --url "https://${OIDC_PROVIDER}" --client-id-list "sts.amazonaws.com" --thumbprint-list "ffffffffffffffffffffffffffffffffffffffff"
  echo "OIDCプロバイダーの作成が完了しました。"
fi

read -r -a PROVIDERS < <(get_oidc_provider_arns)

OIDC_PROVIDER_ARN=""

for ARN in "${PROVIDERS[@]}"; do
  if [[ ${ARN} == *"${OIDC_PROVIDER}" ]]; then
    OIDC_PROVIDER_ARN="${ARN}"
  fi
done

# IAM Roleの作成
# ワイルドカード指定をしている場合、セキュリティツールやIAMのlinterでWARNINGが出る為、
# 後の工程でterraformでIAM Roleをimportして構成管理化に置いた後に配列で対象のリポジトリ群を指定する様に編集する
ROLE_POLICY=$(
  cat << EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "${OIDC_PROVIDER_ARN}"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringLike": {
          "${OIDC_PROVIDER}:sub": [
            "repo:${GITHUB_OWNER}/${REPOSITORY_PATTERN}"
          ]
        }
      }
    }
  ]
}
EOF
)

echo "IAM Roleが作成済みかを確認中..."
if [[ -n $(list_matching_iam_role "${ROLE_NAME}") ]]; then
  echo "IAM Roleは既に作成済みです。"
else
  echo "IAM Role: ${ROLE_NAME} を作成します。"
  aws iam create-role --role-name "${ROLE_NAME}" --assume-role-policy-document "${ROLE_POLICY}"
  echo "IAM Roleを作成しました。"
  echo "IAM Policy: ${POLICY_ARN} をアタッチします。"
  aws iam attach-role-policy --role-name "${ROLE_NAME}" --policy-arn "${POLICY_ARN}"
  echo "IAM Policy のアタッチが完了しました。"
fi

# 動作確認
echo ""
echo "*** GitHub Actions用IAM Role作成スクリプトが完了しました ***"
echo ""
echo "動作確認を実施します。"
echo "存在するOIDC Provider一覧:"
aws iam list-open-id-connect-providers --query "OpenIDConnectProviderList[*].Arn"
echo "RoleNameに\"${IAM_ROLE_NAME}\"が含まれるIAM Role一覧:"
aws iam list-roles --query "Roles[?contains(RoleName, '${IAM_ROLE_NAME}')].RoleName"
