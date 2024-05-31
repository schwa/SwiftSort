// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwiftSort",
    platforms: [
        .macOS(.v13)
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.2.0"),
        .package(url: "https://github.com/apple/swift-syntax.git", from: "510.0.2")
    ],
    targets: [
        .executableTarget(
            name: "SwiftSort",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                "Support"
            ]
        ),
        .target(
            name: "Support",
            dependencies: [
                .product(name: "SwiftParser", package: "swift-syntax"),
                .product(name: "SwiftSyntax", package: "swift-syntax")
            ]
        ),
        .testTarget(name: "SwiftSortTest", dependencies: ["Support"])
    ]
)
