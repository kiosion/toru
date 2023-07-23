SHELL:=/bin/bash

.PHONY: dev test clean

install:
	@bash -c "printf \"Fetching dependencies...\r\" &&\
	mix local.hex --if-missing --force > /dev/null &&\
	mix local.rebar --force > /dev/null &&\
	mix deps.get > /dev/null &&\
	printf \"\033[K\r\""

dev: install # Run the development environment
	@printf "Starting dev server..."
	@mix do clean, compile > /dev/null
	@source ./.env && LFM_TOKEN=$$LFM_TOKEN mix run --no-halt

test: install # Run the mix test suite
	@printf "Running tests...\n"
	@mix deps.compile --only test
	@MIX_ENV=test mix test

clean: # Remove unused dirs
	@rm -rf ./_build ./deps ./erl_crash.dump
