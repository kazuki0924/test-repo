#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

# initializeCommand
# ref: https://containers.dev/implementors/json_reference/#lifecycle-scripts

# reads:
# - .devcontainer/common/.env.devcontainer
# - .env.tool-versions

# chown:
chown "$(id -u):$(id -g)" .devcontainer/common/scripts/lifecycle/on_create_command.sh

# bind mount file has to exist or docker compose will fail
[[ ! -e repl.sh ]] && touch repl.sh
chown "$(id -u):$(id -g)" repl.sh
[[ ! -e repl.py ]] && touch repl.py
chown "$(id -u):$(id -g)" repl.py
[[ ! -e ~/.gitignore ]] && touch ~/.gitignore
chown "$(id -u):$(id -g)" ~/.gitignore

# create .env for host machine
[[ ! -e .env ]] && cp .env.sample .env
[[ ! -e ./.devcontainer/common/.env ]] && touch ./.devcontainer/common/.env

# create .env.git if it doesn't exist
[[ ! -e ./.devcontainer/common/.env.git ]] && {
  # store the git remote url and main branch name to later git clone the repository in the named volume
  echo "export GIT_REMOTE_ORIGIN=\"$(git remote get-url origin)\""
  echo "export MAIN_BRANCH=\"$(git remote show origin | grep 'HEAD branch' | awk '{print $NF}')\""
} > ./.devcontainer/common/.env.git

{
  echo "export DEVCONTAINER_WORK_BRANCH=\"$(git branch --show-current)\""
  echo "export DEVCONTAINER_UID=\"$(id -u)\""
  echo "export DEVCONTAINER_GID=\"$(id -g)\""
  echo "export HOST_REPO_PATH=\"$(pwd)\""
  cat ./.devcontainer/common/.env.git
  cat ./.devcontainer/common/.env.devcontainer
  cat ./.env.tool-versions
} > ./.devcontainer/common/.env
