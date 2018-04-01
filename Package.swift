// swift-tools-version:4.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Snippet",
    dependencies: [
        .package(url: "https://github.com/apple/swift-package-manager.git", from: "0.2.0")
    ],
    targets: [
        .target(
            name: "Snippet",
            dependencies: ["SnippetCore"]),
        .target(
            name: "SnippetCore",
            dependencies: ["Utility"]),
        .testTarget(
            name: "SnippetTests",
            dependencies: ["SnippetCore"])
    ]
)
