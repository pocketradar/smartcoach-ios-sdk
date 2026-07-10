# Connection Management

Advanced patterns for managing device connections throughout your app's lifecycle.

## Overview

Effective connection management ensures a smooth user experience by handling connections, disconnections, and reconnections gracefully. This guide covers advanced patterns for connection lifecycle management.

## Connection Lifecycle

### Initial Connection

The typical connection flow:

```swift
@MainActor
@Observable
class ConnectionViewModel {
    var sessionState: SmartCoachSessionState = SmartCoach.currentSessionState()
    var sessionStateTask: Task<Void, Never>?
    var errorMessage: String?
    
    init() {
        monitorSessionState()
    }
    
    // Available in Swift 6.2
    // Otherwise start startScanningObservations needs to be async and called from the view.task
    isolated deinit {
        sessionStateTask?.cancel()
        sessionStateTask = nil
    }
    
    func connectToDevice(_ device: any SmartCoachRadar) {
        guard sessionState.rootState == .disconnected else { return }
        Task {
            do {
                try await SmartCoach.connect(to: device)
            } catch {
                self.errorMessage = "Connection failed: \(error.localizedDescription)"
            }
        }
    }
    
    func disconnect() {
        Task {
            await SmartCoach.disconnect()
        }
    }
    
    func startScanning() {
        // handle scanning
    }
    
    private func monitorSessionState() {
        sessionStateTask = Task { @MainActor in
            do {
                for await state in try await SmartCoach.sessionStateStream() {
                    try Task.checkCancellation()
                    sessionState = state
                }
            } catch SmartCoachError.notConfigured {
                errorMessage = "Please configure the SDK"
            } catch {
                errorMessage = "An unexpected error occurred: \(error.localizedDescription)"
                print(error.localizedDescription)
            }
        }
    }
}
```

### Quick Reconnect

For returning users, provide instant reconnection:

```swift
func quickReconnect() async {
    do {
        try await SmartCoach.startScanning(connectToLastPairedDevice: true)
        connectionStatus = "Reconnecting…"
        // Scanning has started — the device is NOT connected yet. The SDK
        // connects when it finds the last paired device; observe
        // sessionStateStream() and treat the session as connected only when
        // it emits .connected (see monitorSessionState above).
    } catch {
        // Fall back to full connection flow
        await initialConnect()
    }
}
```

### Graceful Disconnection

Always disconnect cleanly:

```swift
func disconnect() async {
    await SmartCoach.disconnect()
    isConnected = false
    connectionStatus = "Disconnected"
}
```

## Auto-Reconnect Strategies

### Configuration-Based Auto-Reconnect

Enable at SDK initialization:

```swift
let options = SmartCoachDeviceConfigurationOptions(autoReconnect: true)
try SmartCoach.configure(deviceConfigurationOptions: options)
```

### Custom Auto-Reconnect Logic

Implement your own reconnection strategy:

```swift
@MainActor
class CustomReconnectManager: ObservableObject {
    @Published var connectionState: SmartCoachSessionState = .disconnected
    
    private var reconnectAttempts = 0
    private let maxAttempts = 5
    private var reconnectTask: Task<Void, Never>?
    
    func startMonitoring() async {
        let stateStream = try? await SmartCoach.sessionStateStream()
        
        guard let stream = stateStream else { return }
        
        for await state in stream {
            connectionState = state
            
            if case .disconnected = state {
                await handleDisconnect()
            } else if case .connected = state {
                // Reset on successful connection
                reconnectAttempts = 0
            }
        }
    }
    
    private func handleDisconnect() async {
        guard reconnectAttempts < maxAttempts else {
            print("Max reconnect attempts reached")
            showManualReconnectPrompt()
            return
        }
        
        reconnectAttempts += 1
        
        // Exponential backoff
        let delay = min(pow(2.0, Double(reconnectAttempts)), 30.0)
        try? await Task.sleep(for: .seconds(delay))
        
        do {
            try await SmartCoach.startScanning(connectToLastPairedDevice: true)
        } catch {
            print("Reconnect attempt \(reconnectAttempts) failed: \(error)")
        }
    }
    
    func resetReconnectCounter() {
        reconnectAttempts = 0
    }
}
```


## Best Practices

### 1. Always Monitor State

Set up state monitoring at app launch:

```swift
Task {
    let stream = try await SmartCoach.sessionStateStream()
    for await state in stream {
        handleStateChange(state)
    }
}
```

### 2. Provide User Feedback

Keep users informed during connection operations:

```swift
struct ConnectionStatusView: View {
    @ObservedObject var manager: ConnectionManager
    
    var body: some View {
        HStack {
            statusIndicator
            Text(manager.connectionStatus)
        }
    }
}
```

### 3. Handle Edge Cases

Plan for unexpected scenarios:

```swift
func connect() async {
    do {
        try await SmartCoach.connect(to: device)
    } catch SmartCoachError.bluetoothNotAvailable {
        showBluetoothPrompt()
    } catch SmartCoachError.failedToConnect {
        retryOrShowError()
    } catch {
        handleUnexpectedError(error)
    }
}
```


## See Also

- ``SmartCoach/startScanning(timeout:connectToLastPairedDevice:)``
- ``SmartCoach/connect(to:)``
- ``SmartCoach/disconnect()``
- ``SmartCoachDeviceConfigurationOptions``
- <doc:DeviceDiscovery>
- <doc:SessionStateManagement>
- <doc:BestPractices>
