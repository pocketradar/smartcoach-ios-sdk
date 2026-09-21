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
            url: "https://github.com/pocketradar/smartcoach-ios-sdk/releases/download/v0.2.0-beta.1/SmartCoachSDK.xcframework.zip",
            checksum: "09397e0edb13b63cfa27c68197e0475337d6a4a49d95a564e0ac40d674aa0cfe"
        ),
        
        // Documentation-only target
        .target(
            name: "SmartCoachSDKDocumentation",
            path: "Sources/SmartCoachSDK"
        ),
    ]
)
