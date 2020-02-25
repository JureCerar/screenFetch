# Source and app name
APP = screenfetch
DIR := /usr/local/bin
SRC = screenfetch.sh

# Compiler and install
INSTALL := install

# -------------------

default:

.PHONY: install

install: $(SRC)
	@echo "-- Binaries will be installed to:" $(DIR)
	$(INSTALL) $(SRC) $(DIR)/$(APP)
