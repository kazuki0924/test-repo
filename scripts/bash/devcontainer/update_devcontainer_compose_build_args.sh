#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

# devcontainer用compose.ymlのx-defaults.services.build.args.tool-versionsを.env.tool-versionsを元に更新する

# dependencies
REQUIREMENTS=(
  "yq"
)

for CMD in "${REQUIREMENTS[@]}"; do
  if ! command -v "${CMD}" &> /dev/null; then
    echo "Error: ${CMD} is not installed." >&2
    exit 1
  fi
done

readonly TOOL_VERSIONS_ENV_FILE="./.env.tool-versions"
readonly COMPOSE_FILE="./.devcontainer/common/compose.yml"

echo "update_devcontainer_compose_build_args.sh started"

keys=()

while IFS= read -r LINE; do
  if [[ ${LINE} =~ ^export[[:space:]]+([^=]+)= ]]; then
    keys+=("${BASH_REMATCH[1]}")
  fi
done < "${TOOL_VERSIONS_ENV_FILE}"

build_args_yq=""
for KEY in "${keys[@]}"; do
  if [[ -n "${build_args_yq}" ]]; then
    build_args_yq+=", "
  fi
  build_args_yq+="\"${KEY}\": \"\${${KEY}}\""
done

keys_yq="[$(printf "\"%s\"," "${keys[@]}" | sed 's/,$//')]"

yq -i "
  .x-defaults.services.build.args.tool-versions |= . + { ${build_args_yq} }
  | .x-defaults.services.build.args.tool-versions |= pick(${keys_yq})
  | .x-defaults.services.build.args.tool-versions[] |= . style=\"double\"
  | (... | select(tag == \"!!merge\")) tag = \"\"
" "${COMPOSE_FILE}"

echo "update_devcontainer_compose_build_args.sh completed"
