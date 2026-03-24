# Configuration

Learn how to configure SmartCoachSDK with the right options for your application.

## Overview

The SDK must be configured once before use, typically during your app's launch sequence. Configuration sets up internal services, validates your API key, and prepares the SDK for device connections.

## Basic Configuration

The simplest way to configure the SDK uses default options:

```swift
import SmartCoachSDK

@main
struct MyApp: App {
    init() {
        do {
            try SmartCoach.configure()
        } catch {
            print("Failed to configure SmartCoach: \(error)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

## Configuration Options

For more control, provide a ``SmartCoachDeviceConfigurationOptions`` instance:

```swift
let options = SmartCoachDeviceConfigurationOptions(autoReconnect: true)

do {
    try SmartCoach.configure(deviceConfigurationOptions: options)
} catch {
    print("Configuration failed: \(error)")
}
```

### Auto-Reconnect

The `autoReconnect` option determines whether the SDK automatically attempts to reconnect to a previously paired device when the connection is lost:

- **`false` (default)**: The SDK will not automatically reconnect. You must manually call ``SmartCoach/startScanning(connectToLastPairedDevice:)`` to reconnect.
- **`true`**: The SDK attempts to reconnect automatically when a connection is unexpectedly lost.

**When to use auto-reconnect:**
- ✅ Long-duration measurement sessions where interruptions should be minimized
- ✅ Background operations where user intervention isn't possible

**When to disable auto-reconnect:**
- ✅ Short measurement sessions
- ✅ Apps where users frequently switch devices
- ✅ When you want full control over connection lifecycle

## Required Info.plist Configuration

The SDK requires specific keys in your `Info.plist`:

### 1. API Key (Required)

```xml
<key>SmartCoachAPIKey</key>
<string>YOUR_API_KEY_HERE</string>
```

Get your API key by contacting [Customer Support](mailto:info@pocketradar.com).

### 2. Bluetooth Permissions (Required)

```xml
<key>NSBluetoothAlwaysUsageDescription</key>
<string>We need Bluetooth to connect to your Smart Coach device</string>
```

Customize the description strings to explain to users why your app needs Bluetooth access.

### 3. Bundle Identifier

Ensure your app's bundle identifier matches the one registered with Pocket Radar

## Configuration Errors

The SDK can throw these configuration-related errors:

| Error | Description | Solution |
|-------|-------------|----------|
| ``SmartCoachErrorCode/alreadyConfigured`` | `configure()` was called more than once | Only call `configure()` once during app launch |
| ``SmartCoachErrorCode/notConfigured`` | SDK calls were made before configure() was called | Call configure at app launch |
| ``SmartCoachErrorCode/missingApiKey`` | API key not found in Info.plist | Add `SmartCoachAPIKey` to Info.plist |
| ``SmartCoachErrorCode/invalidBundleId`` | Bundle ID is missing or invalid | Check your app's bundle identifier |
| ``SmartCoachErrorCode/invalidConfiguration`` | General configuration issue | Verify all Info.plist entries are correct |

## Handling Configuration Errors

```swift
do {
    try SmartCoach.configure()
} catch SmartCoachError.missingApiKey {
    // Show alert to developer
    print("API key is missing from Info.plist")
} catch SmartCoachError.alreadyConfigured {
    // Safe to ignore if you're okay with single configuration
    print("SDK already configured")
} catch SmartCoachError.invalidBundleId {
    print("Bundle ID mismatch - check developer portal")
} catch {
    print("Configuration error: \(error.localizedDescription)")
}
```

## Best Practices

1. **Configure Early**: Call `configure()` in your app delegate or app struct's initializer
2. **Configure Once**: Only call `configure()` one time during app lifecycle
3. **Handle Errors**: Always wrap `configure()` in a do-catch block
4. **Validate Info.plist**: Double-check your Info.plist entries before releasing

## Example: Complete App Configuration

```swift
import SwiftUI
import SmartCoachSDK

@main
struct SmartCoachExampleApp: App {
    init() {
        configureSDK()
    }
    
    private func configureSDK() {
        let options = SmartCoachDeviceConfigurationOptions(
            autoReconnect: true
        )
        
        do {
            try SmartCoach.configure(deviceConfigurationOptions: options)
            print("✅ SmartCoach SDK configured successfully")
        } catch let error as SmartCoachError {
            handleConfigurationError(error)
        } catch {
            print("❌ Unexpected configuration error: \(error)")
        }
    }
    
    private func handleConfigurationError(_ error: SmartCoachError) {
        switch error {
        case SmartCoachError.missingApiKey:
            fatalError("Missing API key in Info.plist")
        case SmartCoachError.invalidBundleId:
            fatalError("Bundle ID mismatch")
        case SmartCoachError.alreadyConfigured:
            print("⚠️ SDK already configured")
        default:
            print("❌ Configuration failed: \(error.localizedDescription)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

## See Also

- ``SmartCoach/configure(deviceConfigurationOptions:)``
- ``SmartCoachDeviceConfigurationOptions``
- <doc:ErrorHandling>
- <doc:GettingStarted>
