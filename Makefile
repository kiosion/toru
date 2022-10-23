.PHONY: dev, prod, test, cleanup

dev: SHELL:=/bin/bash
dev:
	@echo "target: development"
	@./bin/start -m dev

prod: SHELL:=/bin/bash
prod:
	@echo "target: production"
	@./bin/start -m prod
