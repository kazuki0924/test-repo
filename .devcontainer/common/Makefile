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

run-ubuntu: ## ubuntu:noble-20240605をdocker runで起動
	@ docker run --rm --interactive --tty ubuntu:noble-20240605 /bin/bash

@PHONY: run-ubuntu

devcontainer/init: ## devcontainer用の初期セットアップスクリプトの実行
	@ bash ./init.sh

.PHONY: devcontainer/init

devcontainer/build-devcontainers: ## devcontainerのビルド
	docker compose up --build --detach

.PHONY: devcontainer/build-devcontainers

devcontainer/run-infra-edge: ## infra-edgeの起動
	docker compose exec infra-edge /bin/bash

.PHONY: devcontainer/run-infra-edge

devcontainer/test-infra-edge: ## infra-edgeのテスト
	docker compose exec infra-edge /bin/bash -c "py.test -v -s ./scripts/python/tools/tests/infratest_tool_versions.py"

.PHONY: devcontainer/test-infra-edge

devcontainer/poc: ## infra-pocの実行
	docker compose up --build --detach infra-poc
	docker compose exec infra-poc /bin/bash
