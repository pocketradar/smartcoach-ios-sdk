// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SmartCoachSDK",
    platforms: [
        .iOS(.v18)
    ],
    products: [
        .library(
            name: "SmartCoachSDK",
            targets: ["SmartCoachSDK", "SmartCoachSDKDocumentation"]
        ),
    ],
    targets: [
        // Binary target - fetched from GitHub Release asset
        .binaryTarget(
            name: "SmartCoachSDK",
            url: "https://github.com/pocketradar/smartcoach-ios-sdk/releases/download/v0.1.0-beta.6/SmartCoachSDK.xcframework.zip",
            checksum: "7a940ac990dc5f48640ba0d5ba1209783be73861739526078f71fc8c20c7eae3"
        ),
        
        // Documentation-only target
        .target(
            name: "SmartCoachSDKDocumentation",
            path: "Sources/SmartCoachSDK"
        ),
    ]
)
