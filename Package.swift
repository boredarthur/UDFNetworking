// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "UDFNetworking",
    platforms: [
        .iOS(.v15),
        .macOS(.v12)
    ],
    products: [
        .library(
            name: "UDFNetworking",
            targets: ["UDFNetworking"]
        ),
    ],
    targets: [
        .target(
            name: "UDFNetworking"
        ),
        .testTarget(
            name: "UDFNetworkingTests",
            dependencies: ["UDFNetworking"]
        ),

    ]
)
