# Auto-Reconnect

Learn how to implement automatic reconnection to maintain seamless connectivity with SmartCoach devices.

## Overview

Auto-reconnect automatically re-establishes connections when they're unexpectedly lost, providing a seamless experience for users during long sessions or when connectivity is intermittent.

## Built-In Auto-Reconnect

### Enabling Auto-Reconnect

Enable auto-reconnect during SDK configuration:

```swift
let options = SmartCoachDeviceConfigurationOptions(autoReconnect: true)

do {
    try SmartCoach.configure(deviceConfigurationOptions: options)
} catch {
    print("Configuration failed: \(error)")
}
```

### How It Works

When auto-reconnect is enabled:
1. SDK detects connection loss
2. Automatically attempts to reconnect to the last paired device
3. Continues attempting with exponential backoff
4. Restores connection transparently to your app

### When to Use Built-In Auto-Reconnect

✅ **Use when:**
- Running long measurement sessions
- Operating in environments with potential interference
- Background operation is required
- User experience should be uninterrupted

❌ **Don't use when:**
- Users frequently switch between devices
- Short, isolated measurement sessions
- You need custom reconnection logic
- Battery life is critical

## Custom Auto-Reconnect

### Basic Custom Implementation

Implement your own reconnection logic:

<!--```swift-->
<!--@MainActor-->
<!--class CustomAutoReconnect: ObservableObject {-->
<!--    @Published var isReconnecting = false-->
<!--    -->
<!--    func startMonitoring() async {-->
<!--        let stateStream = try? await SmartCoach.sessionStateStream()-->
<!--        -->
<!--        guard let stream = stateStream else { return }-->
<!--        -->
<!--        for await state in stream {-->
<!--            if case .disconnected = state {-->
<!--                await attemptReconnect()-->
<!--            }-->
<!--        }-->
<!--    }-->
<!--    -->
<!--    private func attemptReconnect() async {-->
<!--        guard !isReconnecting else { return }-->
<!--        -->
<!--        isReconnecting = true-->
<!--        defer { isReconnecting = false }-->
<!--        -->
<!--        do {-->
<!--            try await SmartCoach.startScanning(connectToLastPairedDevice: true)-->
<!--            print("Reconnected successfully")-->
<!--        } catch {-->
<!--            print("Reconnection failed: \(error)")-->
<!--        }-->
<!--    }-->
<!--}-->
<!--```-->
<!---->
<!--### Advanced: Retry with Exponential Backoff-->
<!---->
<!--Implement smart retry logic:-->
<!---->
<!--```swift-->
<!--@MainActor-->
<!--class ExponentialBackoffReconnect: ObservableObject {-->
<!--    @Published var reconnectAttempts = 0-->
<!--    @Published var isReconnecting = false-->
<!--    -->
<!--    private let maxAttempts = 5-->
<!--    private let baseDelay: TimeInterval = 2.0-->
<!--    private var reconnectTask: Task<Void, Never>?-->
<!--    -->
<!--    func startMonitoring() async {-->
<!--        let stream = try? await SmartCoach.sessionStateStream()-->
<!--        guard let stream else { return }-->
<!--        -->
<!--        for await state in stream {-->
<!--            switch state {-->
<!--            case .disconnected:-->
<!--                reconnectTask = Task {-->
<!--                    await attemptReconnectWithBackoff()-->
<!--                }-->
<!--            case .connected:-->
<!--                cancelReconnect()-->
<!--            default:-->
<!--                break-->
<!--            }-->
<!--        }-->
<!--    }-->
<!--    -->
<!--    private func attemptReconnectWithBackoff() async {-->
<!--        guard !isReconnecting else { return }-->
<!--        -->
<!--        isReconnecting = true-->
<!--        defer { isReconnecting = false }-->
<!--        -->
<!--        while reconnectAttempts < maxAttempts {-->
<!--            // Calculate delay: 2s, 4s, 8s, 16s, 30s (capped)-->
<!--            let delay = min(baseDelay * pow(2.0, Double(reconnectAttempts)), 30.0)-->
<!--            -->
<!--            print("Reconnect attempt \(reconnectAttempts + 1)/\(maxAttempts) in \(delay)s")-->
<!--            -->
<!--            try? await Task.sleep(for: .seconds(delay))-->
<!--            -->
<!--            // Check if we should still reconnect-->
<!--            guard !Task.isCancelled else { break }-->
<!--            -->
<!--            do {-->
<!--                try await SmartCoach.startScanning(connectToLastPairedDevice: true)-->
<!--                print("Reconnected!")-->
<!--                reconnectAttempts = 0-->
<!--                return-->
<!--            } catch {-->
<!--                reconnectAttempts += 1-->
<!--                print("Attempt \(reconnectAttempts) failed: \(error)")-->
<!--            }-->
<!--        }-->
<!--        -->
<!--        // Max attempts reached-->
<!--        print("Failed to reconnect after \(maxAttempts) attempts")-->
<!--        showManualReconnectPrompt()-->
<!--    }-->
<!--    -->
<!--    func cancelReconnect() {-->
<!--        reconnectTask?.cancel()-->
<!--        reconnectTask = nil-->
<!--        reconnectAttempts = 0-->
<!--    }-->
<!--    -->
<!--    func resetAttempts() {-->
<!--        reconnectAttempts = 0-->
<!--    }-->
<!--}-->
<!--```-->
<!---->
<!--### Conditional Auto-Reconnect-->
<!---->
<!--Only reconnect in specific situations:-->
<!---->
<!--```swift-->
<!--class ConditionalAutoReconnect {-->
<!--    private var isInCriticalSession = false-->
<!--    private var shouldMaintainConnection = false-->
<!--    -->
<!--    func startCriticalSession() async throws {-->
<!--        isInCriticalSession = true-->
<!--        shouldMaintainConnection = true-->
<!--        -->
<!--        // Start monitoring-->
<!--        Task {-->
<!--            await monitorConnection()-->
<!--        }-->
<!--    }-->
<!--    -->
<!--    func endCriticalSession() {-->
<!--        isInCriticalSession = false-->
<!--        shouldMaintainConnection = false-->
<!--    }-->
<!--    -->
<!--    private func monitorConnection() async {-->
<!--        let stream = try? await SmartCoach.sessionStateStream()-->
<!--        guard let stream else { return }-->
<!--        -->
<!--        for await state in stream {-->
<!--            if case .disconnected = state, shouldMaintainConnection {-->
<!--                await reconnectDuringCriticalSession()-->
<!--            }-->
<!--        }-->
<!--    }-->
<!--    -->
<!--    private func reconnectDuringCriticalSession() async {-->
<!--        guard isInCriticalSession else { return }-->
<!--        -->
<!--        print("Critical session - auto-reconnecting")-->
<!--        try? await SmartCoach.startScanning(connectToLastPairedDevice: true)-->
<!--    }-->
<!--}-->
<!---->
<!--// Usage-->
<!--let reconnect = ConditionalAutoReconnect()-->
<!---->
<!--// Start important measurement session-->
<!--try await reconnect.startCriticalSession()-->
<!--let measurements = try await SmartCoach.startMeasuring()-->
<!---->
<!--for await measurement in measurements {-->
<!--    processMeasurement(measurement)-->
<!--}-->
<!---->
<!--// End session-->
<!--reconnect.endCriticalSession()-->
<!--```-->
<!---->
<!--## User Notifications-->
<!---->
<!--### Notify Users of Reconnection-->
<!---->
<!--Keep users informed during reconnection:-->
<!---->
<!--```swift-->
<!--@MainActor-->
<!--class ReconnectNotifier: ObservableObject {-->
<!--    @Published var isReconnecting = false-->
<!--    @Published var reconnectMessage = ""-->
<!--    @Published var showReconnectAlert = false-->
<!--    -->
<!--    func handleDisconnect() async {-->
<!--        isReconnecting = true-->
<!--        reconnectMessage = "Connection lost. Reconnecting..."-->
<!--        showReconnectAlert = true-->
<!--        -->
<!--        var attempts = 0-->
<!--        let maxAttempts = 3-->
<!--        -->
<!--        while attempts < maxAttempts {-->
<!--            attempts += 1-->
<!--            reconnectMessage = "Reconnecting... (Attempt \(attempts)/\(maxAttempts))"-->
<!--            -->
<!--            try? await Task.sleep(for: .seconds(2))-->
<!--            -->
<!--            do {-->
<!--                try await SmartCoach.startScanning(connectToLastPairedDevice: true)-->
<!--                -->
<!--                // Success-->
<!--                reconnectMessage = "Reconnected successfully!"-->
<!--                try? await Task.sleep(for: .seconds(2))-->
<!--                showReconnectAlert = false-->
<!--                isReconnecting = false-->
<!--                return-->
<!--                -->
<!--            } catch {-->
<!--                print("Attempt \(attempts) failed")-->
<!--            }-->
<!--        }-->
<!--        -->
<!--        // All attempts failed-->
<!--        reconnectMessage = "Unable to reconnect. Please reconnect manually."-->
<!--        isReconnecting = false-->
<!--    }-->
<!--}-->
<!---->
<!--// View-->
<!--struct ReconnectionAlertView: View {-->
<!--    @ObservedObject var notifier: ReconnectNotifier-->
<!--    -->
<!--    var body: some View {-->
<!--        VStack {-->
<!--            // Your main content-->
<!--        }-->
<!--        .alert("Connection Status", isPresented: $notifier.showReconnectAlert) {-->
<!--            if !notifier.isReconnecting {-->
<!--                Button("Retry") {-->
<!--                    Task {-->
<!--                        await notifier.handleDisconnect()-->
<!--                    }-->
<!--                }-->
<!--                Button("Cancel", role: .cancel) { }-->
<!--            }-->
<!--        } message: {-->
<!--            Text(notifier.reconnectMessage)-->
<!--        }-->
<!--    }-->
<!--}-->
<!--```-->
<!---->
<!--### Toast Notifications-->
<!---->
<!--Show unobtrusive reconnection status:-->
<!---->
<!--```swift-->
<!--struct ReconnectionToast: View {-->
<!--    let isReconnecting: Bool-->
<!--    let message: String-->
<!--    -->
<!--    var body: some View {-->
<!--        if isReconnecting {-->
<!--            HStack {-->
<!--                ProgressView()-->
<!--                    .scaleEffect(0.8)-->
<!--                Text(message)-->
<!--                    .font(.caption)-->
<!--            }-->
<!--            .padding()-->
<!--            .background(Color.black.opacity(0.7))-->
<!--            .foregroundColor(.white)-->
<!--            .cornerRadius(8)-->
<!--            .transition(.move(edge: .top).combined(with: .opacity))-->
<!--        }-->
<!--    }-->
<!--}-->
<!--```-->
<!---->
<!--## Reconnection Strategies-->
<!---->
<!--### Strategy 1: Aggressive Reconnect-->
<!---->
<!--Reconnect immediately with minimal delay:-->
<!---->
<!--```swift-->
<!--// Best for: Critical monitoring, real-time applications-->
<!--func aggressiveReconnect() async {-->
<!--    let maxAttempts = 10-->
<!--    var attempts = 0-->
<!--    -->
<!--    while attempts < maxAttempts {-->
<!--        try? await Task.sleep(for: .milliseconds(500))-->
<!--        -->
<!--        do {-->
<!--            try await SmartCoach.startScanning(connectToLastPairedDevice: true)-->
<!--            return-->
<!--        } catch {-->
<!--            attempts += 1-->
<!--        }-->
<!--    }-->
<!--}-->
<!--```-->
<!---->
<!--### Strategy 2: Conservative Reconnect-->
<!---->
<!--Longer delays between attempts to conserve battery:-->
<!---->
<!--```swift-->
<!--// Best for: Background monitoring, battery-sensitive apps-->
<!--func conservativeReconnect() async {-->
<!--    let delays: [TimeInterval] = [5, 10, 20, 30]-->
<!--    -->
<!--    for (index, delay) in delays.enumerated() {-->
<!--        try? await Task.sleep(for: .seconds(delay))-->
<!--        -->
<!--        do {-->
<!--            try await SmartCoach.startScanning(connectToLastPairedDevice: true)-->
<!--            return-->
<!--        } catch {-->
<!--            print("Attempt \(index + 1) failed")-->
<!--        }-->
<!--    }-->
<!--}-->
<!--```-->
<!---->
<!--### Strategy 3: Adaptive Reconnect-->
<!---->
<!--Adjust based on connection quality:-->
<!---->
<!--```swift-->
<!--class AdaptiveReconnect {-->
<!--    private var recentFailures = 0-->
<!--    private var recentSuccesses = 0-->
<!--    -->
<!--    func attemptReconnect() async {-->
<!--        let delay = calculateDelay()-->
<!--        try? await Task.sleep(for: .seconds(delay))-->
<!--        -->
<!--        do {-->
<!--            try await SmartCoach.startScanning(connectToLastPairedDevice: true)-->
<!--            recentSuccesses += 1-->
<!--            recentFailures = 0-->
<!--        } catch {-->
<!--            recentFailures += 1-->
<!--            recentSuccesses = 0-->
<!--        }-->
<!--    }-->
<!--    -->
<!--    private func calculateDelay() -> TimeInterval {-->
<!--        // More failures = longer delay-->
<!--        // More successes = shorter delay-->
<!--        let failurePenalty = TimeInterval(recentFailures * 2)-->
<!--        let successBonus = max(0, TimeInterval(3 - recentSuccesses))-->
<!--        -->
<!--        return min(2.0 + failurePenalty + successBonus, 30.0)-->
<!--    }-->
<!--}-->
<!--```-->
<!---->
<!--## Best Practices-->
<!---->
<!--### 1. Inform Users-->
<!---->
<!--Always let users know when reconnection is happening:-->
<!---->
<!--```swift-->
<!--struct StatusBar: View {-->
<!--    let state: SmartCoachSessionState-->
<!--    let isReconnecting: Bool-->
<!--    -->
<!--    var body: some View {-->
<!--        HStack {-->
<!--            if isReconnecting {-->
<!--                HStack(spacing: 8) {-->
<!--                    ProgressView()-->
<!--                        .scaleEffect(0.7)-->
<!--                    Text("Reconnecting...")-->
<!--                        .font(.caption)-->
<!--                }-->
<!--            } else {-->
<!--                connectionStatusIndicator(state)-->
<!--            }-->
<!--        }-->
<!--    }-->
<!--}-->
<!--```-->
<!---->
<!--### 2. Limit Retry Attempts-->
<!---->
<!--Don't retry indefinitely:-->
<!---->
<!--```swift-->
<!--let maxAttempts = 5-->
<!--var attempts = 0-->
<!---->
<!--while attempts < maxAttempts {-->
<!--    // Attempt reconnect-->
<!--    attempts += 1-->
<!--}-->
<!---->
<!--// Prompt user to manually reconnect-->
<!--```-->
<!---->
<!--### 3. Use Exponential Backoff-->
<!---->
<!--Prevent network flooding:-->
<!---->
<!--```swift-->
<!--let delay = min(baseDelay * pow(2.0, Double(attempts)), maxDelay)-->
<!--try await Task.sleep(for: .seconds(delay))-->
<!--```-->
<!---->
<!--### 4. Provide Manual Override-->
<!---->
<!--Let users manually reconnect:-->
<!---->
<!--```swift-->
<!--struct ReconnectButton: View {-->
<!--    @State private var isReconnecting = false-->
<!--    -->
<!--    var body: some View {-->
<!--        Button("Reconnect") {-->
<!--            Task {-->
<!--                isReconnecting = true-->
<!--                defer { isReconnecting = false }-->
<!--                -->
<!--                try? await SmartCoach.startScanning(connectToLastPairedDevice: true)-->
<!--            }-->
<!--        }-->
<!--        .disabled(isReconnecting)-->
<!--    }-->
<!--}-->
<!--```-->
<!---->
<!--### 5. Clean Up on Success-->
<!---->
<!--Reset counters when connection is restored:-->
<!---->
<!--```swift-->
<!--if connectionSuccessful {-->
<!--    reconnectAttempts = 0-->
<!--    consecutiveFailures = 0-->
<!--}-->
<!--```-->
<!---->
<!--## Testing Auto-Reconnect-->
<!---->
<!--### Simulate Disconnections-->
<!---->
<!--Test your reconnection logic:-->
<!---->
<!--```swift-->
<!--#if DEBUG-->
<!--extension SmartCoach {-->
<!--    static func simulateDisconnect() async {-->
<!--        await disconnect()-->
<!--        // Your state should trigger reconnect logic-->
<!--    }-->
<!--}-->
<!--#endif-->
<!--```-->
<!---->
<!--### Monitor Reconnection Performance-->
<!---->
<!--Track reconnection metrics:-->
<!---->
<!--```swift-->
<!--struct ReconnectionMetrics {-->
<!--    var totalDisconnects = 0-->
<!--    var successfulReconnects = 0-->
<!--    var failedReconnects = 0-->
<!--    var averageReconnectTime: TimeInterval = 0-->
<!--    -->
<!--    var successRate: Double {-->
<!--        guard totalDisconnects > 0 else { return 0 }-->
<!--        return Double(successfulReconnects) / Double(totalDisconnects)-->
<!--    }-->
<!--}-->
<!--```-->

## See Also

- ``SmartCoachDeviceConfigurationOptions``
- ``SmartCoach/configure(deviceConfigurationOptions:)``
- <doc:SessionStateManagement>
- <doc:ConnectionManagement>
- <doc:DeviceDiscovery>
