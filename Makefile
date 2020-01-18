# Source and app name
APP = screenfetch
DIR := /usr/bin
SRC = screenfetch-jpc.sh

# Compiler and install
INSTALL := install

# -------------------

default:
	@echo "-- Binaries will be installed to:" $(DIR)

.PHONY: clean install

install: $(SRC)
	$(INSTALL) $(SRC) $(DIR)/$(APP)

clean:
