SHELL:=/usr/bin/env bash -euo pipefail -c
.DEFAULT_GOAL := help

CURRENT_DIR:=$(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))
PROJECT_NAME:=$(shell poetry version | sed -e 's/[ ].*//g')
PROJECT_VERSION:=$(shell poetry version | sed -e 's/.*[ ]//g')

.PHONY: help
help:
	@echo "usage: make command"
	@echo ""
	@echo "=== [Targets] =================================================================="
	@sed -n 's/^###//p' < $(CURRENT_DIR)/Makefile | sort

### clean          : Clean build
.PHONY: clean
clean:
	@if [ -d "dist" ]; then rm -Rf $(CURRENT_DIR)/dist; fi

### format         : Format source
.PHONY: format
format:
	@poetry run isort $(PROJECT_NAME) tests
	@poetry run black $(PROJECT_NAME) tests
	@poetry run docformatter $(PROJECT_NAME) tests || true

### compile        : Apply code styling and perform type checks
.PHONY: lint
lint: format
	@poetry check
	@poetry run ruff check --diff --no-fix $(PROJECT_NAME) tests
	@poetry run ruff format --check --diff $(PROJECT_NAME) tests
	@poetry run mypy $(PROJECT_NAME) tests

### test           : Run tests
.PHONY: test
test:
	@poetry run pytest

### build          : Compile, run tests and package
.PHONY: build
build: lint test
	@poetry build
	@poetry run mkdocs build -f docs/mkdocs.yml

### docker         : Build docker image
.PHONY: docker
docker:
	@poetry docker

### changelog      : Generate changelog
.PHONY: changelog
changelog:
	@cz changelog --unreleased-version "Latest Release"
