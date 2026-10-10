// -------------------------------------------------------------------------------
// /qompassai/blaze-ts.nvim/bindings/swift/TreeSitterMojoTests/TreeSitterMojoTests.swift
// Qompass AI Swift binding tests
// SPDX-License-Identifier: Apache-2.0
// Copyright (c) 2026 Qompass AI
//
// Licensed under the Apache License, Version 2.0 (the "License"); you may not
// use this file except in compliance with the License. You may obtain a copy
// of the License at http://www.apache.org/licenses/LICENSE-2.0
// -------------------------------------------------------------------------------

import XCTest
import SwiftTreeSitter
import TreeSitterMojo

final class TreeSitterMojoTests: XCTestCase {
    func testCanLoadGrammar() throws {
        let parser = Parser()
        let language = Language(language: tree_sitter_mojo())
        XCTAssertNoThrow(try parser.setLanguage(language),
                         "Error loading Mojo grammar")
    }
}
