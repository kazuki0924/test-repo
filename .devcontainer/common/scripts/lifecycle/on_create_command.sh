#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

# onCreateCommand

# reads:
# - .devcontainer/common/.env.devcontainer
# - .env.tool-versions

# ref: https://containers.dev/implementors/json_reference/#lifecycle-scripts

# volumes:
echo "running volumes setup:"
sudo chmod 0666 /var/run/docker.sock
sudo chown -R "$(id -u):$(id -g)" "${HOME}/workspace"
sudo chown -R "$(id -u):$(id -g)" "${HOME}/.cache"
mkdir -p "${HOME}/.local"
sudo chown -R "$(id -u):$(id -g)" "${HOME}/.local"
sudo chown -R "$(id -u):$(id -g)" "${HOME}/opt"
sudo chown -R "$(id -u):$(id -g)" "/opt"
echo "done"
