#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

# set "$gh auth token" result as GITHUB_TOKEN to .env

# dependencies
REQUIREMENTS=(
  "gh"
)

for CMD in "${REQUIREMENTS[@]}"; do
  if ! command -v "${CMD}" &> /dev/null; then
    echo "Error: ${CMD} is not installed." >&2
    exit 1
  fi
done

echo "this scripts requires you to be logged in to GitHub via \$gh auth login"

readonly TARGET_ENV_FILE=".env"

echo "getting GitHub token..."
GITHUB_TOKEN=$(gh auth token)
readonly GITHUB_TOKEN
echo "done."

echo "writing to .env..."
if [[ -f "${TARGET_ENV_FILE}" ]]; then
  if grep -q "^export GITHUB_TOKEN=" "${TARGET_ENV_FILE}"; then
    echo "updating existing GITHUB_TOKEN..."
    sed -i "s/^export GITHUB_TOKEN=.*/export GITHUB_TOKEN=\"${GITHUB_TOKEN}\"/g" "${TARGET_ENV_FILE}"
  else
    echo "adding GITHUB_TOKEN..."
    echo "export GITHUB_TOKEN=\"${GITHUB_TOKEN}\"" >> .env
  fi
else
  echo "creating .env..."
  echo "export GITHUB_TOKEN=\"${GITHUB_TOKEN}\"" > .env
fi
echo "done."
