SHELL := bash
.ONESHELL:
.DELETE_ON_ERROR:
.DEFAULT_GOAL := all
.SHELLFLAGS := -euo pipefail -c
MAKEFLAGS += --warn-undefined-variables
MAKEFLAGS += --no-builtin-rules

all: help

.PHONY: all

help: ## makeターゲットの一覧をヘルプとして表示
	@ egrep -h '\s##\s' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

.PHONY: help

update/tools: ## 各ツールのバージョンの更新
	@ pre-commit autoupdate
	@ pnpm update --latest
	@ python ./scripts/python/tools/fetch_latest_tool_versions.py
	@ bash ./scripts/bash/devcontainer/update_devcontainer_compose_build_args.sh

@PHONY: update/tools

terraform/unit-tests: ## terraformのunit test(plan)を実行
	@ bash scripts/bash/terraform/run_all.sh --unit-test

.PHONY: terraform/unit-tests
