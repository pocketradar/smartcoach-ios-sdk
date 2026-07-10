# Best Practices

A collection of recommended patterns and practices for building robust applications with SmartCoachSDK.

## Overview

Follow these best practices to create reliable, efficient, and user-friendly applications that integrate SmartCoach devices.

## Configuration

### Configure Once at Launch

Always configure the SDK once during app initialization:

```swift
// ✅ Good
@main
struct MyApp: App {
    init() {
        try? SmartCoach.configure()
    }
    
    var body: some Scene {
        WindowGroup { ContentView() }
    }
}

// ❌ Bad - configuring multiple times
func someFunction() {
    try? SmartCoach.configure() // Don't do this!
}
```

### Handle Configuration Errors Gracefully

```swift
init() {
    do {
        try SmartCoach.configure()
    } catch SmartCoachError.alreadyConfigured {
        // Safe to ignore
    } catch SmartCoachError.missingApiKey {
        fatalError("Missing API key in Info.plist")
    } catch {
        print("Configuration error: \(error)")
    }
}
```

## Connection Management

### Use Auto-Connect for Returning Users

Provide a seamless experience for returning users:

```swift
func connectOnLaunch() async {
    let hasConnectedBefore = UserDefaults.standard.bool(forKey: "hasConnectedBefore")

    // Scanning is only valid while disconnected — it throws
    // SmartCoachError.invalidSessionState if a device is already
    // connected or connecting.
    guard SmartCoach.currentSessionState().rootState == .disconnected else { return }

    if hasConnectedBefore {
        do {
            try await SmartCoach.startScanning(connectToLastPairedDevice: true)
        } catch {
            // Fall back to manual selection
            showDeviceSelection()
        }
    } else {
        showDeviceSelection()
    }
}
```

### Wait for `.connected` Before Measuring

Starting a scan or calling ``SmartCoach/connect(to:)`` begins connecting, but the
device is only ready once the session state reaches `.connected` — the encryption
handshake finishes asynchronously. Calling ``SmartCoach/startMeasuring()`` earlier
throws `SmartCoachError.invalidSessionState`. Drive your flow from the state stream:

```swift
for await state in try await SmartCoach.sessionStateStream() {
    if case .connected = state {
        let stream = try await SmartCoach.startMeasuring()
        // consume measurements...
    }
}
```

### Disconnect Cleanly

``SmartCoach/disconnect()`` never throws — call it with `await`, not `try`. If
anything goes wrong during disconnect, the error arrives on the session state
stream as `.disconnected(error)`:

```swift
await SmartCoach.disconnect()
// Observe .disconnected(let error) on sessionStateStream() for the outcome.
```

### Handle Unexpected Disconnections

Enable autoReconnect at configure time:

```swift
let options = SmartCoachDeviceConfigurationOptions(autoReconnect: true)

do {
    try SmartCoach.configure(deviceConfigurationOptions: options)
} catch {
    print("Configuration failed: \(error)")
}
```

## Measurement Handling

### Clean Up Streams Properly

The measurement stream completes on its own when you call
``SmartCoach/stopMeasuring()``, call ``SmartCoach/disconnect()``, or the connection
drops — the `for await` loop ends. Keep the task handle so state changes can end an
in-flight loop early, and capture `self` weakly so the task can't keep your object
alive:

```swift
@MainActor
class MeasurementManager: ObservableObject {
    private var measurementTask: Task<Void, Never>?

    func startMeasuring() {
        // Measuring requires the session to be .connected; otherwise
        // startMeasuring() throws SmartCoachError.invalidSessionState.
        guard SmartCoach.currentSessionState().rootState == .connected else { return }
        measurementTask = Task { [weak self] in
            do {
                for await measurement in try await SmartCoach.startMeasuring() {
                    self?.processMeasurement(measurement)
                }
                // Loop ended: measuring stopped or the device disconnected.
            } catch {
                self?.handleError(error)
            }
        }
    }

    func stopMeasuring() async {
        measurementTask?.cancel()
        measurementTask = nil
        try? await SmartCoach.stopMeasuring() // safe no-op if not measuring
    }
}
```

> Important: Do not cancel tasks in `deinit`. On a `@MainActor` type, `deinit` is
> nonisolated and cannot reference main-actor-isolated properties — it will not
> compile. Cancel in an explicit teardown method (or a view's `.onDisappear`)
> instead; the `[weak self]` capture ensures the task never keeps the object alive.

## Error Handling

### Always Handle Errors

Never use `try!` or ignore errors in production code:

```swift
// ✅ Good
do {
    try await SmartCoach.startScanning()
} catch {
    handleError(error)
}

// ❌ Bad
try! await SmartCoach.startScanning() // Crashes on error
```

### Provide User-Friendly Error Messages

Translate technical errors into actionable messages:

```swift
func userFriendlyMessage(for error: Error) -> String {
    guard let scError = error as? SmartCoachError else {
        return "An unexpected error occurred."
    }
    
    switch scError {
    case SmartCoachError.bluetoothNotAvailable:
        return "Please enable Bluetooth in Settings to connect to your device."
    case SmartCoachError.noDeviceConnected:
        return "Please connect to a SmartCoach device first."
    case SmartCoachError.invalidSessionState:
        return "That action isn't available right now. Disconnect from the current device first."
    case SmartCoachError.featureNotAvailable:
        return "This feature requires a subscription upgrade."
    default:
        return scError.localizedDescription
    }
}
```

## User Experience

### Show Clear Status Indicators

Keep users informed of what's happening:

```swift
struct StatusView: View {
    let state: SmartCoachSessionState
    
    var body: some View {
        HStack {
            statusIcon
            Text(statusText)
                .font(.subheadline)
        }
    }
    
    private var statusIcon: some View {
        switch state {
        case .disconnected:
            return Image(systemName: "circle").foregroundColor(.gray)
        case .scanning, .connecting, .reconnecting:
            return ProgressView()
        case .connected:
            return Image(systemName: "checkmark.circle.fill").foregroundColor(.green)
        case .measuring:
            return Image(systemName: "waveform.circle.fill").foregroundColor(.blue)
        }
    }
    
    private var statusText: String {
        switch state {
        case .disconnected: return "Disconnected"
        case .scanning: return "Scanning..."
        case .connecting: return "Connecting..."
        case .connected: return "Connected"
        case .measuring: return "Measuring"
        case .reconnecting: return "Reconnecting..."
        }
    }
}
```

### Provide Visual Feedback for Long Operations

Show progress for operations that take time:

```swift
struct ConnectionView: View {
    @State private var isConnecting = false
    
    var body: some View {
        VStack {
            if isConnecting {
                VStack(spacing: 12) {
                    ProgressView()
                    Text("Connecting to device...")
                        .font(.caption)
                }
            } else {
                Button("Connect") {
                    connectToDevice()
                }
            }
        }
    }
    
    func connectToDevice() {
        isConnecting = true
        
        Task {
            defer { isConnecting = false }
            
            do {
                try await SmartCoach.startScanning(connectToLastPairedDevice: true)
            } catch {
                showError(error)
            }
        }
    }
}
```

### Enable/Disable Controls Based on State

Prevent invalid actions by disabling unavailable controls:

```swift
struct MeasurementControls: View {
    let state: SmartCoachSessionState
    
    var body: some View {
        VStack {
            Button("Start Measuring") {
                startMeasuring()
            }
            .disabled(!canStartMeasuring)
            
            Button("Stop Measuring") {
                stopMeasuring()
            }
            .disabled(!canStopMeasuring)
        }
    }
    
    private var canStartMeasuring: Bool {
        state.rootState == .connected
    }
    
    private var canStopMeasuring: Bool {
        state.rootState == .measuring
    }
}
```

## Performance

### Use Async/Await Properly

Leverage structured concurrency for clean, efficient code:

```swift
// ✅ Good - drive the flow from the session state stream
func setupConnection() async throws {
    try await SmartCoach.startScanning()

    for await state in try await SmartCoach.sessionStateStream() {
        switch state {
        case let .scanning(devices):
            // Pick a device (e.g. present the list; here: strongest signal)
            if let device = devices.first {
                try await SmartCoach.connect(to: device)
            }
        case .connected:
            // The device is ready only now — connect(to:) returning is not enough,
            // because the encryption handshake completes asynchronously.
            return
        case let .disconnected(error?):
            throw error
        default:
            break
        }
    }
}

// ❌ Bad - assuming connect(to:) returning means the device is ready
func setupConnection() async throws {
    try await SmartCoach.startScanning()
    try await SmartCoach.connect(to: device)
    _ = try await SmartCoach.startMeasuring() // throws invalidSessionState —
                                              // the session isn't .connected yet
}
```

### Cancel Unused Tasks

The session state stream from ``SmartCoach/sessionStateStream()`` never ends on its
own, so a task observing it must be cancelled explicitly. The simplest approach is
structured concurrency — drive the observation from a SwiftUI `.task` modifier, which
cancels automatically when the view disappears:

```swift
.task { await viewModel.startMonitoring() } // cancelled on disappear — no cleanup code
```

If you store the task yourself, cancel it in an explicit teardown method — never in
`deinit` (on a `@MainActor` type, `deinit` is nonisolated and cannot reference the
isolated property; it will not compile):

```swift
@MainActor
class ViewModel: ObservableObject {
    private var observationTask: Task<Void, Never>?
    
    func startObserving() {
        observationTask = Task { [weak self] in
            // ... observe sessionStateStream() ...
        }
    }
    
    func stopObserving() { // call from .onDisappear or your teardown path
        observationTask?.cancel()
        observationTask = nil
    }
}
```

<!--## Testing-->
<!---->
<!--### Make Your Code Testable-->
<!---->
<!--Design for testability by using protocols:-->
<!---->
<!--```swift-->
<!--protocol SmartCoachServiceProtocol {-->
<!--    func startScanning() async throws-->
<!--    func connect(to device: SmartCoachRadar) async throws-->
<!--    func startMeasuring() async throws -> AsyncStream<MeasurementData>-->
<!--}-->
<!---->
<!--// Production implementation uses SmartCoach directly-->
<!--class SmartCoachService: SmartCoachServiceProtocol {-->
<!--    func startScanning() async throws {-->
<!--        try await SmartCoach.startScanning()-->
<!--    }-->
<!--    // ...-->
<!--}-->
<!---->
<!--// Mock for testing-->
<!--class MockSmartCoachService: SmartCoachServiceProtocol {-->
<!--    var shouldFailScanning = false-->
<!--    -->
<!--    func startScanning() async throws {-->
<!--        if shouldFailScanning {-->
<!--            throw SmartCoachError(code: .failedToStartScanning, domain: "test", underlyingError: /* ... */)-->
<!--        }-->
<!--    }-->
<!--    // ...-->
<!--}-->
<!--```-->
<!---->
<!--### Test Error Paths-->
<!---->
<!--Always test how your app handles errors:-->
<!---->
<!--```swift-->
<!--func testConnectionFailure() async {-->
<!--    let mockService = MockSmartCoachService()-->
<!--    mockService.shouldFailConnection = true-->
<!--    -->
<!--    let viewModel = DeviceViewModel(service: mockService)-->
<!--    -->
<!--    await viewModel.connect()-->
<!--    -->
<!--    XCTAssertFalse(viewModel.isConnected)-->
<!--    XCTAssertNotNil(viewModel.errorMessage)-->
<!--}-->
<!--```-->

## Security

### Protect API Keys

Never hardcode API keys in your source code:

```swift
// ✅ Good - API key in Info.plist
// The SDK reads from Info.plist automatically

// ❌ Bad - hardcoded key
let apiKey = "sk_live_abc123..." // Don't do this!
```

### Validate User Permissions

Check Bluetooth permissions before attempting operations:

```swift
import CoreBluetooth

func checkPermissions() {
    let manager = CBCentralManager()
    
    switch manager.authorization {
    case .allowedAlways:
        proceedWithConnection()
    case .denied, .restricted:
        showPermissionDeniedAlert()
    case .notDetermined:
        // Will be prompted automatically
        break
    @unknown default:
        break
    }
}
```

## See Also

- <doc:GettingStarted>
- <doc:ErrorHandling>
- <doc:SessionStateManagement>
- <doc:DeviceDiscovery>
