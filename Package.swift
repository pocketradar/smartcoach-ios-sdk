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
            url: "https://github.com/pocketradar/smartcoach-ios-sdk/releases/download/v0.1.0-beta.3/SmartCoachSDK.xcframework.zip",
            checksum: "1e4ad848bf8bae8b9369d4064e0f71714a5150c15874e31324fcef05df4d05f3"
        ),
        
        // Documentation-only target
        .target(
            name: "SmartCoachSDKDocumentation",
            path: "Sources/SmartCoachSDK",
            sources: [],
            publicHeadersPath: "."
        ),
    ]
)
