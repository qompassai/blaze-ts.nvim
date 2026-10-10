// -------------------------------------------------------------------------
// /qompassai/blaze-ts.nvim/src/scanner.c
// Qompass AI External scanner for the Mojo tree-sitter grammar
// SPDX-License-Identifier: Apache-2.0
// Copyright (c) 2026 Qompass AI
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
// The scan logic is adapted from the tree-sitter-python external scanner
// (Copyright (c) 2014 Max Brunsfeld, MIT License), whose grammar this
// grammar's external-token contract mirrors. Adaptations: token indices
// follow this grammar's `externals` order exactly, scanner state lives in
// fixed-size arrays with named caps (no dynamic allocation after create),
// and serialization is bounds-checked against
// TREE_SITTER_SERIALIZATION_BUFFER_SIZE on every write.
// -------------------------------------------------------------------------

#include "tree_sitter/parser.h"

#include <stdbool.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>

// Token indices MUST match the order of `externals` in src/grammar.js:
//   _newline, _indent, _dedent, string_start, _string_content,
//   escape_interpolation, string_end, comment, "]", ")", "}", "except"
enum TokenType {
    NEWLINE,
    INDENT,
    DEDENT,
    STRING_START,
    STRING_CONTENT,
    ESCAPE_INTERPOLATION,
    STRING_END,
    COMMENT,
    CLOSE_BRACKET,
    CLOSE_PAREN,
    CLOSE_BRACE,
    EXCEPT,
};

// Bounded scanner state. Indentation deeper than INDENT_STACK_MAX levels
// or strings nested deeper than DELIMITER_STACK_MAX levels stop producing
// the corresponding external tokens (the parser then reports an error)
// instead of growing state without bound.
enum {
    INDENT_STACK_MAX = 128,
    DELIMITER_STACK_MAX = 32,
};

typedef enum {
    SingleQuote = 1 << 0,
    DoubleQuote = 1 << 1,
    BackQuote = 1 << 2,
    Raw = 1 << 3,
    Format = 1 << 4,
    Triple = 1 << 5,
    Bytes = 1 << 6,
} Flags;

typedef struct {
    char flags;
} Delimiter;

static inline Delimiter new_delimiter(void) { return (Delimiter){0}; }

static inline bool is_format(Delimiter *delimiter) { return (delimiter->flags & Format) != 0; }

static inline bool is_raw(Delimiter *delimiter) { return (delimiter->flags & Raw) != 0; }

static inline bool is_triple(Delimiter *delimiter) { return (delimiter->flags & Triple) != 0; }

static inline bool is_bytes(Delimiter *delimiter) { return (delimiter->flags & Bytes) != 0; }

static inline int32_t end_character(Delimiter *delimiter) {
    if (delimiter->flags & SingleQuote) {
        return '\'';
    }
    if (delimiter->flags & DoubleQuote) {
        return '"';
    }
    if (delimiter->flags & BackQuote) {
        return '`';
    }
    return 0;
}

static inline void set_format(Delimiter *delimiter) { delimiter->flags |= Format; }

static inline void set_raw(Delimiter *delimiter) { delimiter->flags |= Raw; }

static inline void set_triple(Delimiter *delimiter) { delimiter->flags |= Triple; }

static inline void set_bytes(Delimiter *delimiter) { delimiter->flags |= Bytes; }

static inline void set_end_character(Delimiter *delimiter, int32_t character) {
    switch (character) {
        case '\'':
            delimiter->flags |= SingleQuote;
            break;
        case '"':
            delimiter->flags |= DoubleQuote;
            break;
        case '`':
            delimiter->flags |= BackQuote;
            break;
        default:
            break;
    }
}

typedef struct {
    uint16_t indents[INDENT_STACK_MAX];
    uint8_t indent_count;
    Delimiter delimiters[DELIMITER_STACK_MAX];
    uint8_t delimiter_count;
    bool inside_interpolated_string;
} Scanner;

static inline bool push_indent(Scanner *scanner, uint16_t indent) {
    if (scanner->indent_count >= INDENT_STACK_MAX) {
        return false;
    }
    scanner->indents[scanner->indent_count++] = indent;
    return true;
}

static inline void pop_indent(Scanner *scanner) {
    if (scanner->indent_count > 1) {
        scanner->indent_count--;
    }
}

static inline uint16_t current_indent(Scanner *scanner) {
    return scanner->indents[scanner->indent_count - 1];
}

static inline bool push_delimiter(Scanner *scanner, Delimiter delimiter) {
    if (scanner->delimiter_count >= DELIMITER_STACK_MAX) {
        return false;
    }
    scanner->delimiters[scanner->delimiter_count++] = delimiter;
    return true;
}

static inline void pop_delimiter(Scanner *scanner) {
    if (scanner->delimiter_count > 0) {
        scanner->delimiter_count--;
    }
}

static inline Delimiter *top_delimiter(Scanner *scanner) {
    return &scanner->delimiters[scanner->delimiter_count - 1];
}

static inline void advance(TSLexer *lexer) { lexer->advance(lexer, false); }

static inline void skip(TSLexer *lexer) { lexer->advance(lexer, true); }

bool tree_sitter_mojo_external_scanner_scan(void *payload, TSLexer *lexer, const bool *valid_symbols) {
    Scanner *scanner = (Scanner *)payload;

    bool error_recovery_mode = valid_symbols[STRING_CONTENT] && valid_symbols[INDENT];
    bool within_brackets = valid_symbols[CLOSE_BRACE] || valid_symbols[CLOSE_PAREN] || valid_symbols[CLOSE_BRACKET];

    bool advanced_once = false;
    if (valid_symbols[ESCAPE_INTERPOLATION] && scanner->delimiter_count > 0 &&
        (lexer->lookahead == '{' || lexer->lookahead == '}') && !error_recovery_mode) {
        Delimiter *delimiter = top_delimiter(scanner);
        if (is_format(delimiter)) {
            lexer->mark_end(lexer);
            bool is_left_brace = lexer->lookahead == '{';
            advance(lexer);
            advanced_once = true;
            if ((lexer->lookahead == '{' && is_left_brace) || (lexer->lookahead == '}' && !is_left_brace)) {
                advance(lexer);
                lexer->mark_end(lexer);
                lexer->result_symbol = ESCAPE_INTERPOLATION;
                return true;
            }
            return false;
        }
    }

    if (valid_symbols[STRING_CONTENT] && scanner->delimiter_count > 0 && !error_recovery_mode) {
        Delimiter *delimiter = top_delimiter(scanner);
        int32_t end_char = end_character(delimiter);
        bool has_content = advanced_once;
        while (lexer->lookahead) {
            if ((advanced_once || lexer->lookahead == '{' || lexer->lookahead == '}') && is_format(delimiter)) {
                lexer->mark_end(lexer);
                lexer->result_symbol = STRING_CONTENT;
                return has_content;
            }
            if (lexer->lookahead == '\\') {
                if (is_raw(delimiter)) {
                    // Step over the backslash.
                    advance(lexer);
                    // Step over any escaped quotes.
                    if (lexer->lookahead == end_character(delimiter) || lexer->lookahead == '\\') {
                        advance(lexer);
                    }
                    // Step over newlines
                    if (lexer->lookahead == '\r') {
                        advance(lexer);
                        if (lexer->lookahead == '\n') {
                            advance(lexer);
                        }
                    } else if (lexer->lookahead == '\n') {
                        advance(lexer);
                    }
                    continue;
                }
                if (is_bytes(delimiter)) {
                    lexer->mark_end(lexer);
                    advance(lexer);
                    if (lexer->lookahead == 'N' || lexer->lookahead == 'u' || lexer->lookahead == 'U') {
                        // In bytes strings, \N{...}, \uXXXX and \UXXXXXXXX are
                        // not escape sequences.
                        advance(lexer);
                    } else {
                        lexer->result_symbol = STRING_CONTENT;
                        return has_content;
                    }
                } else {
                    lexer->mark_end(lexer);
                    lexer->result_symbol = STRING_CONTENT;
                    return has_content;
                }
            } else if (lexer->lookahead == end_char) {
                if (is_triple(delimiter)) {
                    lexer->mark_end(lexer);
                    advance(lexer);
                    if (lexer->lookahead == end_char) {
                        advance(lexer);
                        if (lexer->lookahead == end_char) {
                            if (has_content) {
                                lexer->result_symbol = STRING_CONTENT;
                            } else {
                                advance(lexer);
                                lexer->mark_end(lexer);
                                pop_delimiter(scanner);
                                lexer->result_symbol = STRING_END;
                                scanner->inside_interpolated_string = false;
                            }
                            return true;
                        }
                        lexer->mark_end(lexer);
                        lexer->result_symbol = STRING_CONTENT;
                        return true;
                    }
                    lexer->mark_end(lexer);
                    lexer->result_symbol = STRING_CONTENT;
                    return true;
                }
                if (has_content) {
                    lexer->result_symbol = STRING_CONTENT;
                } else {
                    advance(lexer);
                    pop_delimiter(scanner);
                    lexer->result_symbol = STRING_END;
                    scanner->inside_interpolated_string = false;
                }
                lexer->mark_end(lexer);
                return true;

            } else if (lexer->lookahead == '\n' && has_content && !is_triple(delimiter)) {
                return false;
            }
            advance(lexer);
            has_content = true;
        }
    }

    lexer->mark_end(lexer);

    bool found_end_of_line = false;
    uint16_t indent_length = 0;
    int32_t first_comment_indent_length = -1;
    for (;;) {
        if (lexer->lookahead == '\n') {
            found_end_of_line = true;
            indent_length = 0;
            skip(lexer);
        } else if (lexer->lookahead == ' ') {
            indent_length++;
            skip(lexer);
        } else if (lexer->lookahead == '\r' || lexer->lookahead == '\f') {
            indent_length = 0;
            skip(lexer);
        } else if (lexer->lookahead == '\t') {
            indent_length += 8;
            skip(lexer);
        } else if (lexer->lookahead == '#' && (valid_symbols[INDENT] || valid_symbols[DEDENT] ||
                                               valid_symbols[NEWLINE] || valid_symbols[EXCEPT])) {
            // If we haven't found an EOL yet,
            // then this is a comment after an expression:
            //   foo = bar # comment
            // Just return, since we don't want to generate an indent/dedent
            // token.
            if (!found_end_of_line) {
                return false;
            }
            if (first_comment_indent_length == -1) {
                first_comment_indent_length = (int32_t)indent_length;
            }
            while (lexer->lookahead && lexer->lookahead != '\n') {
                skip(lexer);
            }
            skip(lexer);
            indent_length = 0;
        } else if (lexer->lookahead == '\\') {
            skip(lexer);
            if (lexer->lookahead == '\r') {
                skip(lexer);
            }
            if (lexer->lookahead == '\n' || lexer->eof(lexer)) {
                skip(lexer);
            } else {
                return false;
            }
        } else if (lexer->eof(lexer)) {
            indent_length = 0;
            found_end_of_line = true;
            break;
        } else {
            break;
        }
    }

    if (found_end_of_line) {
        if (scanner->indent_count > 0) {
            uint16_t current_indent_length = current_indent(scanner);

            if (valid_symbols[INDENT] && indent_length > current_indent_length) {
                if (!push_indent(scanner, indent_length)) {
                    return false;
                }
                lexer->result_symbol = INDENT;
                return true;
            }

            bool next_tok_is_string_start =
                lexer->lookahead == '\"' || lexer->lookahead == '\'' || lexer->lookahead == '`';

            if ((valid_symbols[DEDENT] ||
                 (!valid_symbols[NEWLINE] && !(valid_symbols[STRING_START] && next_tok_is_string_start) &&
                  !within_brackets)) &&
                indent_length < current_indent_length && !scanner->inside_interpolated_string &&

                // Wait to create a dedent token until we've consumed any
                // comments
                // whose indentation matches the current block.
                first_comment_indent_length < (int32_t)current_indent_length) {
                pop_indent(scanner);
                lexer->result_symbol = DEDENT;
                return true;
            }
        }

        if (valid_symbols[NEWLINE] && !error_recovery_mode) {
            lexer->result_symbol = NEWLINE;
            return true;
        }
    }

    if (first_comment_indent_length == -1 && valid_symbols[STRING_START]) {
        Delimiter delimiter = new_delimiter();

        bool has_flags = false;
        while (lexer->lookahead) {
            if (lexer->lookahead == 'f' || lexer->lookahead == 'F' || lexer->lookahead == 't' ||
                lexer->lookahead == 'T') {
                set_format(&delimiter);
            } else if (lexer->lookahead == 'r' || lexer->lookahead == 'R') {
                set_raw(&delimiter);
            } else if (lexer->lookahead == 'b' || lexer->lookahead == 'B') {
                set_bytes(&delimiter);
            } else if (lexer->lookahead != 'u' && lexer->lookahead != 'U') {
                break;
            }
            has_flags = true;
            advance(lexer);
        }

        if (lexer->lookahead == '`') {
            set_end_character(&delimiter, '`');
            advance(lexer);
            lexer->mark_end(lexer);
        } else if (lexer->lookahead == '\'') {
            set_end_character(&delimiter, '\'');
            advance(lexer);
            lexer->mark_end(lexer);
            if (lexer->lookahead == '\'') {
                advance(lexer);
                if (lexer->lookahead == '\'') {
                    advance(lexer);
                    lexer->mark_end(lexer);
                    set_triple(&delimiter);
                }
            }
        } else if (lexer->lookahead == '\"') {
            set_end_character(&delimiter, '\"');
            advance(lexer);
            lexer->mark_end(lexer);
            if (lexer->lookahead == '\"') {
                advance(lexer);
                if (lexer->lookahead == '\"') {
                    advance(lexer);
                    lexer->mark_end(lexer);
                    set_triple(&delimiter);
                }
            }
        }

        if (end_character(&delimiter)) {
            if (!push_delimiter(scanner, delimiter)) {
                return false;
            }
            lexer->result_symbol = STRING_START;
            scanner->inside_interpolated_string = is_format(&delimiter);
            return true;
        }
        if (has_flags) {
            return false;
        }
    }

    return false;
}

unsigned tree_sitter_mojo_external_scanner_serialize(void *payload, char *buffer) {
    Scanner *scanner = (Scanner *)payload;

    size_t size = 0;
    size_t size_max = TREE_SITTER_SERIALIZATION_BUFFER_SIZE;

    buffer[size++] = (char)scanner->inside_interpolated_string;
    buffer[size++] = (char)scanner->delimiter_count;

    if (scanner->delimiter_count > 0) {
        memcpy(&buffer[size], scanner->delimiters, scanner->delimiter_count);
    }
    size += scanner->delimiter_count;

    uint32_t iter = 1;
    for (; iter < scanner->indent_count && size + 2 <= size_max; ++iter) {
        uint16_t indent_value = scanner->indents[iter];
        buffer[size++] = (char)(indent_value & 0xFF);
        buffer[size++] = (char)((indent_value >> 8) & 0xFF);
    }

    return (unsigned)size;
}

void tree_sitter_mojo_external_scanner_deserialize(void *payload, const char *buffer, unsigned length) {
    Scanner *scanner = (Scanner *)payload;

    scanner->delimiter_count = 0;
    scanner->indent_count = 1;
    scanner->indents[0] = 0;
    scanner->inside_interpolated_string = false;

    if (length > 0) {
        size_t size = 0;

        scanner->inside_interpolated_string = (bool)buffer[size++];

        if (size < length) {
            size_t delimiter_count = (uint8_t)buffer[size++];
            if (delimiter_count > DELIMITER_STACK_MAX) {
                delimiter_count = DELIMITER_STACK_MAX;
            }
            if (delimiter_count > length - size) {
                delimiter_count = length - size;
            }
            if (delimiter_count > 0) {
                memcpy(scanner->delimiters, &buffer[size], delimiter_count);
                scanner->delimiter_count = (uint8_t)delimiter_count;
                size += delimiter_count;
            }
        }

        for (; size + 1 < length && scanner->indent_count < INDENT_STACK_MAX; size += 2) {
            uint16_t indent_value = (unsigned char)buffer[size] | ((unsigned char)buffer[size + 1] << 8);
            scanner->indents[scanner->indent_count++] = indent_value;
        }
    }
}

void *tree_sitter_mojo_external_scanner_create(void) {
    Scanner *scanner = calloc(1, sizeof(Scanner));
    if (scanner == NULL) {
        return NULL;
    }
    tree_sitter_mojo_external_scanner_deserialize(scanner, NULL, 0);
    return scanner;
}

void tree_sitter_mojo_external_scanner_destroy(void *payload) {
    Scanner *scanner = (Scanner *)payload;
    free(scanner);
}
