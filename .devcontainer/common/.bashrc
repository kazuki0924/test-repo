#!/usr/bin/env bash

# [bash]
# ensure history is appended to the history file and not overwritten
shopt -s histappend
# set history sizes
export HISTSIZE=10000
export HISTFILESIZE=20000
# avoid duplicate entries and erase duplicates
export HISTIGNORE="&:ls:cd:cd -:exit:*.vscode-server/extensions*"
export HISTCONTROL="ignoredups"
export HISTFILE="${HOME}/.bash_history"

# [make]
alias make='/usr/local/bin/make'

# [terragrunt]
export TERRAGRUNT_PROVIDER_CACHE=1
export TERRAGRUNT_PROVIDER_CACHE_DIR="${HOME}/workspace/.terragrunt-provider-cache"

# [python]
# shellcheck disable=SC1091
[[ -f "${HOME}/workspace/scripts/python/.venv/bin/activate" ]] && . "${HOME}/workspace/scripts/python/.venv/bin/activate"
export UV_LINK_MODE="symlink"
export UV_CACHE_DIR="${HOME}/workspace/.uv-cache"
export UV_PROJECT_ENVIRONMENT="${HOME}/workspace/scripts/python/.venv"

# [cargo]
export PATH="/usr/local/cargo/bin:${PATH}"

# [go]
export PATH="${PATH}:/usr/local/go/bin"
export GOPATH="${HOME}/opt/go"
export PATH="${PATH}:${GOPATH}/bin"

# [fnm]
if command -v fnm &>/dev/null; then
  eval "$(fnm env --use-on-cd --)"
fi

# [starship]
if command -v starship &>/dev/null; then
  eval "$(starship init bash)"
fi

# [zoxide]
if command -v zoxide &>/dev/null; then
  eval "$(zoxide init bash)"
fi

# [mcfly]
if command -v mcfly &>/dev/null; then
  eval "$(mcfly init bash)"
fi

# [.env]
# shellcheck disable=SC1091
[[ -f "${HOME}/workspace/.env.tool-versions" ]] && source "${HOME}/workspace/.env.tool-versions"
# shellcheck disable=SC1091
[[ -f "${HOME}/workspace/.devcontainer/common/.env" ]] && source "${HOME}/workspace/.devcontainer/common/.env"
# shellcheck disable=SC1091
[[ -f "${HOME}/workspace/.env" ]] && source "${HOME}/workspace/.env"

# [misc]
alias td="rm -rf ~/workspace/tempdir && mkdir -p ~/workspace/tempdir && cd ~/workspace/tempdir"
