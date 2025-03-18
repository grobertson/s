# Makefile for the s tool

# Variables
VERSION := 1.0.0
PREFIX := /usr/local
BINDIR := $(PREFIX)/bin
LIBDIR := $(PREFIX)/lib/s
CONFIGDIR := $(HOME)/.s
CONFIGFILE := $(HOME)/.sconfig

# Colors for output
RED := \033[0;31m
GREEN := \033[0;32m
YELLOW := \033[1;33m
BLUE := \033[0;34m
NC := \033[0m # No Color

# Default target
all: install

# Install the tool
install: check-deps
	@echo -e "${BLUE}Installing s tool...${NC}"
	@mkdir -p $(BINDIR) $(LIBDIR)
	@cp -f bin/s $(BINDIR)/
	@chmod 755 $(BINDIR)/s
	@cp -f lib/*.sh $(LIBDIR)/
	@chmod 644 $(LIBDIR)/*.sh
	@echo -e "${GREEN}Installation complete${NC}"

# Install for current user only
install-home: check-deps
	@echo -e "${BLUE}Installing s tool for current user...${NC}"
	@mkdir -p $(HOME)/bin $(HOME)/.s/lib
	@cp -f bin/s $(HOME)/bin/
	@chmod 755 $(HOME)/bin/s
	@cp -f lib/*.sh $(HOME)/.s/lib/
	@chmod 644 $(HOME)/.s/lib/*.sh
	@echo -e "${GREEN}Installation complete${NC}"
	@echo -e "${YELLOW}Make sure $(HOME)/bin is in your PATH${NC}"

# Uninstall the tool
uninstall:
	@echo -e "${BLUE}Uninstalling s tool...${NC}"
	@rm -f $(BINDIR)/s
	@rm -rf $(LIBDIR)
	@echo -e "${GREEN}Uninstallation complete${NC}"

# Run tests
test: check-deps
	@echo -e "${BLUE}Running tests...${NC}"
	@./tests/run-tests.sh
	@echo -e "${GREEN}Tests complete${NC}"

# Check dependencies
check-deps:
	@echo -e "${BLUE}Checking dependencies...${NC}"
	@command -v bash >/dev/null 2>&1 || { echo -e "${RED}Error: bash is required${NC}"; exit 1; }
	@command -v ssh >/dev/null 2>&1 || { echo -e "${RED}Error: ssh is required${NC}"; exit 1; }
	@command -v ssh-keygen >/dev/null 2>&1 || { echo -e "${RED}Error: ssh-keygen is required${NC}"; exit 1; }
	@echo -e "${GREEN}All dependencies satisfied${NC}"

# Run shellcheck
lint:
	@echo -e "${BLUE}Running shellcheck...${NC}"
	@command -v shellcheck >/dev/null 2>&1 || { echo -e "${RED}Error: shellcheck is required${NC}"; exit 1; }
	@shellcheck bin/s lib/*.sh tests/*.sh
	@echo -e "${GREEN}Linting complete${NC}"

# Clean build artifacts
clean:
	@echo -e "${BLUE}Cleaning...${NC}"
	@rm -rf build/
	@find . -type f -name "*.log" -delete
	@echo -e "${GREEN}Clean complete${NC}"

# Show help
help:
	@echo -e "${BLUE}Available targets:${NC}"
	@echo -e "  ${GREEN}install${NC}      - Install system-wide (requires root)"
	@echo -e "  ${GREEN}install-home${NC} - Install for current user only"
	@echo -e "  ${GREEN}uninstall${NC}    - Remove the tool"
	@echo -e "  ${GREEN}test${NC}         - Run tests"
	@echo -e "  ${GREEN}lint${NC}         - Run shellcheck"
	@echo -e "  ${GREEN}clean${NC}        - Clean build artifacts"
	@echo -e "  ${GREEN}help${NC}         - Show this help message"

.PHONY: all install install-home uninstall test check-deps lint clean help 