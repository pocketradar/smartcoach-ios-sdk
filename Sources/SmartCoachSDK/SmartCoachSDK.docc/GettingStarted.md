# Getting Started

Learn how to integrate SmartCoachSDK into your iOS application and start receiving measurement data from SmartCoach devices.

## Overview

This guide walks you through the initial setup, from adding the SDK to your project through making your first connection to a Smart Coach device.

## Prerequisites

- iOS 18.0 or later
- Xcode 15.0 or later
- Swift 5.9 or later
- Bluetooth permissions configured in your app

## Installation

### 1. Add the Framework to Your Project

1. Drag the `SmartCoachSDK.xcframework` into your Xcode project
2. In your target's **General** settings, ensure the framework is listed under **Frameworks, Libraries, and Embedded Content**
3. Set the framework to **Embed & Sign**

### 2. Configure Info.plist

Add the required Bluetooth permissions to your `Info.plist`:

```xml
<key>NSBluetoothAlwaysUsageDescription</key>
<string>This app needs Bluetooth to connect to Smart Coach devices</string>

<key>SmartCoachAPIKey</key>
<string>YOUR_API_KEY_HERE</string>
```

Replace `YOUR_API_KEY_HERE` with your actual API key from the Smart Coach developer portal.

### 3. Import the SDK

In any Swift file where you want to use the SDK:

```swift
import SmartCoachSDK
```

## Quick Start

Here's a minimal example to get you started:

```swift
import SwiftUI
import SmartCoachSDK
@main
struct iOSSmartCoachSDKSampleApp: App {
    init() {
        do {
            try SmartCoach.configure()
        } catch {
            print("SmartCoach failed to configure: \(error)")
        }
    }
    var body: some Scene {
        WindowGroup {
            HomeView()
        }
    }
}
```

## Next Steps

Now that you have the basics working, explore these topics:

- <doc:Configuration> - Learn about advanced configuration options
- <doc:DeviceDiscovery> - Deep dive into device scanning and pairing
- <doc:ConnectingYourFirstDevice> - Step-by-step tutorial for device connection
- <doc:ErrorHandling> - Handle errors gracefully in your app

## Common Issues

### "SmartCoach SDK must be configured before making any requests"

Make sure you call `SmartCoach.configure()` before any other SDK methods, typically in your app's initialization code.

### "Missing API key"

Verify that your `Info.plist` contains a valid `SmartCoachAPIKey` entry.

### Bluetooth Not Available

Ensure you've added the required Bluetooth permission keys to your `Info.plist` and that the user has granted Bluetooth permissions to your app.

## See Also

- ``SmartCoach/configure(deviceConfigurationOptions:)``
- ``SmartCoachDeviceConfigurationOptions``
- <doc:Configuration>
