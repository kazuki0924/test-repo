#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

# postCreateCommand

# reads:
# - .devcontainer/common/.env.devcontainer
# - .env.tool-versions

# ref: https://containers.dev/implementors/json_reference/#lifecycle-scripts

# git clone the repository to the named volume in "${HOME}/workspace"
if [[ ! -d ".git" ]]; then
  echo "running git operations:"
  git init --initial-branch "${MAIN_BRANCH}"
  git remote add origin "${GIT_REMOTE_ORIGIN}"
  git fetch --depth 1 origin "${MAIN_BRANCH}"
  git reset --hard origin/"${MAIN_BRANCH}"
  git push --set-upstream origin "${MAIN_BRANCH}"
  echo "done"
fi

[[ ! -d ".git" ]] && echo "failed to clone repository" && exit 1

# create .env for repository in named volume
[[ ! -e .env ]] && cp .env.sample .env

# .bashrc
if [[ -f "${HOME}/.bashrc" ]] && [[ ! -L "${HOME}/.bashrc" ]]; then
  mv "${HOME}/.bashrc" "${HOME}/.bashrc_bak"
fi
if [[ ! -f "${HOME}/.bashrc" ]]; then
  ln -sv "${HOME}/workspace/.devcontainer/common/.bashrc" "${HOME}/.bashrc"
fi

# .bash_history
if [[ ! -f "${HOME}/.bash_history" ]]; then
  if [[ ! -f "${HOME}/workspace/bash-history/.bash_history" ]]; then
    cp "${HOME}/workspace/.devcontainer/common/.bash_history.sample" "${HOME}/workspace/bash-history/.bash_history"
  fi
  ln -sv "${HOME}/workspace/bash-history/.bash_history" "${HOME}/.bash_history"
fi

# terraform
if [[ -f "${HOME}/.terraformrc" ]] && [[ ! -L "${HOME}/.terraformrc" ]]; then
  mv "${HOME}/.terraformrc" "${HOME}/.terraformrc_bak"
fi
if [[ ! -f "${HOME}/.terraformrc" ]]; then
  ln -sv "${HOME}/workspace/.terraformrc" "${HOME}/.terraformrc"
fi
if [[ ! -d "${HOME}/workspace/.terraform.d/plugin-cache" ]]; then
  mkdir -p "${HOME}/workspace/.terraform.d/plugin-cache"
fi

# python
if [[ ! -f "${HOME}/workspace/scripts/python/.venv/bin/activate" ]]; then
  uv venv "${HOME}/workspace/scripts/python/.venv"
fi