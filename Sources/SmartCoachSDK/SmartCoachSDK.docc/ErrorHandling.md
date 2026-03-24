# Error Handling

Learn how to handle errors gracefully in your SmartCoach-enabled application.

## Overview

SmartCoachSDK uses a comprehensive error system based on ``SmartCoachError`` and ``SmartCoachErrorCode``. Every error includes a specific error code, domain, and localized description to help you provide great user experiences.

## Error Structure

All SDK errors are instances of ``SmartCoachError``, which contains:

- **`code`**: A ``SmartCoachErrorCode`` enum value
- **`domain`**: The error domain string
- **`localizedDescription`**: A user-friendly error message

## Error Categories

Errors are organized into logical categories:

### Configuration Errors (1000–1999)

Errors that occur during SDK initialization.

```swift
do {
    try SmartCoach.configure()
} catch let error as SmartCoachError {
    switch error {
    case SmartCoachError.alreadyConfigured:
        // SDK was already configured
        print("Already configured - safe to ignore")
        
    case SmartCoachError.notConfigured:
        // Attempted to use SDK before configuration
        print("Must call configure() first")
        
    case SmartCoachError.missingApiKey:
        // API key missing from Info.plist
        print("Add SmartCoachAPIKey to Info.plist")
        
    case SmartCoachError.invalidBundleId:
        // Bundle ID issue
        print("Check bundle identifier")
        
    case SmartCoachError.invalidConfiguration:
        // General configuration problem
        print("Verify Info.plist entries")
        
    default:
        print("Configuration error: \(error.localizedDescription)")
    }
}
```

### Entitlement Errors (3000–3999)

Errors related to feature permissions and subscriptions.

```swift
do {
    let stream = try await SmartCoach.startMeasuring()
    // Process stream...
} catch let error as SmartCoachError {
    switch error {
    case SmartCoachError.featureNotAvailable:
        // Feature not included in subscription
        showUpgradePrompt()
        
    case SmartCoachError.invalidEntitlements:
        // Entitlements expired or invalid
        // May need network to refresh
        await refreshEntitlements()
        
    default:
        print("Error: \(error.localizedDescription)")
    }
}
```

### Device Errors (4000–4999)

Errors related to Bluetooth connectivity and device communication.

```swift
do {
    try await SmartCoach.startScanning()
} catch let error as SmartCoachError {
    switch error {
    case SmartCoachError.bluetoothNotAvailable:
        // Bluetooth is off or unavailable
        showBluetoothAlert()
        
    case SmartCoachError.failedToConnect:
        // Connection attempt failed
        print("Please try again")
        
    case SmartCoachError.noDeviceConnected:
        // No device is connected
        print("Please connect a device first")
        
    case SmartCoachError.unexpectedDisconnect:
        // Lost connection unexpectedly
        attemptReconnect()
        
    case SmartCoachError.featureNotSupported:
        // Device doesn't support this feature
        print("This device doesn't support that")
        
    case SmartCoachError.failedToStartScanning:
        // Scanning failed to start
        print("Couldn't start scanning")
        
    case SmartCoachError.failedToStartMeasuring:
        // Measurement failed to start
        print("Couldn't start measuring")
        
    default:
        print("Device error: \(error.localizedDescription)")
    }
}
```

## Pattern Matching with Error Matchers

SmartCoachSDK provides ``SmartCoachErrorMatcher`` for clean pattern matching when access to the actual error is not needed:

```swift
do {
    try await SmartCoach.connect(to: device)
} catch SmartCoachError.bluetoothNotAvailable {
    print("Please enable Bluetooth")
} catch SmartCoachError.failedToConnect {
    print("Connection failed - retry?")
} catch SmartCoachError.notConfigured {
    print("SDK not configured")
} catch {
    print("Unexpected error: \(error)")
}
```

## Complete Error Reference

| Code | Error | Category | Description |
|------|-------|----------|-------------|
| 1001 | `alreadyConfigured` | Configuration | SDK already configured |
| 1002 | `notConfigured` | Configuration | SDK not configured yet |
| 1003 | `missingApiKey` | Configuration | API key not in Info.plist |
| 1004 | `invalidBundleId` | Configuration | Bundle ID invalid |
| 1005 | `invalidConfiguration` | Configuration | Configuration issue |
| 3001 | `featureNotAvailable` | Entitlements | Feature not in plan |
| 3002 | `invalidEntitlements` | Entitlements | Entitlements expired |
| 4001 | `bluetoothNotAvailable` | Device | Bluetooth unavailable |
| 4002 | `failedToConnect` | Device | Connection failed |
| 4003 | `noDeviceConnected` | Device | No device connected |
| 4004 | `unexpectedDisconnect` | Device | Lost connection |
| 4005 | `featureNotSupported` | Device | Feature not supported |
| 4006 | `failedToStartScanning` | Device | Scanning failed |
| 4007 | `failedToStartMeasuring` | Device | Measuring failed |
| -9999 | `unknownInternalError` | Internal | Unknown error |

## Best Practices

### 1. Always Handle Errors

Every SDK method that can throw should be wrapped in appropriate error handling:

```swift
// ✅ Good
do {
    try await SmartCoach.startScanning()
} catch {
    handleError(error)
}

// ❌ Bad - unhandled errors
try! await SmartCoach.startScanning() // Don't do this!
```

### 2. Provide User-Friendly Messages

Use the error's `localizedDescription` or customize messages:

```swift
func showError(_ error: Error) {
    let message: String
    
    if let scError = error as? SmartCoachError {
        switch scError {
        case SmartCoachError.bluetoothNotAvailable:
            message = "Please turn on Bluetooth in Settings to connect to your device."
        case SmartCoachError.featureNotAvailable:
            message = "This feature requires a premium subscription."
        default:
            message = scError.localizedDescription
        }
    } else {
        message = "An unexpected error occurred."
    }
    
    showAlert(message)
}
```

### 3. Log Errors for Debugging

Include error codes and domains in your logs:

```swift
catch let error as SmartCoachError {
    print("SmartCoach Error [\(error.code.rawValue)]: \(error.localizedDescription)")
    print("Domain: \(error.domain)")
    
    // Send to analytics/crash reporting
    Analytics.logError(error)

    // Get internal SDK Debug information
    print(error.debugDescription)

    // Get SDK version information
    print(SmartCoach.getVersion())
}
```

### 4. Handle Recoverable Errors

Some errors can be recovered from automatically:

```swift
func connectToDevice() async {
    do {
        try await SmartCoach.connect(to: selectedDevice)
    } catch SmartCoachError.bluetoothNotAvailable {
        // Wait for Bluetooth to become available
        await waitForBluetooth()
        try? await connectToDevice() // Retry
    } catch SmartCoachError.failedToConnect {
        // Retry connection
        retryCount += 1
        if retryCount < maxRetries {
            try? await Task.sleep(for: .seconds(2))
            await connectToDevice()
        }
    } catch {
        showError(error)
    }
}
```

## Example: Comprehensive Error Handling

```swift
@MainActor
class DeviceManager: ObservableObject {
    @Published var errorMessage: String?
    @Published var isShowingError = false
    
    func setupAndConnect() async {
        do {
            // Configure SDK
            try SmartCoach.configure()
            
            // Start state monitoring
            let stream = try await SmartCoach.startScanning(connectToLastPairedDevice: true)

            await processStateChanges(stream)
            
        } catch let error as SmartCoachError {
            handleSmartCoachError(error)
        } catch {
            handleUnexpectedError(error)
        }
    }
    
    private func handleSmartCoachError(_ error: SmartCoachError) {
        switch error {
        // Configuration
        case SmartCoachError.notConfigured:
            errorMessage = "App is not properly configured. Please contact support."
            
        case SmartCoachError.missingApiKey:
            errorMessage = "Configuration error. Please reinstall the app."
            
        // Bluetooth
        case SmartCoachError.bluetoothNotAvailable:
            errorMessage = "Please enable Bluetooth to connect to your device."
            
        case SmartCoachError.failedToConnect:
            errorMessage = "Couldn't connect to device. Please try again."
            
        case SmartCoachError.unexpectedDisconnect:
            errorMessage = "Lost connection to device. Reconnecting..."
            Task { await attemptReconnect() }
            return // Don't show error for auto-reconnect
            
        // Entitlements
        case SmartCoachError.featureNotAvailable:
            errorMessage = "This feature requires a subscription upgrade."
            
        case SmartCoachError.invalidEntitlements:
            errorMessage = "Please check your internet connection and try again."
            
        default:
            errorMessage = error.localizedDescription
        }
        
        isShowingError = true
    }
    
    private func handleUnexpectedError(_ error: Error) {
        print("Unexpected error: \(error)")
        errorMessage = "An unexpected error occurred. Please try again."
        isShowingError = true
    }
    
    private func attemptReconnect() async {
        do {
            try await SmartCoach.startScanning(connectToLastPairedDevice: true)
        } catch {
            handleSmartCoachError(error as! SmartCoachError)
        }
    }
}
```

## See Also

- ``SmartCoachError``
- ``SmartCoachErrorCode``
- ``SmartCoachErrorMatcher``
- <doc:CommonErrors>
