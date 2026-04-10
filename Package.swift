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
            url: "https://github.com/pocketradar/smartcoach-ios-sdk/releases/download/v0.1.0-beta.5/SmartCoachSDK.xcframework.zip",
            checksum: "c1478b2e4495b1218d733906e2510f05a821476519535e7ba8049ab6670e5420"
        ),
        
        // Documentation-only target
        .target(
            name: "SmartCoachSDKDocumentation",
            path: "Sources/SmartCoachSDK"
        ),
    ]
)
