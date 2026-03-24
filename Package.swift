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
            url: "https://github.com/your-org/SmartCoachSDK/releases/download/0.1.0-beta.3/SmartCoachSDK.xcframework.zip",
            checksum: "paste-your-checksum-here"
        ),
        
        // Documentation-only target
        .target(
            name: "SmartCoachSDKDocumentation",
            path: "Sources/SmartCoachSDK",
            sources: []
        ),
    ]
)
