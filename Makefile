.PHONY: clean upgrade test quality quality-python test-python
# Generates a help message. Borrowed from https://github.com/pydanny/cookiecutter-djangopackage.
help: ## display this help message
	@echo "Please use \`make <target>\` where <target> is one of"
	@perl -nle'print $& if m{^[\.a-zA-Z_-]+:.*?## .*$$}' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m  %-25s\033[0m %s\n", $$1, $$2}'

clean: ## delete generated byte code and coverage reports
	find . -name '*.pyc' -delete
	find . -name '__pycache__' -type d -exec rm -rf {} ';' || true
	rm -rf coverage htmlcov
	rm -rf assets
	rm -rf pii_report

COMMON_CONSTRAINTS_TXT=requirements/common_constraints.txt
.PHONY: $(COMMON_CONSTRAINTS_TXT)
$(COMMON_CONSTRAINTS_TXT):
	wget -O "$(@)" https://raw.githubusercontent.com/edx/edx-lint/master/edx_lint/files/common_constraints.txt || touch "$(@)"

upgrade: export CUSTOM_COMPILE_COMMAND=make upgrade
upgrade: $(COMMON_CONSTRAINTS_TXT)  ## update the requirements/*.txt files with the latest packages satisfying requirements/*.in
	pip install -r requirements/pip.txt
	pip install -q -r requirements/pip_tools.txt
	pip-compile --upgrade --allow-unsafe --rebuild -o requirements/pip.txt requirements/pip.in
	pip-compile --upgrade -o requirements/pip_tools.txt requirements/pip_tools.in
	pip install -qr requirements/pip.txt
	pip install -qr requirements/pip_tools.txt
	pip-compile --upgrade -o requirements/base.txt requirements/base.in
	pip-compile --upgrade -o requirements/ci.txt requirements/ci.in
	pip-compile --upgrade -o requirements/test.txt requirements/test.in

requirements: ## install development environment requirements
	pip install -r requirements/pip.txt
	pip install -q -r requirements/pip_tools.txt
	pip install -qr requirements/base.txt --exists-action w
	pip-sync requirements/base.txt requirements/constraints.txt requirements/test.txt requirements/ci.txt

quality-python: ## Run python linters
	flake8 . --count --select=E901,E999,F821,F822,F823 --show-source --statistics
	flake8 . --count --exit-zero --max-complexity=10 --max-line-length=127 --statistics

quality: quality-python ## Run linters

test-python: clean ## run tests and generate coverage report
	-pytest

test: test-python ## run tests
