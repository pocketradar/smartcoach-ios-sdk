# Session State Management

Learn how to monitor and react to SmartCoach SDK session state changes.

## Overview

The SmartCoach SDK maintains a session state that tracks the current status of device connection and measurement activity. Your app can observe these state changes to update UI, handle disconnections, and provide better user feedback.

## Session States

The SDK uses ``SmartCoachSessionState`` to represent different stages of operation:

| State | Description |
|-------|-------------|
| `disconnected` | No device is connected |
| `scanning` | Actively scanning for devices |
| `connecting` | Attempting to connect to a device |
| `connected` | Device is connected and ready |
| `measuring` | Actively receiving measurement data |

## Observing State Changes

### Using AsyncStream

The primary way to observe state changes is through an AsyncStream:

```swift
@MainActor
@Observable
class SessionStateViewModel {
    var currentState: SmartCoachSessionState = SmartCoach.currentSessionState()
    var errorMessage: String?
    private var sessionStateTask: Task<Void, Never>?
    
    init() {
        monitorSessionState()
    }
    
    // Available in Swift 6.2
    // Otherwise start startScanningObservations needs to be async and called from the view.task
    isolated deinit {
        sessionStateTask?.cancel()
        sessionStateTask = nil
    }
    
    private func monitorSessionState() {
        sessionStateTask = Task { @MainActor in
            do {
                for await state in try await SmartCoach.sessionStateStream() {
                    try Task.checkCancellation()
                    currentState = state
                    handleStateChange(state)
                }
            } catch SmartCoachError.notConfigured {
                errorMessage = "Please configure the SDK"
            } catch {
                errorMessage = "An unexpected error occurred: \(error.localizedDescription)"
                print(error.localizedDescription)
            }
        }
    }
    
    private func handleStateChange(_ state: SmartCoachSessionState) {
        switch state {
        case .disconnected:
            print("Device disconnected")
            
        case .scanning:
            print("Scanning for devices...")
            
        case .connecting:
            print("Connecting to device...")
            
        case .reconnecting:
            print("Reconnecting to device...")
            
        case .connected:
            print("Device connected and ready")
            
        case .measuring:
            print("Receiving measurements")
        @unknown default:
            print("unknown state")
        }
    }
}
```

### Getting Current State

You can also query the current state synchronously:

```swift
let currentState = SmartCoach.currentSessionState()

switch currentState {
case .connected:
    print("Device is connected")
case .measuring:
    print("Currently measuring")
default:
    print("Not connected")
}
```

## Practical Examples

### UI State Management

Update your UI based on session state:

```swift
struct DeviceStatusView: View {
    @StateObject private var viewModel = SessionStateViewModel()
    
    var body: some View {
        VStack(spacing: 16) {
            stateIndicator
            stateDescription
            actionButton
        }
        .task {
            // if you cannot support Swift 6.2 start observing here
            await viewModel.observeSessionState()
        }
    }
    
    @ViewBuilder
    private var stateIndicator: some View {
        switch viewModel.currentState {
        case .disconnected:
            Image(systemName: "circle")
                .foregroundColor(.gray)
        case .scanning, .connecting:
            ProgressView()
        case .connected:
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
        case .measuring:
            Image(systemName: "waveform")
                .foregroundColor(.blue)
        }
    }
    
    private var stateDescription: Text {
        switch viewModel.currentState {
        case .disconnected:
            return Text("Not connected")
        case .scanning:
            return Text("Scanning for devices...")
        case .connecting:
            return Text("Connecting...")
        case .connected:
            return Text("Connected")
        case .measuring:
            return Text("Measuring")
        }
    }
    
    @ViewBuilder
    private var actionButton: some View {
        switch viewModel.currentState {
        case .disconnected:
            Button("Connect") {
                Task {
                    try? await SmartCoach.startScanning(connectToLastPairedDevice: true)
                }
            }
        case .connected:
            Button("Start Measuring") {
                Task {
                    _ = try? await SmartCoach.startMeasuring()
                }
            }
        case .measuring:
            Button("Stop") {
                Task {
                    try? await SmartCoach.stopMeasuring()
                }
            }
        default:
            EmptyView()
        }
    }
}
```

<!--### Automatic Reconnection-->
<!---->
<!--Implement auto-reconnect logic based on state changes:-->
<!---->
<!--```swift-->
<!--class AutoReconnectManager: ObservableObject {-->
<!--    private var reconnectAttempts = 0-->
<!--    private let maxReconnectAttempts = 3-->
<!--    -->
<!--    func startMonitoring() async {-->
<!--        let stateStream = try? await SmartCoach.sessionStateStream()-->
<!--        -->
<!--        guard let stream = stateStream else { return }-->
<!--        -->
<!--        for await state in stream {-->
<!--            if case .disconnected = state {-->
<!--                await handleDisconnection()-->
<!--            }-->
<!--        }-->
<!--    }-->
<!--    -->
<!--    private func handleDisconnection() async {-->
<!--        guard reconnectAttempts < maxReconnectAttempts else {-->
<!--            print("Max reconnect attempts reached")-->
<!--            return-->
<!--        }-->
<!--        -->
<!--        reconnectAttempts += 1-->
<!--        print("Attempting reconnect (\(reconnectAttempts)/\(maxReconnectAttempts))...")-->
<!--        -->
<!--        try? await Task.sleep(for: .seconds(2))-->
<!--        -->
<!--        do {-->
<!--            try await SmartCoach.startScanning(connectToLastPairedDevice: true)-->
<!--            reconnectAttempts = 0 // Reset on successful reconnect-->
<!--        } catch {-->
<!--            print("Reconnect failed: \(error)")-->
<!--        }-->
<!--    }-->
<!--}-->
<!--```-->
<!---->
<!--### Session Recording-->
<!---->
<!--Track session duration and events:-->
<!---->
<!--```swift-->
<!--@MainActor-->
<!--class SessionRecorder: ObservableObject {-->
<!--    @Published var sessionDuration: TimeInterval = 0-->
<!--    @Published var measurementStartTime: Date?-->
<!--    -->
<!--    private var timer: Timer?-->
<!--    -->
<!--    func startMonitoring() async {-->
<!--        let stateStream = try? await SmartCoach.sessionStateStream()-->
<!--        -->
<!--        guard let stream = stateStream else { return }-->
<!--        -->
<!--        for await state in stream {-->
<!--            handleStateForRecording(state)-->
<!--        }-->
<!--    }-->
<!--    -->
<!--    private func handleStateForRecording(_ state: SmartCoachSessionState) {-->
<!--        switch state {-->
<!--        case .measuring:-->
<!--            startTimer()-->
<!--            -->
<!--        case .disconnected, .connected:-->
<!--            stopTimer()-->
<!--            -->
<!--        default:-->
<!--            break-->
<!--        }-->
<!--    }-->
<!--    -->
<!--    private func startTimer() {-->
<!--        guard measurementStartTime == nil else { return }-->
<!--        -->
<!--        measurementStartTime = Date()-->
<!--        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in-->
<!--            guard let startTime = self?.measurementStartTime else { return }-->
<!--            self?.sessionDuration = Date().timeIntervalSince(startTime)-->
<!--        }-->
<!--    }-->
<!--    -->
<!--    private func stopTimer() {-->
<!--        timer?.invalidate()-->
<!--        timer = nil-->
<!--        measurementStartTime = nil-->
<!--        sessionDuration = 0-->
<!--    }-->
<!--}-->
<!--```-->

### State-Based Validation

Validate actions based on current state:

```swift
class SmartCoachOperations {
    func canStartMeasuring() -> Bool {
        let state = SmartCoach.currentSessionState()
        return state == .connected
    }
    
    func canConnect() -> Bool {
        let state = SmartCoach.currentSessionState()
        return state == .disconnected
    }
    
    func performActionIfValid(_ action: () async throws -> Void) async {
        let state = SmartCoach.currentSessionState()
        
        guard state != .measuring else {
            print("Cannot perform action while measuring")
            return
        }
        
        do {
            try await action()
        } catch {
            print("Action failed: \(error)")
        }
    }
}
```

## State Transition Diagram

```
disconnected
    ↓ startScanning()
scanning
    ↓ connect(to:)
connecting
    ↓ [connection successful]
connected
    ↓ startMeasuring()
measuring
    ↓ stopMeasuring()
connected
    ↓ disconnect()
disconnected
```

## Best Practices

### 1. Always Monitor State

Set up state monitoring early in your app lifecycle:

```swift
@main
struct MyApp: App {
    @StateObject private var stateMonitor = SessionStateViewModel()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(stateMonitor)
                .task {
                    await stateMonitor.observeSessionState()
                }
        }
    }
}
```

### 2. Handle All States

Make sure your UI handles every possible state:

```swift
func updateUI(for state: SmartCoachSessionState) {
    switch state {
    case .disconnected: showDisconnectedUI()
    case .scanning: showScanningUI()
    case .connecting: showConnectingUI()
    case .connected: showConnectedUI()
    case .measuring: showMeasuringUI()
    }
}
```

### 3. Combine with Error Handling

Use state monitoring alongside error handling:

```swift
for await state in stateStream {
    if case .disconnected = state {
        // Check if disconnect was expected or an error
        if wasUnexpectedDisconnect {
            handleError()
        }
    }
}
```

### 4. Clean Up Streams

Cancel state observation when no longer needed:

```swift
var observationTask: Task<Void, Never>?

func startObserving() {
    observationTask = Task {
        let stream = try? await SmartCoach.sessionStateStream()
        guard let stream else { return }
        
        for await state in stream {
            handleState(state)
        }
    }
}

func stopObserving() {
    observationTask?.cancel()
    observationTask = nil
}
```

## See Also

- ``SmartCoachSessionState``
- ``SmartCoach/sessionStateStream()``
- ``SmartCoach/currentSessionState()``
- <doc:DeviceDiscovery>
- <doc:ConnectionManagement>
