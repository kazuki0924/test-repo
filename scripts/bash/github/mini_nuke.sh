#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

# Nukes GitHub resources

gh variable list -R "$GITHUB_OWNER"/"$GITHUB_REPO" --json name -q '.[] | .name' | xargs -I {} sh -c 'gh variable delete {} -R $GITHUB_OWNER/$GITHUB_REPO || true'
gh variable list -R $GITHUB_OWNER/$GITHUB_REPO --env dev --json name -q '.[] | .name' | xargs -I {} sh -c 'gh variable delete {} -R $GITHUB_OWNER/$GITHUB_REPO --env dev || true'
gh variable list -R $GITHUB_OWNER/$GITHUB_REPO --env test --json name -q '.[] | .name' | xargs -I {} sh -c 'gh variable delete {} -R $GITHUB_OWNER/$GITHUB_REPO --env test || true'
gh variable list -R $GITHUB_OWNER/$GITHUB_REPO --env stg --json name -q '.[] | .name' | xargs -I {} sh -c 'gh variable delete {} -R $GITHUB_OWNER/$GITHUB_REPO --env stg || true'
gh variable list -R $GITHUB_OWNER/$GITHUB_REPO --env prod --json name -q '.[] | .name' | xargs -I {} sh -c 'gh variable delete {} -R $GITHUB_OWNER/$GITHUB_REPO --env prod || true'
