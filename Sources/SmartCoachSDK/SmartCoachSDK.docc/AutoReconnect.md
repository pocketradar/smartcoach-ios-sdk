# Auto-Reconnect

Learn how automatic reconnection maintains seamless connectivity with SmartCoach devices.

## Overview

Auto-reconnect automatically re-establishes connections when they're unexpectedly lost, providing a seamless experience for users during long sessions or when connectivity is intermittent.

## Built-In Auto-Reconnect

### Enabling Auto-Reconnect

Enable auto-reconnect during SDK configuration:

```swift
let options = SmartCoachDeviceConfigurationOptions(autoReconnect: true)

do {
    try SmartCoach.configure(deviceConfigurationOptions: options)
} catch {
    print("Configuration failed: \(error)")
}
```

### How It Works

When auto-reconnect is enabled and a connection is lost unexpectedly:

1. The SDK detects the connection loss (or Bluetooth becoming unavailable).
2. The session state stream emits `.reconnecting(device)` so your app can show status.
3. The SDK scans for the lost device and reconnects as soon as it's back in range — scanning continues until the device is found.
4. On success the session returns to `.connected(device)`; your app resumes from the state stream as usual.

> Important: Auto-reconnect applies only to **unexpected** disconnects. A
> user-initiated ``SmartCoach/disconnect()`` never triggers reconnection.

While the SDK is reconnecting, don't start a manual scan —
``SmartCoach/startScanning(timeout:connectToLastPairedDevice:)`` throws
``SmartCoachErrorCode/invalidSessionState`` when a connection attempt is already in
progress.

Note that a measurement in progress does not survive a reconnect: the measurement
stream completes when the connection drops, and the session returns to
`.connected` (not `.measuring`). Observe the transition back to `.connected` and
call ``SmartCoach/startMeasuring()`` again if you want measuring to resume.

### When to Use Built-In Auto-Reconnect

✅ **Use when:**
- Running long measurement sessions
- Operating in environments with potential interference
- Background operation is required
- User experience should be uninterrupted

❌ **Don't use when:**
- Users frequently switch between devices
- Short, isolated measurement sessions
- You need custom reconnection logic
- Battery life is critical

## Manual Reconnection

With auto-reconnect disabled, unexpected disconnects surface as
`.disconnected(error)` on the session state stream (the error describes why the
connection dropped). Reconnect by scanning again from the disconnected state:

```swift
for await state in try await SmartCoach.sessionStateStream() {
    if case let .disconnected(error) = state, error != nil {
        // Unexpected drop — reconnect to the last paired device
        try? await SmartCoach.startScanning(connectToLastPairedDevice: true)
    }
}
```

## See Also

- ``SmartCoachDeviceConfigurationOptions``
- ``SmartCoach/configure(deviceConfigurationOptions:)``
- <doc:SessionStateManagement>
- <doc:ConnectionManagement>
- <doc:DeviceDiscovery>
