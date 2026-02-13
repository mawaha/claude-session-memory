.PHONY: help install test lint clean

help: ## Show this help message
	@echo 'Usage: make [target]'
	@echo ''
	@echo 'Available targets:'
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

install: ## Install the plugin
	@./install.sh

test: ## Run all tests
	@./test.sh

lint: ## Lint shell scripts
	@echo "Linting shell scripts..."
	@if command -v shellcheck > /dev/null; then \
		shellcheck hooks/*.sh install.sh test.sh; \
		echo "✅ Linting passed"; \
	else \
		echo "⚠️  shellcheck not installed. Install with: brew install shellcheck"; \
		exit 1; \
	fi

clean: ## Remove test artifacts
	@echo "Cleaning test artifacts..."
	@rm -rf tests/test-output
	@echo "✅ Cleaned"

uninstall: ## Uninstall the plugin
	@echo "Uninstalling plugin..."
	@if [ -L "$$HOME/.claude/plugins/session-memory" ]; then \
		rm "$$HOME/.claude/plugins/session-memory"; \
		echo "✅ Plugin uninstalled"; \
	else \
		echo "⚠️  Plugin not installed"; \
	fi

check-deps: ## Check if required dependencies are installed
	@echo "Checking dependencies..."
	@command -v jq >/dev/null 2>&1 || { echo "❌ jq not installed"; exit 1; }
	@command -v git >/dev/null 2>&1 || { echo "❌ git not installed"; exit 1; }
	@command -v bats >/dev/null 2>&1 || { echo "⚠️  bats not installed (needed for tests)"; }
	@echo "✅ All required dependencies installed"
