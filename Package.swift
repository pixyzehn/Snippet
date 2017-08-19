// swift-tools-version:4.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Snippet",
    dependencies: [],
    targets: [
        .target(
            name: "Snippet",
            dependencies: ["SnippetCore"]),
        .target(
            name: "SnippetCore"),
        .testTarget(
            name: "SnippetTests",
            dependencies: ["SnippetCore"])
    ]
)
