# Terminal colors
GREEN  := $(shell tput -Txterm setaf 2)
YELLOW := $(shell tput -Txterm setaf 3)
WHITE  := $(shell tput -Txterm setaf 7)
RESET  := $(shell tput -Txterm sgr0)
BLUE   := $(shell tput -Txterm setaf 4)

# Project settings
PYTHON_VERSION := 3.12
VENV_NAME := .venv
PROJECT_NAME := pr-agent
REPO_ROOT := $(shell pwd)
PYTHON := $(REPO_ROOT)/$(VENV_NAME)/bin/python

# Test settings
TEST_PATH := tests/
PYTEST_ARGS ?= -v
COVERAGE_THRESHOLD := 90

RUN_ARGS ?= --help

help: ## Show this help message
	@echo ''
	@echo '${YELLOW}Development Guide${RESET}'
	@echo ''
	@echo '${YELLOW}Installation Options:${RESET}'
	@echo '  Basic:      ${GREEN}make install${RESET}        - Install pr-agent'
	@echo '  All:        ${GREEN}make install-all${RESET}    - Install with all dependencies'
	@echo '  Development:${GREEN}make install-dev${RESET}    - Development tools'
	@echo ''
	@echo '${YELLOW}Development Workflow:${RESET}'
	@echo '  1. Setup:     ${GREEN}make setup${RESET}         - Full development environment'
	@echo '  2. Source:    ${GREEN}source setup.sh${RESET}    - Activate environment'
	@echo '  3. Install:   ${GREEN}make install-all${RESET}   - Install packages'
	@echo ''
	@echo '${YELLOW}Available Targets:${RESET}'
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  ${YELLOW}%-15s${GREEN}%s${RESET}\n", $$1, $$2}' $(MAKEFILE_LIST)
	@echo ''

# Development environment targets
.PHONY: env
env: ## Create virtual environment using uv
	@echo "${BLUE}Creating virtual environment...${RESET}"
	uv venv --python $(PYTHON_VERSION)
	@echo "${GREEN}Virtual environment created. Activate it with:${RESET}"
	@echo "source $(VENV_NAME)/bin/activate"

.PHONY: install
install: ## Install pr-agent package
	@echo "${BLUE}Installing pr-agent package...${RESET}"
	uv pip install -e .
	@echo "${GREEN}pr-agent installed successfully${RESET}"
	@# Verify installation
	@$(PYTHON) -c "import pr_agent; print(f'pr-agent installed at: {pr_agent.__file__}')"

.PHONY: install-all
install-all: install ## Install pr-agent with all optional dependencies
	@echo "${BLUE}Installing optional dependencies...${RESET}"
	uv pip install -e ".[all]"
	@echo "${GREEN}All dependencies installed successfully${RESET}"

.PHONY: install-dev
install-dev: ## Install development dependencies
	@echo "${BLUE}Installing development tools...${RESET}"
	uv pip install -e ".[dev]"
	uv pip install -r requirements-dev.txt
	@echo "${GREEN}Development dependencies installed successfully${RESET}"

.PHONY: setup
setup: ## Create environment and install full development dependencies
	@echo "${BLUE}Creating complete development environment...${RESET}"
	@echo '#!/bin/bash' > setup.sh
	@echo 'uv venv --python $(PYTHON_VERSION)' >> setup.sh
	@echo 'source $(VENV_NAME)/bin/activate' >> setup.sh
	@echo 'make install-all' >> setup.sh
	@echo 'make install-dev' >> setup.sh
	@echo 'echo "${GREEN}Setup complete! Development environment ready.${RESET}"' >> setup.sh
	@echo 'rm "$$0"' >> setup.sh
	@chmod +x setup.sh
	@echo "${GREEN}Environment setup script created. To complete setup, run:${RESET}"
	@echo "${YELLOW}source setup.sh${RESET}"

.PHONY: update
update: ## Update all dependencies
	@echo "${BLUE}Updating dependencies...${RESET}"
	make install-dev

.PHONY: test
test: ## Run tests with coverage
	@echo "${BLUE}Running tests with coverage...${RESET}"
	PYTHONPATH="$(REPO_ROOT):$(REPO_ROOT)/tests:$(PYTHONPATH)" \
	$(REPO_ROOT)/$(VENV_NAME)/bin/python -m pytest tests -v --cov=pr_agent --cov-report=term-missing

.PHONY: test-unit
test-unit: ## Run unit tests
	@echo "${BLUE}Running unit tests...${RESET}"
	PYTHONPATH="$(REPO_ROOT):$(REPO_ROOT)/tests:$(PYTHONPATH)" \
	$(REPO_ROOT)/$(VENV_NAME)/bin/python -m pytest tests/unittest -v --cov=pr_agent --cov-report=term-missing

.PHONY: test-e2e
test-e2e: ## Run end-to-end tests
	@echo "${BLUE}Running end-to-end tests...${RESET}"
	PYTHONPATH="$(REPO_ROOT):$(PYTHONPATH)" \
	$(REPO_ROOT)/$(VENV_NAME)/bin/python -m pytest tests/e2e_tests $(PYTEST_ARGS) \
		--cov=pr_agent --cov-report=term-missing

.PHONY: test-health
test-health: ## Run health tests
	@echo "${BLUE}Running health tests...${RESET}"
	PYTHONPATH="$(REPO_ROOT):$(PYTHONPATH)" \
	$(REPO_ROOT)/$(VENV_NAME)/bin/python -m pytest tests/health_test $(PYTEST_ARGS)

.PHONY: format
format: ## Format code with Ruff and isort
	@echo "${BLUE}Formatting code...${RESET}"
	$(PYTHON) -m ruff check pr_agent/ --fix
	$(PYTHON) -m ruff format .
	$(PYTHON) -m isort .

.PHONY: lint
lint: ## Run linters
	@echo "${BLUE}Running linters...${RESET}"
	$(PYTHON) -m ruff check pr_agent/ tests/
	$(PYTHON) -m ruff format --check pr_agent/ tests/
	$(PYTHON) -m mypy pr_agent/ tests/

.PHONY: clean
clean: ## Clean build artifacts and cache
	@echo "${BLUE}Cleaning build artifacts and cache...${RESET}"
	rm -rf build/ dist/ *.egg-info .coverage .mypy_cache .pytest_cache .ruff_cache $(VENV_NAME)
	rm -rf setup.sh
	find . -type d -name "__pycache__" -exec rm -rf {} +
	find . -type f -name "*.pyc" -delete
	@echo "${GREEN}Cleaned all build artifacts and cache.${RESET}"

.PHONY: build
build: clean format lint test ## Build package for distribution
	@echo "${BLUE}Building package for distribution...${RESET}"
	uv pip build
	@echo "${GREEN}Package built successfully. Distribution files in dist/ directory.${RESET}"

.PHONY: publish
publish: build ## Publish package to PyPI
	@echo "${BLUE}Publishing package to PyPI...${RESET}"
	@echo "${YELLOW}This will publish pr-agent to PyPI.${RESET}"
	@echo "${YELLOW}Are you sure you want to continue? (y/n)${RESET}"
	@read -p " " yn; \
	if [ "$$yn" = "y" ]; then \
		uv pip publish --repository pypi; \
		echo "${GREEN}Package published successfully!${RESET}"; \
	else \
		echo "${YELLOW}Publishing cancelled.${RESET}"; \
	fi

.PHONY: pre-commit
pre-commit: format lint test ## Run all checks before committing
	@echo "${GREEN}✓ All checks passed${RESET}"

.PHONY: structure
structure: ## Show project structure
	@echo "${YELLOW}Current Project Structure:${RESET}"
	@echo "${BLUE}"
	@if command -v tree > /dev/null; then \
		tree -a -I '.git|.venv|__pycache__|*.pyc|*.pyo|*.pyd|.pytest_cache|.ruff_cache|.coverage|htmlcov'; \
	else \
		find . -not -path '*/\.*' -not -path '*.pyc' -not -path '*/__pycache__/*' \
			-not -path './.venv/*' -not -path './build/*' -not -path './dist/*' \
			-not -path './*.egg-info/*' \
			| sort | \
			sed -e "s/[^-][^\/]*\// │   /g" -e "s/├── /│── /" -e "s/└── /└── /"; \
	fi
	@echo "${RESET}"

# Additional targets
.PHONY: prune-branches
prune-branches: ## Remove local branches that are no longer tracked on the remote
	@echo "${BLUE}Pruning local branches that are no longer tracked on the remote...${RESET}"
	@git fetch -p && \
	  for branch in $$(git branch -vv | grep ': gone]' | awk '{print $$1}'); do \
	    git branch -D $$branch; \
	  done
	@echo "${GREEN}Stale branches have been removed.${RESET}"

.PHONY: add-paths
add-paths: ## Add file paths as first-line comments to all Python files
	@echo "${BLUE}Adding file paths as comments to Python files...${RESET}"
	@echo '#!/usr/bin/env python' > add_paths.py
	@echo '# add_paths.py' >> add_paths.py
	@echo '"""' >> add_paths.py
	@echo 'Script to add file paths as first-line comments to Python files.' >> add_paths.py
	@echo '"""' >> add_paths.py
	@echo 'import os' >> add_paths.py
	@echo 'import sys' >> add_paths.py
	@echo 'import traceback' >> add_paths.py
	@echo '' >> add_paths.py
	@echo 'def update_file(filepath):' >> add_paths.py
	@echo '    try:' >> add_paths.py
	@echo '        relpath = os.path.relpath(filepath)' >> add_paths.py
	@echo '        print(f"Processing {relpath}...")' >> add_paths.py
	@echo '' >> add_paths.py
	@echo '        with open(filepath, "r") as f:' >> add_paths.py
	@echo '            content = f.read()' >> add_paths.py
	@echo '' >> add_paths.py
	@echo '        lines = content.split("\\n")' >> add_paths.py
	@echo '        if not lines:' >> add_paths.py
	@echo '            print(f"  Skipping {relpath}: empty file")' >> add_paths.py
	@echo '            return' >> add_paths.py
	@echo '' >> add_paths.py
	@echo '        has_path_comment = False' >> add_paths.py
	@echo '        if lines[0].strip().startswith("#"):' >> add_paths.py
	@echo '            has_path_comment = True' >> add_paths.py
	@echo '            old_line = lines[0]' >> add_paths.py
	@echo '            lines[0] = f"# {relpath}"' >> add_paths.py
	@echo '            print(f"  Replacing comment: {old_line} -> # {relpath}")' >> add_paths.py
	@echo '        else:' >> add_paths.py
	@echo '            lines.insert(0, f"# {relpath}")' >> add_paths.py
	@echo '            print(f"  Adding new comment: # {relpath}")' >> add_paths.py
	@echo '' >> add_paths.py
	@echo '        with open(filepath, "w") as f:' >> add_paths.py
	@echo '            f.write("\\n".join(lines))' >> add_paths.py
	@echo '' >> add_paths.py
	@echo '        print(f"  Updated {relpath}")' >> add_paths.py
	@echo '    except Exception as e:' >> add_paths.py
	@echo '        print(f"  Error processing {filepath}: {str(e)}")' >> add_paths.py
	@echo '        traceback.print_exc()' >> add_paths.py
	@echo '' >> add_paths.py
	@echo 'def main():' >> add_paths.py
	@echo '    try:' >> add_paths.py
	@echo '        count = 0' >> add_paths.py
	@echo '        print("Starting file scan...")' >> add_paths.py
	@echo '        for root, dirs, files in os.walk("."):' >> add_paths.py
	@echo '            # Skip hidden and build directories' >> add_paths.py
	@echo '            if any(x in root for x in [".git", ".venv", "__pycache__", ".mypy_cache",' >> add_paths.py
	@echo '                                      ".pytest_cache", ".ruff_cache", "build", "dist", ".egg-info"]):' >> add_paths.py
	@echo '                continue' >> add_paths.py
	@echo '' >> add_paths.py
	@echo '            for file in files:' >> add_paths.py
	@echo '                if file.endswith(".py"):' >> add_paths.py
	@echo '                    filepath = os.path.join(root, file)' >> add_paths.py
	@echo '                    update_file(filepath)' >> add_paths.py
	@echo '                    count += 1' >> add_paths.py
	@echo '' >> add_paths.py
	@echo '        print(f"Processed {count} Python files")' >> add_paths.py
	@echo '    except Exception as e:' >> add_paths.py
	@echo '        print(f"Fatal error: {str(e)}")' >> add_paths.py
	@echo '        traceback.print_exc()' >> add_paths.py
	@echo '        sys.exit(1)' >> add_paths.py
	@echo '' >> add_paths.py
	@echo 'if __name__ == "__main__":' >> add_paths.py
	@echo '    main()' >> add_paths.py
	@chmod +x add_paths.py
	@$(PYTHON) add_paths.py
	@rm add_paths.py
	@echo "${GREEN}✓ File paths added to all Python files${RESET}"

.PHONY: run
run: ## Run pr-agent with arguments specified via RUN_ARGS
	@echo "${BLUE}Running pr-agent...${RESET}"
	$(PYTHON) -m pr_agent.cli $(RUN_ARGS)

.PHONY: docs
docs: ## Build documentation
	@echo "${BLUE}Building documentation...${RESET}"
	cd docs && mkdocs build
	@echo "${GREEN}Documentation built successfully. Open docs/site/index.html in your browser.${RESET}"

.PHONY: docs-serve
docs-serve: ## Serve documentation locally
	@echo "${BLUE}Serving documentation locally...${RESET}"
	cd docs && mkdocs serve
	@echo "${GREEN}Documentation server stopped.${RESET}"

.DEFAULT_GOAL := help