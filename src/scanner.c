#include "tree_sitter/parser.h"
#include <string.h>
#include <stdbool.h>
#include <stdlib.h>

enum TokenType {
  INDENT,
  DEDENT,
  NEWLINE,
  STRING_CONTENT,
  ERROR_SENTINEL
};

typedef struct {
  uint32_t indent_length;
  bool inside_string;
  int32_t string_delimiter_length;
  uint32_t *indent_lengths;
  uint32_t indent_count;
  uint32_t indent_capacity;
} Scanner;

void *tree_sitter_mojo_external_scanner_create() {
  Scanner *scanner = calloc(1, sizeof(Scanner));
  scanner->indent_capacity = 10;
  scanner->indent_lengths = calloc(scanner->indent_capacity, sizeof(uint32_t));
  scanner->indent_count = 1;
  scanner->indent_lengths[0] = 0;
  return scanner;
}

void tree_sitter_mojo_external_scanner_destroy(void *payload) {
  Scanner *scanner = (Scanner *)payload;
  free(scanner->indent_lengths);
  free(scanner);
}

unsigned tree_sitter_mojo_external_scanner_serialize(void *payload, char *buffer) {
  Scanner *scanner = (Scanner *)payload;
  
  size_t i = 0;
  buffer[i++] = (char)scanner->indent_count;
  buffer[i++] = (char)scanner->inside_string;
  buffer[i++] = (char)scanner->string_delimiter_length;
  
  if (scanner->indent_count > 0) {
    for (size_t j = 0; j < scanner->indent_count && i < TREE_SITTER_SERIALIZATION_BUFFER_SIZE; j++) {
      buffer[i++] = (char)scanner->indent_lengths[j];
    }
  }
  
  return i;
}

void tree_sitter_mojo_external_scanner_deserialize(void *payload, const char *buffer, unsigned length) {
  if (length == 0) return;
  
  Scanner *scanner = (Scanner *)payload;
  
  size_t i = 0;
  scanner->indent_count = (uint32_t)buffer[i++];
  scanner->inside_string = (bool)buffer[i++];
  scanner->string_delimiter_length = (int32_t)buffer[i++];
  
  if (scanner->indent_count > scanner->indent_capacity) {
    scanner->indent_capacity = scanner->indent_count;
    free(scanner->indent_lengths);
    scanner->indent_lengths = calloc(scanner->indent_capacity, sizeof(uint32_t));
  }
  
  if (scanner->indent_count > 0) {
    for (size_t j = 0; j < scanner->indent_count && i < length; j++) {
      scanner->indent_lengths[j] = (uint32_t)buffer[i++];
    }
  }
}

bool tree_sitter_mojo_external_scanner_scan(void *payload, TSLexer *lexer, const bool *valid_symbols) {
  Scanner *scanner = (Scanner *)payload;
  
  if (scanner->inside_string) {
    return false;
  }
  
  if (valid_symbols[INDENT] || valid_symbols[DEDENT]) {
    bool at_line_start = lexer->get_column(lexer) == 0;
    if (at_line_start) {
      uint32_t indent_length = 0;
      for (;;) {
        if (lexer->lookahead == ' ') {
          indent_length++;
        } else if (lexer->lookahead == '\t') {
          indent_length += 8 - (indent_length % 8);
        } else {
          break;
        }
        lexer->advance(lexer, true);
      }
      
      if (lexer->lookahead == '\n' || lexer->lookahead == '\r' || lexer->lookahead == '#') {
        return false;
      }
      
      uint32_t current_indent_length = scanner->indent_lengths[scanner->indent_count - 1];
      
      if (indent_length > current_indent_length && valid_symbols[INDENT]) {
        if (scanner->indent_count >= scanner->indent_capacity) {
          scanner->indent_capacity *= 2;
          scanner->indent_lengths = realloc(scanner->indent_lengths, scanner->indent_capacity * sizeof(uint32_t));
        }
        scanner->indent_lengths[scanner->indent_count++] = indent_length;
        
        lexer->result_symbol = INDENT;
        return true;
      }
      
      if (indent_length < current_indent_length && valid_symbols[DEDENT]) {
        scanner->indent_count--;
        
        lexer->result_symbol = DEDENT;
        return true;
      }
    }
  }
  
  if (valid_symbols[NEWLINE]) {
    if (lexer->lookahead == '\n') {
      lexer->advance(lexer, true);
      lexer->result_symbol = NEWLINE;
      return true;
    }
  }
  
  return false;
}

