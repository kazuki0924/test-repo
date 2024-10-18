#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

# postStartCommand

# reads:
# - .devcontainer/common/.env.devcontainer
# - .env.tool-versions

# ref: https://containers.dev/implementors/json_reference/#lifecycle-scripts

echo "running git fetch:"
git fetch --all
echo "done"

echo "running python setup:"
if command -v uv &> /dev/null; then
  # install dev dependencies(e.g. pydantic, httpx etc.)
  cd scripts/python
  uv sync
  cd -
fi
if command -v mypy &> /dev/null; then
  mypy --install-types --non-interactive
fi
echo "done"

echo "running node setup:"
# install dev dependencies(e.g. prettier, eslint, etc.)
if command -v pnpm &> /dev/null; then
  pnpm install --frozen-lockfile
fi
echo "done"

echo "running terraform setup:"
# tflint
if command -v tflint &> /dev/null; then
  tflint --init
fi
echo "done"

# TODO: implement
# pre-commit:
# pre-commit install --install-hooks
