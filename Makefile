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
	$(NODE) ./node_modules/.bin/tree-sitter generate

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

# Create a linkable version with package metadata
package: $(PARSER_PATH)
	@mkdir -p lib
	cp $(PARSER_PATH) lib/
	sed -e 's|@LANGUAGE_NAME@|$(LANGUAGE_NAME)|g' \
		-e 's|@HOMEPAGE_URL@|$(HOMEPAGE_URL)|g' \
		-e 's|@VERSION@|$(VERSION)|g' \
		bindings/c/tree-sitter-mojo.pc.in > lib/tree-sitter-$(LANGUAGE_NAME).pc


#PREFIX ?= /usr/local
#DATADIR ?= $(PREFIX)/share
#INCLUDEDIR ?= $(PREFIX)/include
#LIBDIR ?= $(PREFIX)/lib
#PCLIBDIR ?= $(LIBDIR)/pkgconfig

# source/object files
#PARSER := $(SRC_DIR)/parser.c
#EXTRAS := $(filter-out $(PARSER),$(wildcard $(SRC_DIR)/*.c))
#OBJS := $(patsubst %.c,%.o,$(PARSER) $(EXTRAS))

# flags
#ARFLAGS ?= rcs
#override CFLAGS += -I$(SRC_DIR) -std=c11 -fPIC

# ABI versioning
#SONAME_MAJOR = $(shell sed -n 's/\#define LANGUAGE_VERSION //p' $(PARSER))
#SONAME_MINOR = $(word 1,$(subst ., ,$(VERSION)))

# OS-specific bits
#ifeq ($(shell uname),Darwin)
#	SOEXT = dylib
#	SOEXTVER_MAJOR = $(SONAME_MAJOR).$(SOEXT)
#	SOEXTVER = $(SONAME_MAJOR).$(SONAME_MINOR).$(SOEXT)
#	LINKSHARED = -dynamiclib -Wl,-install_name,$(LIBDIR)/lib$(LANGUAGE_NAME).$(SOEXTVER),-rpath,@executable_path/../Frameworks
#else
#	SOEXT = so
#	SOEXTVER_MAJOR = $(SOEXT).$(SONAME_MAJOR)
#	SOEXTVER = $(SOEXT).$(SONAME_MAJOR).$(SONAME_MINOR)
#	LINKSHARED = -shared -Wl,-soname,lib$(LANGUAGE_NAME).$(SOEXTVER)
#endif
#ifneq ($(filter $(shell uname),FreeBSD NetBSD DragonFly),)
#	PCLIBDIR := $(PREFIX)/libdata/pkgconfig
#endif

#all: lib$(LANGUAGE_NAME).a lib$(LANGUAGE_NAME).$(SOEXT) $(LANGUAGE_NAME).pc
#
#lib$(LANGUAGE_NAME).a: $(OBJS)
#	$(AR) $(ARFLAGS) $@ $^
#
#lib$(LANGUAGE_NAME).$(SOEXT): $(OBJS)
#	$(CC) $(LDFLAGS) $(LINKSHARED) $^ $(LDLIBS) -o $@
#ifneq ($(STRIP),)
#	$(STRIP) $@
#endif
#
#$(LANGUAGE_NAME).pc: bindings/c/$(LANGUAGE_NAME).pc.in
#	sed -e 's|@PROJECT_VERSION@|$(VERSION)|' \
#		-e 's|@CMAKE_INSTALL_LIBDIR@|$(LIBDIR:$(PREFIX)/%=%)|' \
#		-e 's|@CMAKE_INSTALL_INCLUDEDIR@|$(INCLUDEDIR:$(PREFIX)/%=%)|' \
#		-e 's|@PROJECT_DESCRIPTION@|$(DESCRIPTION)|' \
#		-e 's|@PROJECT_HOMEPAGE_URL@|$(HOMEPAGE_URL)|' \
#		-e 's|@CMAKE_INSTALL_PREFIX@|$(PREFIX)|' $< > $@
#
#$(PARSER): $(SRC_DIR)/grammar.json
#	$(TS) generate $^
#
#install: all
#	install -d '$(DESTDIR)$(DATADIR)'/tree-sitter/queries/mojo '$(DESTDIR)$(INCLUDEDIR)'/tree_sitter '$(DESTDIR)$(PCLIBDIR)' '$(DESTDIR)$(LIBDIR)'
#	install -m644 bindings/c/tree_sitter/$(LANGUAGE_NAME).h '$(DESTDIR)$(INCLUDEDIR)'/tree_sitter/$(LANGUAGE_NAME).h
#	install -m644 $(LANGUAGE_NAME).pc '$(DESTDIR)$(PCLIBDIR)'/$(LANGUAGE_NAME).pc
#	install -m644 lib$(LANGUAGE_NAME).a '$(DESTDIR)$(LIBDIR)'/lib$(LANGUAGE_NAME).a
#	install -m755 lib$(LANGUAGE_NAME).$(SOEXT) '$(DESTDIR)$(LIBDIR)'/lib$(LANGUAGE_NAME).$(SOEXTVER)
#	ln -sf lib$(LANGUAGE_NAME).$(SOEXTVER) '$(DESTDIR)$(LIBDIR)'/lib$(LANGUAGE_NAME).$(SOEXTVER_MAJOR)
#	ln -sf lib$(LANGUAGE_NAME).$(SOEXTVER_MAJOR) '$(DESTDIR)$(LIBDIR)'/lib$(LANGUAGE_NAME).$(SOEXT)
#	install -m644 queries/*.scm '$(DESTDIR)$(DATADIR)'/tree-sitter/queries/mojo
#
#uninstall:
#	$(RM) '$(DESTDIR)$(LIBDIR)'/lib$(LANGUAGE_NAME).a \
#		'$(DESTDIR)$(LIBDIR)'/lib$(LANGUAGE_NAME).$(SOEXTVER) \
#		'$(DESTDIR)$(LIBDIR)'/lib$(LANGUAGE_NAME).$(SOEXTVER_MAJOR) \
#		'$(DESTDIR)$(LIBDIR)'/lib$(LANGUAGE_NAME).$(SOEXT) \
#		'$(DESTDIR)$(INCLUDEDIR)'/tree_sitter/$(LANGUAGE_NAME).h \
#		'$(DESTDIR)$(PCLIBDIR)'/$(LANGUAGE_NAME).pc
#	$(RM) -r '$(DESTDIR)$(DATADIR)'/tree-sitter/queries/mojo
#
#clean:
#	$(RM) $(OBJS) $(LANGUAGE_NAME).pc lib$(LANGUAGE_NAME).a lib$(LANGUAGE_NAME).$(SOEXT)
#
#test:
#	$(TS) test
#
