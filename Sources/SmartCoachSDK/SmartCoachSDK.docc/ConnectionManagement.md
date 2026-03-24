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
        isConnected = true
        connectionStatus = "Reconnected"
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
<!---->
<!--### Conditional Auto-Reconnect-->
<!---->
<!--Only reconnect in certain scenarios:-->
<!---->
<!--```swift-->
<!--class ConditionalReconnectManager {-->
<!--    private var shouldAutoReconnect = false-->
<!--    private var isMeasuring = false-->
<!--    -->
<!--    func enableAutoReconnect(during activity: () async throws -> Void) async throws {-->
<!--        shouldAutoReconnect = true-->
<!--        defer { shouldAutoReconnect = false }-->
<!--        -->
<!--        try await activity()-->
<!--    }-->
<!--    -->
<!--    func handleDisconnect() async {-->
<!--        guard shouldAutoReconnect else {-->
<!--            print("Auto-reconnect disabled")-->
<!--            return-->
<!--        }-->
<!--        -->
<!--        try? await SmartCoach.startScanning(connectToLastPairedDevice: true)-->
<!--    }-->
<!--}-->
<!---->
<!--// Usage-->
<!--let manager = ConditionalReconnectManager()-->
<!---->
<!--// Enable auto-reconnect only during measurements-->
<!--try await manager.enableAutoReconnect {-->
<!--    let stream = try await SmartCoach.startMeasuring()-->
<!--    for await measurement in stream {-->
<!--        processMeasurement(measurement)-->
<!--    }-->
<!--}-->
<!--```-->

<!--## Connection Pooling-->
<!---->
<!--For apps that might need to connect to multiple devices:-->
<!---->
<!--```swift-->
<!--@MainActor-->
<!--class ConnectionPool: ObservableObject {-->
<!--    @Published var activeConnections: [UUID: SmartCoachRadar] = [:]-->
<!--    -->
<!--    private var currentDevice: SmartCoachRadar?-->
<!--    -->
<!--    func connect(to device: SmartCoachRadar) async throws {-->
<!--        // Disconnect from current device if different-->
<!--        if let current = currentDevice, current.id != device.id {-->
<!--            await SmartCoach.disconnect()-->
<!--        }-->
<!--        -->
<!--        try await SmartCoach.connect(to: device)-->
<!--        currentDevice = device-->
<!--        activeConnections[device.id] = device-->
<!--    }-->
<!--    -->
<!--    func disconnect(from deviceId: UUID) async {-->
<!--        if currentDevice?.id == deviceId {-->
<!--            await SmartCoach.disconnect()-->
<!--            currentDevice = nil-->
<!--        }-->
<!--        activeConnections.removeValue(forKey: deviceId)-->
<!--    }-->
<!--    -->
<!--    func switchDevice(to device: SmartCoachRadar) async throws {-->
<!--        await SmartCoach.disconnect()-->
<!--        try await SmartCoach.connect(to: device)-->
<!--        currentDevice = device-->
<!--    }-->
<!--}-->
<!--```-->
<!---->
<!--## Background Connection Management-->
<!---->
<!--### Maintain Connection in Background-->
<!---->
<!--Keep connection alive during background transitions:-->
<!---->
<!--```swift-->
<!--@MainActor-->
<!--class BackgroundConnectionManager: ObservableObject {-->
<!--    private var backgroundTask: UIBackgroundTaskIdentifier = .invalid-->
<!--    -->
<!--    func enterBackground() {-->
<!--        backgroundTask = UIApplication.shared.beginBackgroundTask { [weak self] in-->
<!--            self?.endBackgroundTask()-->
<!--        }-->
<!--    }-->
<!--    -->
<!--    func enterForeground() async {-->
<!--        endBackgroundTask()-->
<!--        -->
<!--        // Check if still connected-->
<!--        let state = SmartCoach.currentSessionState()-->
<!--        if state == .disconnected {-->
<!--            try? await SmartCoach.startScanning(connectToLastPairedDevice: true)-->
<!--        }-->
<!--    }-->
<!--    -->
<!--    private func endBackgroundTask() {-->
<!--        if backgroundTask != .invalid {-->
<!--            UIApplication.shared.endBackgroundTask(backgroundTask)-->
<!--            backgroundTask = .invalid-->
<!--        }-->
<!--    }-->
<!--}-->
<!---->
<!--// Setup in App or Scene-->
<!--@main-->
<!--struct MyApp: App {-->
<!--    @StateObject private var connectionManager = BackgroundConnectionManager()-->
<!--    @Environment(\.scenePhase) private var scenePhase-->
<!--    -->
<!--    var body: some Scene {-->
<!--        WindowGroup {-->
<!--            ContentView()-->
<!--        }-->
<!--        .onChange(of: scenePhase) { oldPhase, newPhase in-->
<!--            switch newPhase {-->
<!--            case .background:-->
<!--                connectionManager.enterBackground()-->
<!--            case .active:-->
<!--                Task {-->
<!--                    await connectionManager.enterForeground()-->
<!--                }-->
<!--            default:-->
<!--                break-->
<!--            }-->
<!--        }-->
<!--    }-->
<!--}-->
<!--```-->
<!---->
<!--## Connection Health Monitoring-->
<!---->
<!--### Ping-Based Health Check-->
<!---->
<!--Periodically verify connection is healthy:-->
<!---->
<!--```swift-->
<!--class ConnectionHealthMonitor {-->
<!--    private var healthCheckTimer: Timer?-->
<!--    private let healthCheckInterval: TimeInterval = 30.0-->
<!--    -->
<!--    func startMonitoring() {-->
<!--        healthCheckTimer = Timer.scheduledTimer(-->
<!--            withTimeInterval: healthCheckInterval,-->
<!--            repeats: true-->
<!--        ) { [weak self] _ in-->
<!--            Task { @MainActor in-->
<!--                await self?.checkConnectionHealth()-->
<!--            }-->
<!--        }-->
<!--    }-->
<!--    -->
<!--    func stopMonitoring() {-->
<!--        healthCheckTimer?.invalidate()-->
<!--        healthCheckTimer = nil-->
<!--    }-->
<!--    -->
<!--    private func checkConnectionHealth() async {-->
<!--        let state = SmartCoach.currentSessionState()-->
<!--        -->
<!--        if state == .disconnected {-->
<!--            print("Connection unhealthy - attempting reconnect")-->
<!--            try? await SmartCoach.startScanning(connectToLastPairedDevice: true)-->
<!--        }-->
<!--    }-->
<!--}-->
<!--```-->
<!---->
<!--### Connection Quality Metrics-->
<!---->
<!--Track connection quality over time:-->
<!---->
<!--```swift-->
<!--@MainActor-->
<!--class ConnectionQualityTracker: ObservableObject {-->
<!--    @Published var connectionQuality: ConnectionQuality = .unknown-->
<!--    -->
<!--    private var connectionCount = 0-->
<!--    private var disconnectionCount = 0-->
<!--    private var reconnectionAttempts = 0-->
<!--    -->
<!--    enum ConnectionQuality {-->
<!--        case excellent // No issues-->
<!--        case good      // Rare disconnects-->
<!--        case fair      // Occasional reconnects needed-->
<!--        case poor      // Frequent disconnects-->
<!--        case unknown-->
<!--    }-->
<!--    -->
<!--    func trackConnection() {-->
<!--        connectionCount += 1-->
<!--        updateQuality()-->
<!--    }-->
<!--    -->
<!--    func trackDisconnection() {-->
<!--        disconnectionCount += 1-->
<!--        updateQuality()-->
<!--    }-->
<!--    -->
<!--    func trackReconnectionAttempt() {-->
<!--        reconnectionAttempts += 1-->
<!--        updateQuality()-->
<!--    }-->
<!--    -->
<!--    private func updateQuality() {-->
<!--        guard connectionCount > 0 else {-->
<!--            connectionQuality = .unknown-->
<!--            return-->
<!--        }-->
<!--        -->
<!--        let disconnectRate = Double(disconnectionCount) / Double(connectionCount)-->
<!--        let reconnectRate = Double(reconnectionAttempts) / Double(connectionCount)-->
<!--        -->
<!--        if disconnectRate < 0.05 {-->
<!--            connectionQuality = .excellent-->
<!--        } else if disconnectRate < 0.15 {-->
<!--            connectionQuality = .good-->
<!--        } else if disconnectRate < 0.30 {-->
<!--            connectionQuality = .fair-->
<!--        } else {-->
<!--            connectionQuality = .poor-->
<!--        }-->
<!--    }-->
<!--    -->
<!--    func reset() {-->
<!--        connectionCount = 0-->
<!--        disconnectionCount = 0-->
<!--        reconnectionAttempts = 0-->
<!--        connectionQuality = .unknown-->
<!--    }-->
<!--}-->
<!--```-->
<!---->
<!--## Connection State Persistence-->
<!---->
<!--### Save Last Connected Device-->
<!---->
<!--Remember the last device for quick reconnect:-->
<!---->
<!--```swift-->
<!--class ConnectionPersistence {-->
<!--    private let lastDeviceKey = "lastConnectedDeviceId"-->
<!--    -->
<!--    func saveLastDevice(_ device: SmartCoachRadar) {-->
<!--        UserDefaults.standard.set(device.id.uuidString, forKey: lastDeviceKey)-->
<!--    }-->
<!--    -->
<!--    func hasLastDevice() -> Bool {-->
<!--        UserDefaults.standard.string(forKey: lastDeviceKey) != nil-->
<!--    }-->
<!--    -->
<!--    func clearLastDevice() {-->
<!--        UserDefaults.standard.removeObject(forKey: lastDeviceKey)-->
<!--    }-->
<!--}-->
<!---->
<!--// Usage-->
<!--let persistence = ConnectionPersistence()-->
<!---->
<!--// After successful connection-->
<!--try await SmartCoach.connect(to: device)-->
<!--persistence.saveLastDevice(device)-->
<!---->
<!--// On app launch-->
<!--if persistence.hasLastDevice() {-->
<!--    try await SmartCoach.startScanning(connectToLastPairedDevice: true)-->
<!--}-->
<!--```-->

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

- ``SmartCoach/startScanning(connectToLastPairedDevice:)``
- ``SmartCoach/connect(to:)``
- ``SmartCoach/disconnect()``
- ``SmartCoachDeviceConfigurationOptions``
- <doc:DeviceDiscovery>
- <doc:SessionStateManagement>
- <doc:BestPractices>
