REPO_NAME ?= localhost
IMAGE_NAME ?= bedrock-server
SNYK_TEMP ?= /var/tmp
APP_NAME := ${REPO_NAME}/${IMAGE_NAME}
CONTAINER_RUNTIME := $(shell command -v podman 2> /dev/null || echo docker)

.PHONY: help
help: ## This help.
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "\033[36m%-15s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)
.DEFAULT_GOAL := help

.PHONY: all
all: build ## Build the container.

.PHONY: build
build: ## Build the container.
	$(CONTAINER_RUNTIME) build -t "${APP_NAME}" .

.PHONY: build-nc
build-nc: ## Build the container without cache.
	$(CONTAINER_RUNTIME) build --no-cache -t "${APP_NAME}" .

.PHONY: test
test: ## Test the container.
	$(CONTAINER_RUNTIME) run -it --rm "${APP_NAME}" \
		bash -c "nohup ./bedrock_server & \
			test.sh -t 30 -f nohup.out -s 'Server started'"

.PHONY: snyk-test
snyk-test: ## Run 'snyk test' on the image.
	./scripts/snyk-check.sh -c "${IMAGE_NAME}" -a "test" -p Dockerfile -t "${SNYK_TEMP}"

.PHONY: snyk-monitor
snyk-monitor: ## Run 'snyk monitor' on the image.
	./scripts/snyk-check.sh -c "${IMAGE_NAME}" -a "monitor" -p Dockerfile -t "${SNYK_TEMP}"

.PHONY: push
push: ## Publish the container on Docker Hub
	$(CONTAINER_RUNTIME) push "${APP_NAME}"

.PHONY: shell
shell: ## Launce a shell in the container.
	$(CONTAINER_RUNTIME) run -it --rm \
		"${APP_NAME}" bash

.PHONY: clean
clean: ## Clean the generated files/images.
	$(CONTAINER_RUNTIME) rmi "${APP_NAME}"

