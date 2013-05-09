PREFIX ?= ~/.local

# source files
CONFIG = ./etc/sconfig
BIN = ./bin/s

# installed locations
INSTALL_CONFIG ?= $(HOME)/.sconfig
INSTALL_BIN ?= $(PREFIX)/bin/s

.PHONY: install uninstall
install: $(INSTALL_CONFIG) $(INSTALL_BIN)

uninstall:
	rm -f $(INSTALL_CONFIG)
	rm -f $(INSTALL_BIN)

$(INSTALL_CONFIG): $(CONFIG)
	install -m 644 $^ $@

$(INSTALL_BIN): $(BIN)
	install -m 755 $^ $@
	@echo '--> Please make sure $(PREFIX)/bin is on your $$PATH <--'
