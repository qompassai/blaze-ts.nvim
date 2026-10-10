// -------------------------------------------------------------------------------
// /qompassai/blaze-ts.nvim/bindings/swift/TreeSitterMojo/mojo.h
// Qompass AI Swift binding C header
// SPDX-License-Identifier: Apache-2.0
// Copyright (c) 2026 Qompass AI
//
// Licensed under the Apache License, Version 2.0 (the "License"); you may not
// use this file except in compliance with the License. You may obtain a copy
// of the License at http://www.apache.org/licenses/LICENSE-2.0
// -------------------------------------------------------------------------------

#ifndef TREE_SITTER_MOJO_H_
#define TREE_SITTER_MOJO_H_

typedef struct TSLanguage TSLanguage;

#ifdef __cplusplus
extern "C" {
#endif

const TSLanguage *tree_sitter_mojo(void);

#ifdef __cplusplus
}
#endif

#endif // TREE_SITTER_MOJO_H_
