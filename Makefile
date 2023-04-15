.PHONY: fmt validate plan apply init clean help

SHELL := /bin/bash
ENV ?= dev
COMPONENT ?= platform

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

fmt: ## Format all Terraform files
	@echo "Formatting Terraform files..."
	terraform fmt -recursive .

validate: ## Validate all modules
	@./scripts/validate.sh

init: ## Initialize Terraform for a specific environment
	@echo "Initializing $(ENV)..."
	cd environments/$(ENV) && terraform init

plan: ## Run terraform plan for a specific environment
	@echo "Planning $(ENV)..."
	cd environments/$(ENV) && terraform plan

apply: ## Run terraform apply for a specific environment
	@echo "Applying $(ENV)..."
	cd environments/$(ENV) && terraform apply

clean: ## Remove .terraform directories
	@echo "Cleaning up..."
	find . -type d -name ".terraform" -exec rm -rf {} + 2>/dev/null || true
	find . -type f -name ".terraform.lock.hcl" -delete 2>/dev/null || true
	@echo "Done."
