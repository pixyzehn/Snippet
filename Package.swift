// swift-tools-version:4.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Snippet",
    dependencies: [
        .package(url: "https://github.com/apple/swift-package-manager.git", .branch("master"))
    ],
    targets: [
        .target(
            name: "Snippet",
            dependencies: ["SnippetCore"]),
        .target(
            name: "SnippetCore",
            dependencies: ["SPMUtility"]),
        .testTarget(
            name: "SnippetTests",
            dependencies: ["SnippetCore"])
    ]
)
