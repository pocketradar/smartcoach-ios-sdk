# Common Errors

Quick reference guide for troubleshooting common SmartCoachSDK errors.

## Overview

This guide helps you quickly diagnose and resolve the most frequently encountered errors when using SmartCoachSDK.

## Configuration Errors

### "SDK must be configured before making any requests"

**Error Code**: `1002` (``SmartCoachErrorCode/notConfigured``)

**Cause**: Attempting to use SDK methods before calling `configure()`.

**Solution**:
```swift
// Call configure() once at app launch
@main
struct MyApp: App {
    init() {
        try? SmartCoach.configure()
    }
}
```

---

### "Missing API key"

**Error Code**: `1003` (``SmartCoachErrorCode/missingApiKey``)

**Cause**: No `SmartCoachAPIKey` entry in Info.plist.

**Solution**: Add your API key to Info.plist:
```xml
<key>SmartCoachAPIKey</key>
<string>YOUR_API_KEY_HERE</string>
```

---

### "SDK can only be configured once"

**Error Code**: `1001` (``SmartCoachErrorCode/alreadyConfigured``)

**Cause**: Calling `configure()` multiple times.

**Solution**: This is usually safe to ignore, but ensure you only call `configure()` once:
```swift
// ✅ Good - call once
init() {
    do {
        try SmartCoach.configure()
    } catch SmartCoachError.alreadyConfigured {
        // Safe to ignore
    }
}
```

---

### "Invalid bundle ID"

**Error Code**: `1004` (``SmartCoachErrorCode/invalidBundleId``)

**Cause**: Your app's bundle identifier doesn't match what's registered in the SmartCoach developer portal.

**Solution**: 
1. Check your bundle identifier in Xcode (Target → General → Bundle Identifier)
2. Verify it matches the one registered at [developer.smartcoach.com](https://developer.smartcoach.com)
3. Update either your Xcode project or developer portal registration

## Connection Errors

### "Bluetooth is not available"

**Error Code**: `4001` (``SmartCoachErrorCode/bluetoothNotAvailable``)

**Cause**: Bluetooth is disabled, not authorized, or not supported on the device.

**Solutions**:
1. **Check if Bluetooth is enabled**:
```swift
import CoreBluetooth

let manager = CBCentralManager()
if manager.state != .poweredOn {
    // Show alert to enable Bluetooth
}
```

2. **Verify Info.plist permissions**:
```xml
<key>NSBluetoothAlwaysUsageDescription</key>
<string>We need Bluetooth to connect to your device</string>
```

3. **Check authorization**:
```swift
if manager.authorization == .denied {
    // Direct user to Settings
}
```

---

### "Failed to connect to device"

**Error Code**: `4002` (``SmartCoachErrorCode/failedToConnect``)

**Cause**: Connection attempt failed - device may be out of range, already connected elsewhere, or powered off.

**Solutions**:
1. **Implement retry logic**:
```swift
func connectWithRetry() async {
    var attempts = 0
    while attempts < 3 {
        do {
            try await SmartCoach.connect(to: device)
            return
        } catch SmartCoachError.failedToConnect {
            attempts += 1
            try? await Task.sleep(for: .seconds(2))
        }
    }
}
```

2. **Check device is powered on and in range**
3. **Ensure device isn't connected to another app/device**
4. **Try restarting Bluetooth on the phone**

---

### "No device connected"

**Error Code**: `4003` (``SmartCoachErrorCode/noDeviceConnected``)

**Cause**: An operation required a connected device and none was available.

> Note: Calling ``SmartCoach/startMeasuring()`` while not connected throws
> ``SmartCoachErrorCode/invalidSessionState`` (4008) — see that entry below.

**Solution**:
```swift
// Check connection state before measuring
let state = SmartCoach.currentSessionState()

if state.rootState == .connected {
    try await SmartCoach.startMeasuring()
} else {
    // Connect first
    try await SmartCoach.startScanning(connectToLastPairedDevice: true)
}
```

---

### "Unexpectedly lost connection"

**Error Code**: `4004` (``SmartCoachErrorCode/unexpectedDisconnect``)

**Cause**: Device disconnected unexpectedly - may be due to distance, battery, or interference.

**Solution**: Enable auto-reconnect in configuration — the SDK then handles
unexpected disconnects itself and surfaces `.reconnecting(device)` on the state
stream while it works:

```swift
let options = SmartCoachDeviceConfigurationOptions(autoReconnect: true)
try SmartCoach.configure(deviceConfigurationOptions: options)
```

If auto-reconnect is disabled and you reconnect manually, only do it from a
disconnected state (note `.disconnected` carries an optional error describing why
the connection dropped):

```swift
for await state in sessionStateStream {
    if case let .disconnected(error) = state, error != nil {
        // Unexpected drop — attempt to reconnect
        try? await Task.sleep(for: .seconds(2))
        try? await SmartCoach.startScanning(connectToLastPairedDevice: true)
    }
}
```

> Important: Do not also scan manually while auto-reconnect is enabled — the SDK
> is already reconnecting, and ``SmartCoach/startScanning(timeout:connectToLastPairedDevice:)``
> throws ``SmartCoachErrorCode/invalidSessionState`` when a connection attempt is
> in progress.

---

### "Failed to start scanning"

**Error Code**: `4006` (``SmartCoachErrorCode/failedToStartScanning``)

**Cause**: Bluetooth scanning couldn't start - usually temporary.

**Solution**: Retry after a short delay:
```swift
do {
    try await SmartCoach.startScanning()
} catch SmartCoachError.failedToStartScanning {
    try? await Task.sleep(for: .seconds(1))
    try? await SmartCoach.startScanning() // Retry
}
```

---

### "Invalid session state"

**Error Code**: `4008` (``SmartCoachErrorCode/invalidSessionState``)

**Cause**: The operation isn't valid for the current session state. Typical
triggers:
- Calling ``SmartCoach/startScanning(timeout:connectToLastPairedDevice:)`` or
  ``SmartCoach/connect(to:)`` while a device is already connected or connecting.
- Calling ``SmartCoach/startMeasuring()`` before the session has reached
  `.connected` (for example, right after `connect(to:)` returns — the encryption
  handshake finishes asynchronously).

**Solution**: Check the state first, and drive readiness from the state stream:
```swift
// Scanning again? Disconnect first.
if SmartCoach.currentSessionState().rootState != .disconnected {
    await SmartCoach.disconnect()
}
try await SmartCoach.startScanning()

// Measuring? Wait for .connected on the state stream.
for await state in try await SmartCoach.sessionStateStream() {
    if case .connected = state {
        let stream = try await SmartCoach.startMeasuring()
        // ...
    }
}
```

### "The radar rejected the command or did not acknowledge it"

**Error Code**: `4009` (``SmartCoachErrorCode/commandFailed``)

**Cause**: A settings call — ``SmartCoach/setMeasurementUnit(_:)``,
``SmartCoach/setSpeedRange(_:)``, or ``SmartCoach/setSensitivity(_:)`` — was rejected by
the radar or not acknowledged within a few seconds.

**Solution**: The connection is unaffected. Retry once; if it persists, check the radar
is awake and in range. Validate values with the failable initializers
(``RadarSpeedRange/init(lowMPH:highMPH:)``, ``RadarSensitivity/init(level:)``) so an
out-of-range value never reaches the radar:

```swift
guard let range = RadarSpeedRange(lowMPH: 40, highMPH: 100) else { return }
do {
    try await SmartCoach.setSpeedRange(range)
} catch SmartCoachError.commandFailed {
    showRetryPrompt()
}
```

## Entitlement Errors

### "Feature not available"

**Error Code**: `3001` (``SmartCoachErrorCode/featureNotAvailable``)

**Cause**: Attempting to use a feature not included in your subscription plan.

**Solution**: Upgrade your subscription or disable the feature in your app:
```swift
do {
    try await SmartCoach.startMeasuring()
} catch SmartCoachError.featureNotAvailable {
    showUpgradePrompt()
}
```

---

### "Invalid entitlements"

**Error Code**: `3002` (``SmartCoachErrorCode/invalidEntitlements``)

**Cause**: Entitlements expired or couldn't be validated (usually requires network).

**Solutions**:
1. **Check internet connection**
2. **Wait and retry** (may be temporary server issue)
3. **Verify subscription is active** in developer portal

```swift
do {
    try await SmartCoach.startMeasuring()
} catch SmartCoachError.invalidEntitlements {
    // Show message about connectivity
    showAlert("Please check your internet connection and try again")
}
```

## Measurement Errors

### "Failed to start measuring"

**Error Code**: `4007` (``SmartCoachErrorCode/failedToStartMeasuring``)

**Cause**: Measurement couldn't start — the device may not support the feature, or
sending the start command failed. (Calling it in the wrong session state throws
``SmartCoachErrorCode/invalidSessionState`` instead — see that entry.)

**Solutions**:
1. **Verify device is connected**:
```swift
let state = SmartCoach.currentSessionState()
guard state.rootState == .connected else {
    print("Must be connected to measure")
    return
}
```

2. **Check device supports measurement**
3. **Try reconnecting the device**

---

### "Feature not supported"

**Error Code**: `4005` (``SmartCoachErrorCode/featureNotSupported``)

**Cause**: The connected device doesn't support the requested feature.

**Solution**: Check device capabilities before attempting operation:
```swift
// Provide alternative UI for unsupported features
if deviceSupportsAdvancedMeasurements {
    showAdvancedMeasurementUI()
} else {
    showBasicMeasurementUI()
}
```

## Debugging Tips

### Enable Detailed Logging

Log errors with full context:
```swift
catch let error as SmartCoachError {
    print("SmartCoach Error:")
    print("  Code: \(error.code.rawValue)")
    print("  Domain: \(error.domain)")
    print("  Message: \(error.localizedDescription)")
}
```

### Check Current State

Always check current state when debugging:
```swift
let state = SmartCoach.currentSessionState()
print("Current state: \(state)")
```

### Monitor State Changes

Observe state transitions to understand flow:
```swift
let stream = try await SmartCoach.sessionStateStream()
for await state in stream {
    print("State changed to: \(state)")
}
```

### Verify Configuration

Ensure all required Info.plist entries are present:
- `SmartCoachAPIKey`
- `NSBluetoothAlwaysUsageDescription`
- Correct Bundle Identifier

## Getting Help

If you continue to experience issues:

1. **Check the error code** - Each error has a specific code for easy reference
2. **Review documentation** - See <doc:ErrorHandling> for comprehensive error handling
3. **Enable logging** - Log full error details for debugging
4. **Contact support** - Include error code, domain, and steps to reproduce

## See Also

- ``SmartCoachError``
- ``SmartCoachErrorCode``
- <doc:ErrorHandling>
- <doc:DeviceDiscovery>
- <doc:Configuration>
