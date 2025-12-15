# Measuring Speeds

Once a SmartCoach radar is connected, you may begin receiving real-time speed measurements through an asynchronous stream. Streaming is actor-safe, event-driven, and automatically terminates on disconnect or error.

---

## Prerequisites

Before starting measurement, you must:

1. **Configure the SDK:**

```swift
try SmartCoach.configure()
```

2. **Start scanning:**

```swift
try await SmartCoach.startScanning()
```

3. **Observe discovered radars and display them in your UI:**

```swift
for await state in try await SmartCoach.sessionStateStream() {
    if case let .scanning(radars) = state {
        // Update UI with list of radars (e.g., SwiftUI List or UIKit TableView)
    }
}
```

4. **Connect when the user taps/selects a radar:**

```swift
func userSelectedRadar(_ radar: SmartCoachRadar) async {
    do {
        try await SmartCoach.connect(to: radar)
    } catch {
        print("Failed to connect:", error)
    }
}
```

Once the connection succeeds, you may begin measuring.

---

## Starting Measurement Streaming

```swift
let stream = try await SmartCoach.startMeasuring()

for await measurement in stream {
    print("Speed:", measurement.measurement.value)
}
```

This triggers a session state transition:

```
.connected(radar)
→ .measuring(radar)
```

The `AsyncStream<MeasurementData>` continues until:

- The radar disconnects  
- A Bluetooth error occurs  
- You call `stopMeasuring()`  
- The consumer task is cancelled  

---

## `MeasurementData` Format

```swift
public struct MeasurementData: Equatable, Sendable {
    public let measurement: Measurement<UnitSpeed>
    public let macAddress: String?
}
```

- `measurement.value`: The numeric speed  
- `measurement.unit`: `.milesPerHour` or `.kilometersPerHour`  
- `macAddress`: The radar’s MAC address (reserved for multi-device expansion)  

Example:

```swift
let value = measurement.measurement.value       // Double
let unit = measurement.measurement.unit         // UnitSpeed.milesPerHour
```

---

## Stopping Measurement Streaming

To stop streaming:

```swift
try await SmartCoach.stopMeasuring()
```

The stream completes naturally, and session state returns to:

```
.connected(radar)
```

---

## Error Conditions

### Not Configured

```swift
SmartCoachError.configuratiaonError(.notConfigured)
```

Occurs if measurement begins before configuration.

### No Active Connection

If measurement is started without an active connection:

```swift
RadarError.invalidSessionState
```

### Bluetooth Errors

Failures from CoreBluetooth propagate as:

```swift
SmartCoachError.apiError(BluetoothError.*)
```

These errors automatically terminate the stream.

---

## Observing Measurement State via `sessionStateStream()`

While measurement is active, the session state is:

```
.measuring(radar)
```

Example:

```swift
for await state in try await SmartCoach.sessionStateStream() {
    if case .measuring(let radar) = state {
        print("Measuring on: \(radar.id)")
    }
}
```

---

## Summary

You now understand:

- How to begin and stop speed measurement  
- How to consume measurement values asynchronously  
- Interaction with user-selected radar connections  
- How streams terminate  
- Expected error behaviors  
- How session state reflects measurement activity  

Proceed to <doc:PublicAPI> for complete API reference details.
