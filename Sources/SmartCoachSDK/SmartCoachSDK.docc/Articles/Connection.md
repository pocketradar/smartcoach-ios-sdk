# Connection

Connecting to a SmartCoach radar device is an essential part of the SmartCoach iOS SDK workflow.  
Connections are fully asynchronous and state-driven, and must occur **after scanning** and **after successful configuration**.

---

## Prerequisites

Before attempting to connect:

1. The SDK must be configured:

```swift
try SmartCoach.configure()
```

2. Scanning must be started:

```swift
try await SmartCoach.startScanning()
```

3. Devices must be discovered using `sessionStateStream()`:

```swift
for await state in try await SmartCoach.sessionStateStream() {
    if case let .scanning(radars) = state {
        // Present radars to the user
    }
}
```

---

## Connecting to a Device

Once a `SmartCoachRadar` is selected from the `.scanning` state:

```swift
try await SmartCoach.connect(to: radar)
```

This produces the following session state transitions:

```
.scanning([...])
→ .connecting(radar)
→ .connected(radar)
```

These transitions can be observed via `sessionStateStream()`.

---

## Disconnecting

To disconnect from a device:

```swift
try await SmartCoach.disconnect(from: radar)
```

This drives the session state to:

```
.disconnected(nil)
```

If Bluetooth encounters an error, the state becomes:

```
.disconnected(Error?)
```

---

## Connection Error Behavior

### Not Configured
Calling `connect` or `disconnect` before configuration results in:

```
SmartCoachError.configuratiaonError(.notConfigured)
```

### Invalid Session State
If connection is attempted when not allowed:

```
RadarError.invalidSessionState
```

Common causes:
- Already connected to a device
- Connection already in progress
- Not scanning
- Active session does not match requested device

### Bluetooth Errors
Underlying CoreBluetooth errors appear as:

```
SmartCoachError.apiError(BluetoothError.*)
```

Including:
- `.connectionFailed`
- `.discoverServicesFailed`
- `.notificationFailure`

---

## Observing Connection State

### Using `sessionStateStream()`

Connection progress is represented by:

- `.connecting(radar)`
- `.connected(radar)`
- `.disconnected(error?)`

Example:

```swift
for await state in try await SmartCoach.sessionStateStream() {
    switch state {
    case .connecting(let radar):
        print("Connecting to \(radar.id)…")

    case .connected(let radar):
        print("Connected to \(radar.id)")

    case .disconnected(let error):
        print("Disconnected: \(error?.localizedDescription ?? "no error")")

    default:
        break
    }
}
```

---

## Using Current Session State

The synchronous helper:

```swift
let state = SmartCoach.currentSessionState()
```

If called before configuration, returns:

```
.disconnected(ConfigurationError.notConfigured)
```

Useful for:
- Initial UI state
- Readiness checks
- Avoiding early async subscriptions

---

## Summary

You should now understand:

- The complete connection workflow  
- How to initiate and observe connection state transitions  
- The disconnect process and error handling  
- Differences between `sessionStateStream()` and `currentSessionState()`  

Proceed to <doc:SpeedStreaming> to learn how to receive measurement data.
