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

test: SHELL:=/bin/bash
test: install
test: # Run the mix test suite
	@mix deps.compile --only test
	@MIX_ENV=test mix test

clean: SHELL:=/bin/bash
clean: # Remove unused dirs
	@rm -rf ./_build ./deps ./erl_crash.dump
