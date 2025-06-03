# Makefile for ODK-AI

RESET_MULTIARCH_ON_BUILD=true

CACHE=

ARCH=linux/$(shell uname -m | sed 's/x86_64/amd64/')
PLATFORMS=linux/amd64,linux/arm64

.PHONY: .FORCE

VERSION = v0.1
IM=cmungall/odk-ai
TAGS_OPTION=-t $(IM):$(VERSION) -t $(IM):latest

.PHONY: build build-no-cache build-dev build-dev-no-cache clean ensure-gh-token

# Ensure GH_TOKEN is set

ensure-gh-token:
	@if [ -z "$$GH_TOKEN" ]; then \
		echo "ERROR: GH_TOKEN environment variable is not set"; \
		echo "Please set it with: export GH_TOKEN=your_github_token"; \
		echo "You can create a token at https://github.com/settings/tokens"; \
		exit 1; \
	fi

build: ensure-gh-token
	docker build $(CACHE) --platform $(ARCH) \
		--build-arg GH_TOKEN=$(GH_TOKEN)
	    $(TAGS_OPTION) \
	    .

build-no-cache:
	$(MAKE) build CACHE=--no-cache

build-dev: ensure-gh-token
	docker build $(CACHE) --platform $(ARCH) \
		--build-arg GH_TOKEN=$(GH_TOKEN) \
		-t $(IM):dev \
		.

build-dev-no-cache:
	$(MAKE) build CACHE=--no-cache

clean:
	docker rm -f $(IM) || true

#### Publishing #####

.PHONY: publish-multiarch publish-multiarch-dev test

publish-multiarch: ensure-gh-token
	$(MAKE) reset-multiarch
	docker buildx build $(CACHE) --push --platform $(PLATFORMS) \
	    $(TAGS_OPTION) \
	    .

publish-multiarch-dev: ensure-gh-token
	$(MAKE) reset-multiarch
	docker buildx build $(CACHE) --push --platform $(PLATFORMS) \
		--build-arg GH_TOKEN=$(GH_TOKEN) \
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
	@echo "  • build-dev-no-cache    - Build the 'dev' image without using cache"
	@echo "  • clean                 - Remove any running/stopped container with image name"
	@echo "  • publish-multiarch     - Publish multi-architecture images (latest + version)"
	@echo "  • publish-multiarch-dev - Publish multi-architecture image tagged as 'dev'"
	@echo "  • reset-multiarch       - Reset the multiarch Docker buildx builder"
	@echo "  • test                  - Launch dev container for testing"
	@echo "  • test-repos/<repo>     - Clone a test repo by GitHub org/repo name"
