# Pocket Radar SmartCoach iOS SDK

⚠️ **IMPORTANT**

This repository contains the **Pocket Radar SmartCoach Software Development Kit (SDK)** used to integrate Pocket Radar hardware into third-party iOS applications.

The SDK is **proprietary software owned by Pocket Radar, Inc.**

This SDK is **NOT open source**.

Access to this repository does **not grant permission to use the SDK**.

Use of the SDK requires:

- Approval from Pocket Radar
- Issuance of a valid **Pocket Radar API key**
- A **separate commercial or partner agreement**

Applications using the SDK will not function without a valid API key issued by Pocket Radar.

---

## Overview

The Pocket Radar SmartCoach SDK enables approved partners to integrate Pocket Radar hardware into their iOS applications. The SDK enables applications to discover, connect to, and stream measurement data from SmartCoach radar devices.

Typical integrations include:

- Sports performance platforms
- Training applications
- Analytics platforms
- Partner software products

> **This SDK is currently in beta.** APIs may change between releases. Please do not submit apps using the beta SDK to the App Store.

## Requirements

- Xcode 26.0 or later (the package manifest uses Swift tools 6.2)
- iOS 18.0 or later

## Installation

### Swift Package Manager

1. In Xcode, go to **File → Add Package Dependencies...**
2. Enter the repository URL:
```
https://github.com/pocketradar/smartcoach-ios-sdk
```
3. Select your desired version and click **Add Package**
4. Import the SDK in your Swift files:
```swift
import SmartCoachSDK
```

## Configuration

### API Key

Add your API key to your app's `Info.plist`:
```xml
<key>SmartCoachAPIKey</key>
<string>YOUR_API_KEY_HERE</string>
```

### Bluetooth Permissions

Add the required Bluetooth permission to your app's `Info.plist`:
```xml
<key>NSBluetoothAlwaysUsageDescription</key>
<string>This app needs Bluetooth to connect to SmartCoach devices</string>
```

## Quick Start

```swift
import SwiftUI
import SmartCoachSDK

@main
struct MyApp: App {
    init() {
        do {
            try SmartCoach.configure()
        } catch {
            print("Configuration failed: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

@MainActor
@Observable
class ScanningViewModel {
    var sessionState: SmartCoachSessionState = SmartCoach.currentSessionState()
    var availableDevices: [any SmartCoachRadar] = []
    var errorMessage: String?

    /// Observes SDK session state for the lifetime of the calling task.
    /// Drive this from the owning view's `.task` modifier — SwiftUI cancels the
    /// task automatically when the view disappears, so no manual teardown is needed.
    func startMonitoring() async {
        do {
            for await state in try await SmartCoach.sessionStateStream() {
                sessionState = state
                switch state {
                case let .scanning(devices):
                    availableDevices = devices
                case let .disconnected(error):
                    availableDevices.removeAll()
                    // Keep observing — errors arrive as data on the stream.
                    if let error {
                        errorMessage = error.localizedDescription
                    }
                default:
                    availableDevices.removeAll()
                }
            }
        } catch SmartCoachError.notConfigured {
            errorMessage = "Please configure the SDK"
        } catch {
            errorMessage = "An unexpected error occurred: \(error.localizedDescription)"
        }
    }

    func startScanning() {
        guard sessionState.rootState != .scanning else { return }
        Task {
            do {
                try await SmartCoach.startScanning()
            } catch {
                errorMessage = "Failed to start scan: \(error.localizedDescription)"
            }
        }
    }

    func stopScanning() {
        Task {
            do {
                try await SmartCoach.stopScanning()
            } catch {
                errorMessage = "Failed to stop scan: \(error.localizedDescription)"
            }
        }
    }
}

// In your view — one modifier drives the observation:
//
//     .task { await viewModel.startMonitoring() }
```

Devices are discovered, connected, and measured through the **session state stream** — SDK calls start work, and results arrive as states. See the bundled DocC tutorials for connecting and streaming measurements.

## Documentation

The SDK includes comprehensive DocC documentation bundled directly in the package. Once added to your project, documentation is available in Xcode's Documentation Browser.

**Build Documentation:** `⌃⇧⌘D` or **Product → Build Documentation**

**Browse Documentation:** `⌘⇧0` to open the Documentation Browser, then search for "SmartCoach"

**Quick Help:** Option-click any SmartCoach type or method for inline documentation

### What's Included

- Getting Started Guide
- Configuration Guide
- Step-by-Step Tutorials:
  - Connecting Your First Device
  - Streaming Measurement Data
- Core Guides: Device Discovery, Connection Management, Session State, Error Handling, and Best Practices
- Full API Reference

## Sample Project

A complete sample app demonstrating SDK integration is available in a separate repository:

**[SmartCoach iOS SDK Sample App](https://github.com/pocketradar/ios-smartcoach-sdk-sample)**

The sample app shows best practices for device discovery, connection management, and streaming measurement data.

## AI-Assisted Integration (Agent Skills)

This repository ships task-scoped recipes that let an AI coding assistant integrate
specific SDK capabilities into your app — "set up the SmartCoach SDK in this app,"
"add device scanning to this view model," "build a screen that connects and streams
speeds" — following the SDK's required call sequences instead of improvising them.

**Supported today: Claude (Claude Code).** The underlying recipes
([`agent-skills/recipes/`](agent-skills/recipes/)) are vendor-neutral markdown, so
other assistants (Codex, Gemini, Cursor) can use them directly — point your agent at
the relevant recipe file. Native packaging for those tools is planned.

### Install (Claude Code)

Clone this repository at the tag matching your SDK version and run the installer:

```bash
git clone --depth 1 --branch <release-tag> https://github.com/pocketradar/smartcoach-ios-sdk
cd smartcoach-ios-sdk/agent-skills
./install.sh                          # user-level: available in all your projects
# or:
./install.sh /path/to/your/app        # project-level: committed with one app
```

Then start a fresh Claude Code session in your project and ask naturally, e.g.
*"Set up the SmartCoach SDK in this app"* or *"Add SmartCoach device scanning to
DevicesViewModel."*

> The recipes are version-locked to SDK behavior — use the same release tag as the
> SDK version in your app, and re-run `install.sh` after updating the SDK.

See [`agent-skills/README.md`](agent-skills/README.md) for details.

## Feedback & Reporting Issues

Your feedback during the beta is invaluable — please use [GitHub Issues](https://github.com/pocketradar/smartcoach-ios-sdk/issues) to report bugs, share feedback on API design, or request features. When filing a bug, include:

- SDK version
- Xcode and iOS version
- Steps to reproduce
- Expected vs actual behavior
- Relevant logs or code snippets

For urgent support, contact [partners@pocketradar.com](mailto:partners@pocketradar.com).

## Partner Access

API keys are issued only to **approved Pocket Radar partners**.

If you are interested in integrating Pocket Radar technology into your application, please contact:

**partners@pocketradar.com**

Pocket Radar will work with partners to establish a commercial agreement defining:

- SDK usage rights
- Distribution rights
- Support
- Commercial terms

---

## License

Use of this SDK is governed by the license terms in the **LICENSE** file in this repository.
The SDK is proprietary software and is not distributed under an open source license.

See [LICENSE](LICENSE) for complete details.

