// swift-tools-version:5.0

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
            dependencies: ["TSCUtility"]),
        .testTarget(
            name: "SnippetTests",
            dependencies: ["SnippetCore"])
    ]
)
