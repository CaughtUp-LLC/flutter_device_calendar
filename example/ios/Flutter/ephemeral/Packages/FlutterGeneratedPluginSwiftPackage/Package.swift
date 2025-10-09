// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.
//
//  Generated file. Do not edit.
//

import PackageDescription

let package = Package(
    name: "FlutterGeneratedPluginSwiftPackage",
    platforms: [
        .iOS("12.0")
    ],
    products: [
        .library(name: "FlutterGeneratedPluginSwiftPackage", type: .static, targets: ["FlutterGeneratedPluginSwiftPackage"])
    ],
    dependencies: [
        .package(name: "flutter_timezone", path: "/Users/stephentan/.pub-cache/hosted/pub.dev/flutter_timezone-5.0.0/ios/flutter_timezone"),
        .package(name: "integration_test", path: "/Users/stephentan/Documents/Development/flutter/packages/integration_test/ios/integration_test")
    ],
    targets: [
        .target(
            name: "FlutterGeneratedPluginSwiftPackage",
            dependencies: [
                .product(name: "flutter-timezone", package: "flutter_timezone"),
                .product(name: "integration-test", package: "integration_test")
            ]
        )
    ]
)
