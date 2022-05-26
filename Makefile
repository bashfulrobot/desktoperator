SHELL=/bin/bash

# CREDIT - Colour pulled from https://gist.github.com/rsperl/d2dfe88a520968fbc1f49db0a29345b9

# to see all colors, run
# bash -c 'for c in {0..255}; do tput setaf $c; tput setaf $c | cat -v; echo =$c; done'
# the first 15 entries are the 8-bit colors

# define standard colors
ifneq (,$(findstring xterm,${TERM}))
	BLACK        := $(shell tput -Txterm setaf 0)
	RED          := $(shell tput -Txterm setaf 1)
	GREEN        := $(shell tput -Txterm setaf 2)
	YELLOW       := $(shell tput -Txterm setaf 3)
	LIGHTPURPLE  := $(shell tput -Txterm setaf 4)
	PURPLE       := $(shell tput -Txterm setaf 5)
	BLUE         := $(shell tput -Txterm setaf 6)
	WHITE        := $(shell tput -Txterm setaf 7)
	RESET := $(shell tput -Txterm sgr0)
else
	BLACK        := ""
	RED          := ""
	GREEN        := ""
	YELLOW       := ""
	LIGHTPURPLE  := ""
	PURPLE       := ""
	BLUE         := ""
	WHITE        := ""
	RESET        := ""
endif

# set target color
TARGET_COLOR := $(BLUE)

POUND = \#

.DEFAULT_GOAL := help

TOWER-PLAYBOOK = playbooks/tower.yaml
SD-LAPTOP-PLAYBOOK = playbooks/sd-laptop.yaml
BOOTSTRAP = playbooks/bootstrap.yaml
TEST-PLAYBOOK = playbooks/test.yaml

install: ## install software dependencies
	@echo "${BLUE}installing software dependencies ${RESET}"
	@sudo apt update
	@sudo apt install git curl wget vim-nox python3-pip -y
	@sudo pip install ansible Jinja2
	@echo "${BLUE}installing playbook dependencies ${RESET}"
	@ansible-galaxy install -r requirements.yaml --ignore-errors --force
requirements: ## install ansible requirements
	@echo "${BLUE}installing ansible requirements${RESET}"
	@ansible-galaxy install -r requirements.yaml --ignore-errors --force
run-bootstrap: ## run all ansible tasks
	@echo "${BLUE}running bootstrap${RESET}"
	@ansible-playbook --ask-become-pass --ask-vault-pass --connection=local "${BOOTSTRAP}"
run-desktop: ## run all ansible tasks
	@echo "${BLUE}running all ansible tasks${RESET}"
	@git pull
	@ansible-playbook --ask-become-pass --ask-vault-pass --connection=local "${TOWER-PLAYBOOK}"
run-sd-laptop: ## run all ansible tasks
	@echo "${BLUE}running all ansible tasks${RESET}"
	@git pull
	@ansible-playbook --ask-become-pass --ask-vault-pass --connection=local "${SD-LAPTOP-PLAYBOOK}"
run-test-playbook: ## run all ansible tasks
	@echo "${BLUE}running all ansible tasks${RESET}"
	@ansible-playbook --ask-become-pass --ask-vault-pass --connection=local "${TEST-PLAYBOOK}"
see_tags: ## run to see which tags are in use in the playbook
	@echo "${BLUE}retreived ansible tags ${RESET}"
	@grep -R 'tags:' . | grep -v '#' | less
help:
	@echo ""
	@echo "    ${BLACK}:: ${RED}Makefile Help${RESET} ${BLACK}::${RESET}"
	@echo ""
	@echo "Available options are:"
	@echo "-----------------------------------------------------------------${RESET}"
	@grep -E '^[a-zA-Z_0-9%-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "${TARGET_COLOR}%-30s${RESET} %s\n", $$1, $$2}'
