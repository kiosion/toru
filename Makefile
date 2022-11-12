.PHONY: dev, release, run, test, cleanup

DOCKER_EXISTS := $(shell docker --help > /dev/null 2>&1; echo $$?)

dev: SHELL:=/bin/bash
dev: # Run the development environment
	@./bin/start -m dev

release: SHELL:=/bin/bash
release: # Check docker is present then build container
ifdef DOCKER_EXISTS
	@docker build --build-arg PORT=$(PORT) --build-arg LFM_TOKEN=$(LFM_TOKEN) -t toru:latest .
else
	@echo "Docker is not available. Please install docker and try again."
endif

run: SHELL:=/bin/bash
run: # Check docker is present then run container
ifdef DOCKER_EXISTS
	@docker stop toru-latest > /dev/null || true && docker rm toru-latest > /dev/null || true
	@docker run -p $(PORT):$(PORT) -it -d --name toru-latest toru:latest
else
	@echo "Docker is not available. Please install docker and try again."
endif

test: SHELL:=/bin/bash
test: # Run the mix test suite
	@source ./.env && mix test --verbose

cleanup: SHELL:=/bin/bash
cleanup: # Remove unused dirs
	@rm -rf _build deps
