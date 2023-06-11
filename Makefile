.PHONY: dev release run test clean

DOCKER_EXISTS := $(shell docker --help > /dev/null 2>&1; echo $$?)

PORT ?= 3000

install: SHELL:=/bin/bash
install:
	@mix local.hex --if-missing --force > /dev/null
	@mix local.rebar --force > /dev/null
	@mix deps.get > /dev/null

dev: SHELL:=/bin/bash
dev: # Run the development environment
	@bash -c "printf \"Building dependencies\r\" &&\
	mix local.hex --if-missing --force > /dev/null &&\
	mix local.rebar --if-missing --force > /dev/null &&\
	mix deps.get > /dev/null && \
	mix do clean, compile > /dev/null &&\
	printf \"\n\r\""
	@source ./.env && LFM_TOKEN=$$LFM_TOKEN mix run --no-halt

release: SHELL:=/bin/bash
release: # Check docker and env vars are present then build container
ifndef LFM_TOKEN
	$(error No token provided. Please set LFM_TOKEN environment variable)
endif
ifdef DOCKER_EXISTS
	@docker build --build-arg PORT=$(PORT) --build-arg LFM_TOKEN=$(LFM_TOKEN) --network=host -t toru:latest .
else
	@echo "Docker is not available. Please install docker and try again."
endif

run: SHELL:=/bin/bash
run: # Check docker is present then run container
ifdef DOCKER_EXISTS
	@docker stop toru > /dev/null || true && docker rm toru > /dev/null || true
	@docker run -it -d --network=host --name toru toru:latest
else
	@echo "Docker is not available. Please install docker and try again."
endif

test: SHELL:=/bin/bash
test: install
test: # Run the mix test suite
	@mix deps.compile --only=test
	@source ./.env || true && LFM_TOKEN=$$LFM_TOKEN MIX_ENV=test mix test

clean: SHELL:=/bin/bash
clean: # Remove unused dirs
	@rm -rf ./_build ./deps ./erl_crash.dump
