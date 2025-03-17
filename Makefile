.PHONY: all test install clean

all: test

test:
	@echo "Running tests..."
	@chmod +x tests/test-s.sh
	@./tests/test-s.sh

install:
	@echo "Installing s..."
	@chmod +x bin/s
	@./bin/s --install system

install-home:
	@echo "Installing s for current user..."
	@chmod +x bin/s
	@./bin/s --install home

uninstall:
	@echo "Uninstalling s..."
	@./bin/s --remove force

clean:
	@echo "Cleaning up..."
	@rm -rf tests/*.tmp
	@rm -rf tests/*.log

lint:
	@echo "Running shellcheck..."
	@shellcheck bin/s bin/s-common.sh tests/*.sh

help:
	@echo "Available targets:"
	@echo "  test        - Run test suite"
	@echo "  install     - Install s system-wide (requires root)"
	@echo "  install-home - Install s for current user"
	@echo "  uninstall   - Remove s from all locations"
	@echo "  clean       - Clean up test artifacts"
	@echo "  lint        - Run shellcheck on scripts"
	@echo "  help        - Show this help message" 