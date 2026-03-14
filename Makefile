SHELL:=/usr/bin/env bash -euo pipefail -c
.DEFAULT_GOAL := help

CURRENT_DIR:=$(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))
PROJECT_NAME:=$(shell uv version | sed -e 's/[ ].*//g' | tr '-' '_')
PROJECT_VERSION:=$(shell uv version | sed -e 's/.*[ ]//g')
RELEASE_NOTES:=$(shell cat pyproject.toml | grep release_notes_file | sed -e 's/.*=[ ]//g')

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
	@if [ -d "docs/site" ]; then rm -Rf $(CURRENT_DIR)/docs/site; fi

### format         : Format source
.PHONY: format
format:
	@uv run pyupgrade --py310-plus **/*.py || true
	@uv run nbqa pyupgrade --py310-plus **/*.ipynb || true
	@uv run isort $(PROJECT_NAME) tests
	@uv run nbqa isort notebooks --float-to-top
	@uv run ruff format notebooks $(PROJECT_NAME) tests
	@uv run docformatter $(PROJECT_NAME) tests || true
	@uv run sqlfluff fix sql

### compile        : Apply code styling and perform type checks
.PHONY: lint
lint:
	@uv check
	@uv run ruff check --fix notebooks $(PROJECT_NAME) tests
	@uv run mypy $(PROJECT_NAME) tests

### test           : Run tests
.PHONY: test
test:
	@uv run pytest

### build          : Run tests, build docs and package
.PHONY: build
build: test
	@uv build
	@uv run mkdocs build -f docs/mkdocs.yml

### local-docs     : Run local documentation server
.PHONY: local-docs
local-docs: build
	@mkdocs serve -f docs/mkdocs.yml

### docker         : Build docker image
.PHONY: docker
docker:
	@uv docker

### bump           : Bump version and generate changelog (INCREMENT can be PATCH, MINOR or MAJOR)
.PHONY: bump
bump:
	@cz changelog --template docs/templates/release_notes.j2 --file-name $(RELEASE_NOTES)
	@cz bump --yes --increment $(INCREMENT)

### release        : Release the package and documentation
.PHONY: release
release: build
	@echo "Releasing version '$(PROJECT_VERSION)'"
	@uv publish
	@uv run mkdocs gh-deploy
	@gh release create \
		--verify-tag $(PROJECT_VERSION) \
		--notes-file $(RELEASE_NOTES) \
		dist/$(PROJECT_NAME)-$(PROJECT_VERSION).tar.gz \
		dist/$(PROJECT_NAME)-$(PROJECT_VERSION)-py3-none-any.whl
