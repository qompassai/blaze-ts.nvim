ifeq ($(OS),Windows_NT)
$(error Windows is not supported)
endif

LANGUAGE_NAME := mojo
HOMEPAGE_URL := https://github.com/qompassai/blaze-ts.nvim
VERSION := 0.1.0
BUILD_DIR := build
PARSER_NAME := $(LANGUAGE_NAME).so
PARSER_PATH := $(BUILD_DIR)/$(PARSER_NAME)
SRC_DIR := src
GRAMMAR_FILE := $(SRC_DIR)/grammar.js
SCANNER_FILE := $(SRC_DIR)/scanner.c
TS ?= tree-sitter
NODE := node
CC ?= gcc
CFLAGS ?= -O3 -Wall -Wextra -I./$(SRC_DIR) -fPIC

.PHONY: all install uninstall clean test

all: $(PARSER_PATH)

$(PARSER_PATH): $(SRC_DIR)/parser.c $(SCANNER_FILE)
	@mkdir -p $(BUILD_DIR)
	$(CC) $(CFLAGS) -shared -o $@ $^

$(SRC_DIR)/parser.c: $(GRAMMAR_FILE)
	@mkdir -p $(SRC_DIR)
	$(NODE) ./node_modules/.bin/tree-sitter generate $(GRAMMAR_FILE)

$(SRC_DIR)/node-types.json: $(SRC_DIR)/parser.c

generate: $(SRC_DIR)/parser.c $(SRC_DIR)/node-types.json

build: $(PARSER_PATH)

test:
	$(NODE) ./node_modules/.bin/tree-sitter test

clean:
	rm -rf $(BUILD_DIR)
	rm -f $(SRC_DIR)/parser.c
	rm -f $(SRC_DIR)/grammar.json
	rm -f $(SRC_DIR)/node-types.json

install: $(PARSER_PATH)
	@mkdir -p "$(HOME)/.local/share/nvim/site/parser"
	cp $(PARSER_PATH) "$(HOME)/.local/share/nvim/site/parser/"

package: $(PARSER_PATH)
	@mkdir -p lib
	cp $(PARSER_PATH) lib/
	sed -e 's|@LANGUAGE_NAME@|$(LANGUAGE_NAME)|g' \
		-e 's|@HOMEPAGE_URL@|$(HOMEPAGE_URL)|g' \
		-e 's|@VERSION@|$(VERSION)|g' \
		bindings/c/tree-sitter-mojo.pc.in > lib/tree-sitter-$(LANGUAGE_NAME).pc

