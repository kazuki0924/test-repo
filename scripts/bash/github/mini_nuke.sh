#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

# Nukes GitHub resources

# GitHub Actions Repository Variables
gh variable list -R "${GITHUB_OWNER}/${GITHUB_REPO}" --json name -q '.[] | .name' | xargs -I {} sh -c "gh variable delete '{}' -R '${GITHUB_OWNER}/${GITHUB_REPO}' || true"

environments=(
  "dev"
  "test"
  "stg"
  "prod"
)

# GitHub Actions Environment Variables
for env in "${environments[@]}"; do
  gh variable list -R "${GITHUB_OWNER}/${GITHUB_REPO}" --env "$env" --json name -q '.[] | .name' | xargs -I {} sh -c "gh variable delete '{}' -R '${GITHUB_OWNER}/${GITHUB_REPO}' --env '$env' || true"
done

# Autolink
gh api "repos/${GITHUB_OWNER}/${GITHUB_REPO}/autolinks" --jq '.[].id' | xargs -I {} gh api -X DELETE "repos/${GITHUB_OWNER}/${GITHUB_REPO}/autolinks/{}"
