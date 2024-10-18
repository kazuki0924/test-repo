#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

# terraform testの全実行

CWD="$(pwd)"
export TERRAGRUNT_NON_INTERACTIVE=true

# dependencies
REQUIREMENTS=(
  "fd"
  "terraform"
  "terragrunt"
)

for CMD in "${REQUIREMENTS[@]}"; do
  if ! command -v "${CMD}" &> /dev/null; then
    echo "Error: ${CMD} is not installed." >&2
    exit 1
  fi
done

usage() {
  cat << EOF
NAME

  run_all_tests.sh

DESCRIPTION

  runs all terraform tests

SYNOPSIS:

  run_all_tests.sh [OPTION]...

Usage:

  -h | --help: このヘルプの表示
  -i | --init: terragrunt init/terraform initを全moduleで実行
  -U | --upgrade: terragrunt init -upgrade/terraform init -upgradeを全moduleで実行
  -u | --unit: Unit Testのみ全実行
  --app-integration: app root moduleのIntegration Testのみ実行
  -a | --apply: 全root moduleでterraform applyを実行
  -d | --destroy: 全root moduleでterraform destroyを実行
  -e | --env: 環境の指定。デフォルトはdev
EOF
}

# default values
TEST_TYPE=""
TF_CMD=""
INIT="false"
UPGRADE="false"
ENV="dev"

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
    -i | --init)
      INIT="true"
      ;;
    -U | --upgrade)
      UPGRADE="true"
      ;;
    -u | --unit)
      TEST_TYPE="unit"
      ;;
    --app-integration)
      TEST_TYPE="app-integration"
      ;;
    -a | --apply)
      TF_CMD="apply"
      ;;
    -d | --destroy)
      TF_CMD="destroy"
      ;;
    --env=*)
      ENV="${FLAG#*=}"
      ;;
    -e | --env)
      INDEX_TO_SKIP="$((i + 1))"
      ARGS_LENGTH="${#ARGS[@]}"
      if [[ "${INDEX_TO_SKIP}" -lt "${ARGS_LENGTH}" ]]; then
        NEXT_ARG="${ARGS["${INDEX_TO_SKIP}"]}"
        ENV="${NEXT_ARG}"
      fi
      ;;
  esac
done

# src/ と infra/ のみを対象とする
DEV_ROOT_MODULES="$(fd --absolute-path --full-path --type directory --glob "**/environments/dev/*" --exclude "environments/dev/init/*" --exclude "environments/dev/storage/*" --exclude "environments/dev/network/*" .)"
INFRA_MODULES="$(fd --absolute-path --full-path --type directory --glob "**/modules/*" .)"

run_all_in_infra_modules() {
  for INFRA_MODULE in ${INFRA_MODULES}; do
    echo "cd ${INFRA_MODULE}"
    cd "${INFRA_MODULE}"
    echo "${@}"
    "${@}"
  done
}

run_all_in_root_modules() {
  for DEV_ROOT_MODULE in ${DEV_ROOT_MODULES}; do
    echo "cd ${DEV_ROOT_MODULE}"
    cd "${DEV_ROOT_MODULE}"
    echo "${@}"
    "${@}"
  done
}

if [[ "${INIT}" == "true" ]]; then
  run_all_in_root_modules terragrunt init
  run_all_in_infra_modules terraform init
fi

if [[ "${UPGRADE}" == "true" ]]; then
  # generate versions.tf first
  run_all_in_root_modules terragrunt init
  run_all_in_infra_modules terraform init -upgrade
  run_all_in_root_modules terragrunt init -upgrade
fi

if [[ "${TEST_TYPE}" == "unit" ]]; then
  run_all_in_infra_modules terraform test
elif [[ "${TEST_TYPE}" == "app-integration" ]]; then
  cd "./infra/terraform/aws/environments/dev/app"
  if [[ "${INIT}" == "true" ]]; then
    terragrunt init
  fi
  terragrunt test
fi

if [[ "${TF_CMD}" == "apply" ]]; then
  DIRS=(
    "${CWD}/infra/terraform/aws/environments/dev/init"
    "${CWD}/infra/terraform/aws/environments/dev/storage"
    "${CWD}/infra/terraform/aws/environments/dev/network"
    "${CWD}/infra/terraform/aws/environments/dev/app"
    "${CWD}/src/subdomain-name1/microservice-name1/infra/terraform/aws/environments/dev/app"
  )

  for DIR in "${DIRS[@]}"; do
    cd "${DIR}"
    if [[ "${INIT}" == "true" ]]; then
      echo "y" | terragrunt init
    fi
    echo "y" | terragrunt apply -auto-approve -input=false
  done
fi

if [[ "${TF_CMD}" == "destroy" ]]; then
  DIRS=(
    "${CWD}/infra/terraform/aws/environments/dev/init"
    "${CWD}/infra/terraform/aws/environments/dev/storage"
    "${CWD}/infra/terraform/aws/environments/dev/network"
    "${CWD}/infra/terraform/aws/environments/dev/app"
    "${CWD}/src/subdomain-name1/microservice-name1/infra/terraform/aws/environments/dev/app"
  )

  cd "${CWD}/infra/terraform/aws/environments/dev/init"
  set +e
  terraform init
  terraform state rm module.init.aws_kms_key.sops
  terraform state rm module.init.aws_kms_alias.primary
  terraform state rm module.init.aws_kms_replica_key.sops
  terraform state rm module.init.aws_kms_alias.replica
  terraform state rm module.init.aws_route53_zone.subdomain
  set -e

  for DIR in "${DIRS[@]}"; do
    cd "${DIR}"
    echo "y" | terragrunt destroy -auto-approve -input=false
  done
fi
