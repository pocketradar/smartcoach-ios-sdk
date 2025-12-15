# Scanning

Scanning is the entry point for discovering SmartCoach radar devices. When scanning
begins, the SDK automatically updates session state and publishes device
discoveries through the `SmartCoachSessionState` stream. Applications should
observe session state to render UI and respond to scanning events.

Scanning requires that the SDK has already been successfully configured.
See <doc:Configuration> for details.

---

## Starting and Stopping Scanning

The public API exposes two methods:

```swift
public static func startScanning(autoConnect: Bool = false) async throws
public static func stopScanning() async throws
```

### Starting Scanning

```swift
try await SmartCoach.startScanning()
```

When scanning begins:

- Bluetooth scanning is activated  
- Session state transitions to:  

```swift
.scanning([SmartCoachRadar])
```

The array may be empty at first and updates as devices are discovered.

### AutoConnect Behavior

The `autoConnect` parameter enables automatic reconnection to the *previously connected device*.

```swift
try await SmartCoach.startScanning(autoConnect: true)
```

#### What AutoConnect **does not** do

- ❌ It does **not** connect to the first discovered device  
- ❌ It does **not** connect to all devices in range  
- ❌ It does **not** auto‑connect without a prior manual connection  

#### What AutoConnect **actually** does

1. When the user manually connects to a radar:
```swift
try await SmartCoach.connect(to: radar)
```
2. The SDK stores that radar’s unique identifier (e.g., MAC address)
3. On a later scan:
```swift
try await SmartCoach.startScanning(autoConnect: true)
```
4. If the same radar is discovered during scanning, the SDK automatically attempts to reconnect
5. Session state transitions:
```
.scanning([...])
→ .connecting(radar)
→ .connected(radar)
```

#### When AutoConnect Does Nothing

- The previously connected radar is not detected  
- Bluetooth permissions are denied  
- Scanning entitlements disallow scanning  

In these cases, scanning proceeds normally.

#### Best Use Cases

- Training sessions using the same SmartCoach radar  
- “Open app → reconnect → measure” experiences  
- Hands‑free reconnection  

---

### Stopping Scanning

```swift
try await SmartCoach.stopScanning()
```

Stopping scanning ends BLE discovery and typically triggers a session state
transition back to:

```swift
.disconnected(nil)
```

---

## Observing Session State During Scanning

Scanning behavior is communicated through `SmartCoachSessionState`, which updates
as devices appear, connections are attempted, or scanning ends.

### Available States

```swift
public enum SmartCoachSessionState: Sendable {
    case disconnected(Error?)
    case scanning([any SmartCoachRadar])
    case connecting(any SmartCoachRadar)
    case connected(any SmartCoachRadar)
    case measuring(any SmartCoachRadar)
}
```

### 1. `sessionStateStream()` — Required for Scanning UI

This async stream emits a new value whenever the scanning state changes:

```swift
Task {
    do {
        for await state in try await SmartCoach.sessionStateStream() {
            switch state {
            case .scanning(let devices):
                print("Discovered devices:", devices)

            case .connecting(let radar):
                print("Connecting to:", radar.name)

            case .connected(let radar):
                print("Connected to:", radar.name)

            case .disconnected(let error):
                print("Disconnected:", error?.localizedDescription ?? "<none>")

            default:
                reak
            }
        }
    } catch {
        print("Session stream error:", error)
    }
}
```

#### Calling Before Configuration (Error)

If `sessionStateStream()` is called before `SmartCoach.configure()`,
the SDK throws:

```swift
SmartCoachError.configuratiaonError(.notConfigured)
```

### 2. `currentSessionState()` — Immediate Snapshot

Use this to fetch the most recent state without async:

```swift
let state = SmartCoach.currentSessionState()
```

Before configuration, it returns:

```swift
.disconnected(ConfigurationError.notConfigured)
```

---

## Typical Scanning Flow (SwiftUI)

### Step 1: Observe session state

```swift
@State private var devices: [SmartCoachRadar] = []

Task {
    for await state in try await SmartCoach.sessionStateStream() {
        if case .scanning(let found) = state {
            devices = found
        }
    }   
}
```

### Step 2: Start Scanning

```swift
Button("Scan") {
    Task {
        try? await SmartCoach.startScanning()
    }
}
```

### Step 3: Display Devices

```swift
List(devices, id: \.id) { radar in
    Text(radar.name)
}
```

---

## Error Handling During Scanning

Because scanning depends on Bluetooth and device availability, errors may occur.

Common examples:

### Bluetooth Powered Off

Session typically transitions to:

```swift
.disconnected(BluetoothError.unavailable)
```

### Configuration Missing

```swift
SmartCoachError.configuratiaonError(.notConfigured)
```

Your UI should respond gracefully to `.disconnected(Error?)` and allow the user
to retry scanning.

---

## Summary

After reviewing this section, you should understand:

1. How to start and stop scanning  
2. How session state communicates scanning progress  
3. The difference between `sessionStateStream()` and `currentSessionState()`  
4. Auto-connect scanning behavior  
5. Error handling during scanning  

Proceed to <doc:Connection> to learn how to manage device connections.

