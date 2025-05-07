SHELL:=/usr/bin/env bash -euo pipefail -c
.DEFAULT_GOAL := help

CURRENT_DIR:=$(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))
PROJECT_NAME:=$(shell poetry version | sed -e 's/[ ].*//g')
PROJECT_VERSION:=$(shell poetry version | sed -e 's/.*[ ]//g')
RELEASE_NOTES:=$(shell cat pyproject.toml | grep changelog_file | sed -e 's/.*=[ ]//g')

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
	@poetry run pyupgrade --py310-plus **/*.py || true
	@poetry run nbqa pyupgrade --py310-plus **/*.ipynb || true
	@poetry run isort $(PROJECT_NAME) tests
	@poetry run nbqa isort notebooks --float-to-top
	@poetry run ruff format notebooks $(PROJECT_NAME) tests
	@poetry run docformatter $(PROJECT_NAME) tests || true
	@poetry run sqlfluff fix sql

### compile        : Apply code styling and perform type checks
.PHONY: lint
lint:
	@poetry check
	@poetry run ruff check --fix notebooks $(PROJECT_NAME) tests
	@poetry run mypy $(PROJECT_NAME) tests

### test           : Run tests
.PHONY: test
test:
	@poetry run pytest

### build          : Run tests, build docs and package
.PHONY: build
build: test
	@poetry build
	@poetry run mkdocs build -f docs/mkdocs.yml

### docker         : Build docker image
.PHONY: docker
docker:
	@poetry docker

### bump           : Bump version and generate changelog
.PHONY: bump
bump:
	@perl -i -pe 's/Latest Release/${PROJECT_VERSION}/g' $(RELEASE_NOTES)
	@cz changelog --incremental --start-rev $(PROJECT_VERSION) --unreleased-version "Latest Release"
	$(eval BUMP=$(shell poetry version minor | sed -e 's/.*[ ]to[ ]//g'))
	@git add --all && git commit -m "bump: version ${PROJECT_VERSION} to ${BUMP}"
	@git tag ${BUMP}

### publish        : Publish the package and documentation
.PHONY: publish
publish: build
	@echo "Releasing version '$(PROJECT_VERSION)'"
	@poetry publish
	@poetry run mkdocs gh-deploy
	@cz changelog $(PROJECT_VERSION)
	@gh release create --verify-tag $(PROJECT_VERSION) \
		--notes-file $(RELEASE_NOTES) \
		dist/$(PROJECT_NAME)-$(PROJECT_VERSION).tar.gz \
		dist/$(PROJECT_NAME)-$(PROJECT_VERSION)-py3-none-any.whl
