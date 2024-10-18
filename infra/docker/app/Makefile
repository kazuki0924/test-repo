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

app/local-integration-test: ## ローカル環境での接続テスト
	@ docker compose up --build

.PHONY: app/local-integration-test
