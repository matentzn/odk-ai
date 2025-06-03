# Makefile for ODK-AI

RESET_MULTIARCH_ON_BUILD=true

CACHE=

ARCH=linux/$(shell uname -m | sed 's/x86_64/amd64/')
PLATFORMS=linux/amd64,linux/arm64

.PHONY: .FORCE

VERSION = v0.1
IM=cmungall/odk-ai
TAGS_OPTION=-t $(IM):$(VERSION) -t $(IM):latest

.PHONY: build build-no-cache build-dev clean

build:
	docker build $(CACHE) --platform $(ARCH) \
	    $(TAGS_OPTION) \
	    .

build-no-cache:
	$(MAKE) build CACHE=--no-cache

build-dev:
	docker build $(CACHE) --platform $(ARCH) \
		-t $(IM):dev \
		.

clean:
	docker rm -f $(IM) || true

#### Publishing #####

.PHONY: publish-multiarch publish-multiarch-dev test

publish-multiarch:
	$(MAKE) reset-multiarch
	docker buildx build $(CACHE) --push --platform $(PLATFORMS) \
	    $(TAGS_OPTION) \
	    .

publish-multiarch-dev:
	$(MAKE) reset-multiarch
	docker buildx build $(CACHE) --push --platform $(PLATFORMS) \
		-t $(IM):dev \
		.

.PHONY: reset-multiarch

ifeq ($(RESET_MULTIARCH_ON_BUILD),true)

reset-multiarch:
	docker buildx rm odk-ai-multiarch
	docker buildx create --name odk-ai-multiarch --driver docker-container --use

else

reset-multiarch:
	echo "Skipping reset-multiarch as IMP is not set to true"

endif


#####################
### Testing #########
#####################

test:
	cd scratch && docker run -v $PWD:/work -e ANTHROPIC_API_KEY=$$ANTHROPIC_API_KEY -it --rm odk-ai:latest bash

# e.g. test-repos/obophenotype/uberon
# git clone https://github.com/obophenotype/uberon
test-repos/%:
	cd test-repos && git clone https://github.com/$*
	

##################
### Utilities ####
##################

.PHONY: help

help:
	@echo "Available Make targets:"
	@echo "  • build                 - Build the image for your local architecture"
	@echo "  • build-no-cache        - Build the image without using cache"
	@echo "  • build-dev             - Build the image tagged as 'dev'"
	@echo "  • clean                 - Remove any running/stopped container with image name"
	@echo "  • publish-multiarch     - Publish multi-architecture images (latest + version)"
	@echo "  • publish-multiarch-dev - Publish multi-architecture image tagged as 'dev'"
	@echo "  • reset-multiarch       - Reset the multiarch Docker buildx builder"
	@echo "  • test                  - Launch dev container for testing"
	@echo "  • test-repos/<repo>     - Clone a test repo by GitHub org/repo name"
