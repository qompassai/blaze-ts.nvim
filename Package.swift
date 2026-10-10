// swift-tools-version:5.3
// -------------------------------------------------------------------------------
// /qompassai/blaze-ts.nvim/Package.swift
// Qompass AI Swift package manifest
// SPDX-License-Identifier: Apache-2.0
// Copyright (c) 2026 Qompass AI
//
// Licensed under the Apache License, Version 2.0 (the "License"); you may not
// use this file except in compliance with the License. You may obtain a copy
// of the License at http://www.apache.org/licenses/LICENSE-2.0
// -------------------------------------------------------------------------------


import Foundation
import PackageDescription

var sources = ["src/parser.c"]
if FileManager.default.fileExists(atPath: "src/scanner.c") {
    sources.append("src/scanner.c")
}

let package = Package(
    name: "TreeSitterMojo",
    products: [
        .library(name: "TreeSitterMojo", targets: ["TreeSitterMojo"]),
    ],
    dependencies: [
        .package(url: "https://github.com/tree-sitter/swift-tree-sitter", from: "0.8.0"),
    ],
    targets: [
        .target(
            name: "TreeSitterMojo",
            dependencies: [],
            path: ".",
            sources: sources,
            publicHeadersPath: "bindings/swift/TreeSitterMojo",
            cSettings: [.headerSearchPath("src")]
        ),
        .testTarget(
            name: "TreeSitterMojoTests",
            dependencies: [
                "SwiftTreeSitter",
                "TreeSitterMojo",
            ],
            path: "bindings/swift/TreeSitterMojoTests"
        )
    ],
    cLanguageStandard: .c11
)
