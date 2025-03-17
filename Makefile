.PHONY: all test install install-home uninstall clean lint help check-deps

all: test

test:
	@echo "Running tests..."
	@chmod +x tests/test-s.sh
	@./tests/test-s.sh

check-deps:
	@echo "Checking dependencies..."
	@if ! command -v ssh-keygen >/dev/null 2>&1; then \
		echo "Error: ssh-keygen not found. Please install OpenSSH first."; \
		exit 1; \
	fi
	@if ! command -v shellcheck >/dev/null 2>&1; then \
		echo "Warning: shellcheck not found. Install it for linting."; \
	fi

install: check-deps
	@echo "Installing s system-wide..."
	@if [ -z "$$SUDO_USER" ] && [ "$$(id -u)" != "0" ]; then \
		echo "Error: System-wide installation requires root privileges"; \
		echo "Please run: sudo make install"; \
		exit 1; \
	fi
	@if ! sudo -n true 2>/dev/null; then \
		echo "Error: No sudo access available. Please configure sudo access first."; \
		exit 1; \
	fi
	@chmod +x bin/s
	@./bin/s --install system

install-home: check-deps
	@echo "Installing s for current user..."
	@if [ ! -w "$$HOME" ]; then \
		echo "Error: Cannot write to home directory"; \
		exit 1; \
	fi
	@chmod +x bin/s
	@./bin/s --install home

uninstall:
	@echo "Uninstalling s..."
	@if [ -z "$$SUDO_USER" ] && [ "$$(id -u)" != "0" ]; then \
		echo "Error: System-wide uninstallation requires root privileges"; \
		echo "Please run: sudo make uninstall"; \
		exit 1; \
	fi
	@if ! sudo -n true 2>/dev/null; then \
		echo "Error: No sudo access available. Please configure sudo access first."; \
		exit 1; \
	fi
	@./bin/s --remove force

clean:
	@echo "Cleaning up..."
	@rm -rf tests/*.tmp
	@rm -rf tests/*.log

lint: check-deps
	@echo "Running shellcheck..."
	@if command -v shellcheck >/dev/null 2>&1; then \
		shellcheck bin/s bin/s-common.sh tests/*.sh; \
	else \
		echo "Warning: shellcheck not found. Skipping linting."; \
	fi

help:
	@echo "Available targets:"
	@echo "  test        - Run test suite"
	@echo "  install     - Install s system-wide (requires root)"
	@echo "  install-home - Install s for current user"
	@echo "  uninstall   - Remove s from all locations"
	@echo "  clean       - Clean up test artifacts"
	@echo "  lint        - Run shellcheck on scripts"
	@echo "  help        - Show this help message" 