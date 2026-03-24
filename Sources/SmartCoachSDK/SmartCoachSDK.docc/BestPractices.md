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

Always cancel measurement tasks when done:

```swift
@MainActor
class MeasurementManager: ObservableObject {
    private var measurementTask: Task<Void, Never>?
    
    func startMeasuring() async {
        let stream = try? await SmartCoach.startMeasuring()
        
        measurementTask = Task {
            guard let stream else { return }
            for await measurement in stream {
                processMeasurement(measurement)
            }
        }
    }
    
    func stopMeasuring() async {
        measurementTask?.cancel()
        measurementTask = nil
        try? await SmartCoach.stopMeasuring()
    }
    
    deinit {
        measurementTask?.cancel()
    }
}
```

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
        case .scanning, .connecting:
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
        state == .connected
    }
    
    private var canStopMeasuring: Bool {
        state == .measuring
    }
}
```

## Performance

### Use Async/Await Properly

Leverage structured concurrency for clean, efficient code:

```swift
// ✅ Good - structured concurrency
func setupConnection() async throws {
    try await SmartCoach.startScanning()
    try await SmartCoach.stopScanning()
    try await SmartCoach.connect(to: device)
}

// ❌ Bad - callback hell
func setupConnection(completion: @escaping (Error?) -> Void) {
    SmartCoach.startScanning { error in
        guard error == nil else { completion(error); return }
        SmartCoach.stopScanning { error in
            guard error == nil else { completion(error); return }
            // ...
        }
    }
}
```

### Cancel Unused Tasks

Clean up tasks that are no longer needed:

```swift
class ViewModel: ObservableObject {
    private var observationTask: Task<Void, Never>?
    
    func startObserving() {
        observationTask = Task {
            // ... observation code
        }
    }
    
    func stopObserving() {
        observationTask?.cancel()
        observationTask = nil
    }
    
    deinit {
        observationTask?.cancel()
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
