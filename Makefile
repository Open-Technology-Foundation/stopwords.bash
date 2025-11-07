# Makefile for stopwords.bash
# Installation wrapper around install.sh

# Project metadata
PROJECT = stopwords
VERSION = 1.0.0

# Installation configuration
# PREFIX: Installation prefix (default: /usr/local)
# DESTDIR: Staging directory for package builds (default: empty)
PREFIX ?= /usr/local
DESTDIR ?=

# NLTK_DATA: NLTK data directory (default: /usr/share/nltk_data)
NLTK_DATA ?= /usr/share/nltk_data

# Installation script
INSTALL_SCRIPT = ./install.sh

# Export variables for install.sh
export PREFIX
export NLTK_DATA

# Default target
.DEFAULT_GOAL := help

# PHONY targets (not actual files)
.PHONY: all install uninstall check test verify help clean

# Help target (default)
help:
	@echo "$(PROJECT) v$(VERSION) - Installation Makefile"
	@echo ""
	@echo "Usage: make [TARGET] [VARIABLES]"
	@echo ""
	@echo "Targets:"
	@echo "  install     Install $(PROJECT) (requires sudo for system install)"
	@echo "  uninstall   Remove $(PROJECT) installation"
	@echo "  check       Verify installation status"
	@echo "  test        Alias for 'check'"
	@echo "  verify      Alias for 'check'"
	@echo "  help        Show this help message (default)"
	@echo ""
	@echo "Variables:"
	@echo "  PREFIX      Installation prefix (default: /usr/local)"
	@echo "              For user install: make PREFIX=\$$HOME/.local install"
	@echo "  NLTK_DATA   NLTK data directory (default: /usr/share/nltk_data)"
	@echo "  DESTDIR     Staging directory for package builds (default: empty)"
	@echo ""
	@echo "Examples:"
	@echo "  # System-wide installation (requires sudo)"
	@echo "  sudo make install"
	@echo ""
	@echo "  # User-local installation (no sudo needed)"
	@echo "  make PREFIX=\$$HOME/.local install"
	@echo ""
	@echo "  # Custom NLTK data location"
	@echo "  make NLTK_DATA=\$$HOME/nltk_data install"
	@echo ""
	@echo "  # Check installation"
	@echo "  make check"
	@echo ""
	@echo "  # Uninstall"
	@echo "  sudo make uninstall"
	@echo ""
	@echo "Current Configuration:"
	@echo "  PREFIX:     $(PREFIX)"
	@echo "  NLTK_DATA:  $(NLTK_DATA)"
	@echo "  DESTDIR:    $(DESTDIR)"

# Install target
install:
	@echo "Installing $(PROJECT) with PREFIX=$(PREFIX)"
	@if [ -n "$(DESTDIR)" ]; then \
		echo "Using DESTDIR=$(DESTDIR) (package staging)"; \
		PREFIX="$(DESTDIR)$(PREFIX)" NLTK_DATA="$(DESTDIR)$(NLTK_DATA)" $(INSTALL_SCRIPT) install; \
	else \
		$(INSTALL_SCRIPT) install; \
	fi

# Uninstall target
uninstall:
	@echo "Uninstalling $(PROJECT)"
	@if [ -n "$(DESTDIR)" ]; then \
		PREFIX="$(DESTDIR)$(PREFIX)" NLTK_DATA="$(DESTDIR)$(NLTK_DATA)" $(INSTALL_SCRIPT) uninstall; \
	else \
		$(INSTALL_SCRIPT) uninstall; \
	fi

# Check/verify targets
check:
	@$(INSTALL_SCRIPT) check

test: check

verify: check

# Clean target (for compatibility - nothing to clean in this project)
clean:
	@echo "Nothing to clean (no build artifacts)"

# All target (install)
all: install
