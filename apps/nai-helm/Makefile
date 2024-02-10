# Customize these variables
IMAGE_NAME ?= nai-utils
TAG ?= 0.2
DOCKER_REGISTRY ?= quay.io/wolfgangntnx
CONTAINER_ENGINE ?= docker # or podman

# Build the Docker image
build:
	$(CONTAINER_ENGINE) build --platform linux/amd64 -t $(DOCKER_REGISTRY)/$(IMAGE_NAME):$(TAG) .

# Push the Docker image to a registry
push:
	$(CONTAINER_ENGINE) push $(DOCKER_REGISTRY)/$(IMAGE_NAME):$(TAG)

# All-in-one command to build and push
all: build push
