# Session State Management

Learn how to monitor and react to SmartCoach SDK session state changes.

## Overview

The SmartCoach SDK maintains a session state that tracks the current status of device connection and measurement activity. Your app can observe these state changes to update UI, handle disconnections, and provide better user feedback.

## Session States

The SDK uses ``SmartCoachSessionState`` to represent different stages of operation:

| State | Description |
|-------|-------------|
| `disconnected` | No device is connected (carries an optional error describing why) |
| `scanning` | Actively scanning for devices (carries the discovered devices) |
| `connecting` | Attempting to connect to a device |
| `connected` | Device is connected and ready |
| `measuring` | Actively receiving measurement data |
| `reconnecting` | Auto-reconnect is re-establishing a lost connection |

## Observing State Changes

### Using AsyncStream

The primary way to observe state changes is through an AsyncStream:

```swift
@MainActor
@Observable
class SessionStateViewModel {
    var currentState: SmartCoachSessionState = SmartCoach.currentSessionState()
    var errorMessage: String?
    
    /// Observes SDK session state for the lifetime of the calling task.
    /// Drive this from the owning view's `.task` modifier — SwiftUI cancels the
    /// task automatically when the view disappears, so no stored task or manual
    /// teardown is needed.
    func startMonitoring() async {
        do {
            for await state in try await SmartCoach.sessionStateStream() {
                currentState = state
                handleStateChange(state)
            }
        } catch SmartCoachError.notConfigured {
            errorMessage = "Please configure the SDK"
        } catch {
            errorMessage = "An unexpected error occurred: \(error.localizedDescription)"
        }
    }
    
    private func handleStateChange(_ state: SmartCoachSessionState) {
        switch state {
        case let .disconnected(error):
            // Keep observing after errors — the stream carries them as data.
            print("Device disconnected", error.map { "— \($0.localizedDescription)" } ?? "")
            
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
            await viewModel.startMonitoring()
        }
    }
    
    @ViewBuilder
    private var stateIndicator: some View {
        switch viewModel.currentState {
        case .disconnected:
            Image(systemName: "circle")
                .foregroundColor(.gray)
        case .scanning, .connecting, .reconnecting:
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
        case .reconnecting:
            return Text("Reconnecting...")
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


### State-Based Validation

Validate actions based on current state:

```swift
class SmartCoachOperations {
    // These mirror the SDK's own preconditions: operations called from the
    // wrong state throw SmartCoachError.invalidSessionState.
    func canStartMeasuring() -> Bool {
        SmartCoach.currentSessionState().rootState == .connected
    }
    
    func canConnect() -> Bool {
        SmartCoach.currentSessionState().rootState == .disconnected
    }
    
    func performActionIfValid(_ action: () async throws -> Void) async {
        guard SmartCoach.currentSessionState().rootState != .measuring else {
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
    ↓ startScanning()          — only valid from disconnected; otherwise
scanning                         throws invalidSessionState
    ↓ connect(to:)
connecting
    ↓ [handshake completes — asynchronous; connect(to:) returning
       does not mean connected yet]
connected
    ↓ startMeasuring()         — only valid from connected
measuring
    ↓ stopMeasuring()
connected
    ↓ disconnect()
disconnected

(unexpected connection loss, with autoReconnect enabled)
connected / measuring
    ↓ [connection lost]
reconnecting
    ↓ [device found again]
connected
```

## Best Practices

### 1. Always Monitor State

Set up state monitoring early in your app lifecycle:

```swift
@main
struct MyApp: App {
    @State private var stateMonitor = SessionStateViewModel()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(stateMonitor)
                .task {
                    await stateMonitor.startMonitoring()
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
    case .reconnecting: showReconnectingUI()
    }
}
```

### 3. Combine with Error Handling

Use state monitoring alongside error handling:

```swift
for await state in stateStream {
    // .disconnected carries an optional error: nil means a normal,
    // user-initiated disconnect; non-nil describes an unexpected drop.
    if case let .disconnected(error) = state, let error {
        handleError(error)
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
