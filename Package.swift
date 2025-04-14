// swift-tools-version:5.3

import Foundation
import PackageDescription

var sources = ["src/parser.c"]
if FileManager.default.fileExists(atPath: "src/scanner.c") {
    sources.append("src/scanner.c")
}

let package = Package(
    name: "blaze-ts",
    products: [
        .library(name: "blaze-ts", targets: ["blaze-ts"]),
    ],
    dependencies: [
        .package(url: "https://github.com/tree-sitter/swift-tree-sitter", from: "0.8.0"),
    ],
    targets: [
        .target(
            name: "blaze-ts",
            dependencies: [],
            path: ".",
            sources: sources,
            resources: [
                .copy("queries")
            ],
            publicHeadersPath: "bindings/swift",
            cSettings: [.headerSearchPath("src")]
        ),
        .testTarget(
            name: "blaze-tsTests",
            dependencies: [
                "SwiftTreeSitter",
                "blaze-ts",
            ],
            path: "bindings/swift/blaze-tsTests"
        )
    ],
    cLanguageStandard: .c11
)
