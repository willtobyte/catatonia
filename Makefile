.SILENT:
.DEFAULT_GOAL := default
SHELL := bash -euo pipefail

REGISTRY      ?= ghcr.io
OWNER         ?= willtobyte
USER          := $(shell gh api user -q .login)
IMAGE_NAME    ?= catatonia
IMAGE_TAG     ?= latest
BUILD_CONTEXT ?= .
DOCKERFILE    ?= Dockerfile
IMAGE_REF     := $(REGISTRY)/$(OWNER)/$(IMAGE_NAME):$(IMAGE_TAG)

help: ## Show available targets
	awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

login: ## Login to ghcr.io with gh token
	echo "$$(gh auth token)" | docker login "$(REGISTRY)" -u "$(USER)" --password-stdin

build: ## Build image
	docker build -f "$(DOCKERFILE)" -t "$(IMAGE_REF)" "$(BUILD_CONTEXT)"

push: ## Push image
	docker push "$(IMAGE_REF)"

default: login build push ## Login, build, and push

.PHONY: help login build push default
