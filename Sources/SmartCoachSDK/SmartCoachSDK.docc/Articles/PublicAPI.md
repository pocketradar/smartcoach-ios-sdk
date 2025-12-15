# SmartCoach SDK – Public API Reference

This page documents all **public API functions** exposed by the SmartCoach SDK.  
Each function includes:

- A description of what it does  
- Expected session state transitions  
- Errors it may throw  
- Links to relevant data types (e.g., `<doc:SmartCoachRadar>`, `<doc:MeasurementData>`)

---

# **1. Configuration**

## `configure()`

```swift
public static func configure() throws
```

Initializes the SmartCoach SDK.  
Must be called **once at app launch** before scanning, connecting, or measuring.

**Throws**

- `SmartCoachError.configuratiaonError(<doc:ConfigurationError>)`  
if configuration is missing or invalid.

**Notes**

- Must be invoked before any other SDK function  
- Subsequent calls throw `.alreadyConfigured`

---

# **2. Scanning**

## `startScanning(autoConnect:)`

```swift
public static func startScanning(autoConnect: Bool = false) async throws
```

Begins Bluetooth scanning for SmartCoach radar devices.

**Session State Transitions**

.disconnected → .scanning([<doc:SmartCoachRadar>])

If `autoConnect = true`, the SDK will automatically attempt to connect to discovered devices.

**Throws**

- `SmartCoachError.configuratiaonError(.notConfigured)` if called before `configure()`
- `SmartCoachError.apiError` or Bluetooth-related errors wrapped inside `SmartCoachError`

---

## `stopScanning()`

```swift
public static func stopScanning() async throws
```

Stops scanning.  
Typically transitions to:

```
.scanning → .disconnected(nil)
```

---

# **3. Connecting**

## `connect(to:)`

```swift
public static func connect(to radar: any SmartCoachRadar) async throws
```

Attempts to connect to a specific <doc:SmartCoachRadar> discovered during scanning.

**Session State Transitions**

```
.scanning → .connecting(radar) → .connected(radar)
```

**Throws**

- `SmartCoachError.apiError`
- `SmartCoachError.unknown`
- Bluetooth or radar-specific errors wrapped inside `SmartCoachError`

---

## `disconnect(from:)`

```swift
public static func disconnect(from radar: any SmartCoachRadar) async throws
```

Disconnects from the specified <doc:SmartCoachRadar> device.

**Session State Transitions**

```
.connected → .disconnected(nil)
```

**Throws**

- Connection management errors (e.g., `RadarError.deviceNotConnected`) wrapped inside `SmartCoachError`

---

# **4. Measuring**

## `startMeasuring()`

```swift
public static func startMeasuring() async throws -> AsyncStream<MeasurementData>
```

Starts radar measurement mode.

Returns an `AsyncStream` of <doc:MeasurementData> events representing individual speed readings.

**Session State Transitions**

```
.connected → .measuring(radar)
```

**Throws**

- `SmartCoachError.configuratiaonError(.notConfigured)`  
- Radar readiness or connection errors

---

## `stopMeasuring()`

```swift
public static func stopMeasuring() async throws
```

Stops active measurement.  
Session returns to:

```
.measuring → .connected
```

---

# **5. Session State Observation**

## `sessionStateStream()`

```swift
public static func sessionStateStream() async throws -> AsyncStream<SmartCoachSessionState>
```

Provides a real-time stream of <doc:SmartCoachSessionState> values representing all state transitions:

- Scanning results  
- Connection progress  
- Measurement state changes  
- Disconnection events  

**Important**

- Requires successful configuration  
- Throws `SmartCoachError.configuratiaonError(.notConfigured)` if called before `configure()`

---

## `currentSessionState()`

```swift
public static func currentSessionState() -> SmartCoachSessionState
```

Returns the current <doc:SmartCoachSessionState> **synchronously**.

**Before configuration**

Always returns:

```swift
.disconnected(ConfigurationError.notConfigured)
```

Useful for:

- Initial UI setup  
- Checking readiness  
- Avoiding async startup flows  

---

# **Summary**

This API surface allows apps to:

- Configure the SDK  
- Discover SmartCoach radar devices  
- Connect and disconnect  
- Receive measurement data  
- Track session state transitions  
- Handle all SDK-level errors  
(<doc:SmartCoachError>, <doc:ConfigurationError>, <doc:APIError>, etc.)

---
