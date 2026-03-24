# Device Discovery

Learn how to scan for and connect to SmartCoach radar devices.

## Overview

Device discovery is the process of scanning for nearby SmartCoach devices via Bluetooth and establishing a connection. The SDK provides simple methods to handle the entire discovery and connection workflow.

## Scanning for Devices

Start scanning for nearby SmartCoach devices:

```swift
do {
    try await SmartCoach.startScanning()
    print("Scanning for devices...")
} catch {
    print("Failed to start scanning: \(error)")
}
```

### Auto-Connect to Last Device

If you want to automatically connect to the previously paired device:

```swift
try await SmartCoach.startScanning(connectToLastPairedDevice: true)
```

This is useful for:
- Returning users who have already paired a device
- Apps with single-device workflows
- Minimizing user friction in the connection process

## Stopping a Scan

Stop scanning when you no longer need to discover devices:

```swift
do {
    try await SmartCoach.stopScanning()
    print("Stopped scanning")
} catch {
    print("Failed to stop scanning: \(error)")
}
```

**Best Practice**: Always stop scanning once you've found and connected to a device to conserve battery.

## Connecting to a Device

Once you have a ``SmartCoachRadar`` device reference (typically from your device discovery UI), connect to it:

```swift
let device: SmartCoachRadar = selectedDevice

do {
    try await SmartCoach.connect(to: device)
    print("Connected to \(device.name)")
} catch {
    print("Connection failed: \(error)")
}
```

## Disconnecting

Disconnect from the currently connected device:

```swift
await SmartCoach.disconnect()
print("Disconnected from device")
```

> Note: `disconnect()` does not throw errors - it always succeeds. 
However, if an error occured during disconnection, ``SmartCoach/sessionStateStream()`` will emit
a ``SmartCoachSessionState/disconnected(_:)`` state with an error as an associated value.


## Complete Discovery Flow

Here's a complete example showing device discovery and connection:

ViewModel:
```swift
import Foundation
import SwiftUI
import SmartCoachSDK

@MainActor
@Observable
class ScanningViewModel {
    var availableDevices: [any SmartCoachRadar] = []
    var errorMessage: String?
    var scanningObservationsTask: Task<Void, Never>?
    var isScanning = false

    // Available in Swift 6.2
    // Otherwise start startScanningObservations needs to be async and called from the view.task
    isolated deinit {
        resetScanning()
    }
    
    func startScanning() {
        guard !isScanning else { return }
        resetScanning()
        startScanningObservations()
        Task {
            do {
                isScanning = true
                try await SmartCoach.startScanning(connectToLastPairedDevice: false)
            } catch {
                self.errorMessage = "Failed to start scan: \(error.localizedDescription)"
            }
        }
    }
    
    func stopScanning() {
        resetScanning()
        isScanning = false
        Task {
            do {
                try await SmartCoach.stopScanning()
            } catch {
                self.errorMessage = "Failed to stop scan: \(error.localizedDescription)"
            }
        }
    }
    
    func connectToDevice(_ device: any SmartCoachRadar) {
        // Connect to device
    }
    
    private func startScanningObservations() {
        resetScanning()
        scanningObservationsTask = Task { @MainActor in
            do {
                for await state in try await SmartCoach.sessionStateStream() {
                    try Task.checkCancellation()
                    if case let .scanning(devices) = state {
                        availableDevices = devices
                    }
                }
            } catch SmartCoachError.notConfigured {
                errorMessage = "Please configure the SDK"
            } catch {
                errorMessage = "An unexpected error occurred: \(error.localizedDescription)"
                print(error.localizedDescription)
            }
        }
    }
    
    private func resetScanning() {
        scanningObservationsTask?.cancel()
        scanningObservationsTask = nil
        availableDevices.removeAll()
    }
}
```

View:
```swift
import SwiftUI
import SmartCoachSDK

struct ScanningView: View {
    @State private var viewModel = ScanningViewModel()
    var body: some View {
        VStack {
            scanningButton
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack {
                    ForEach(viewModel.availableDevices, id: \.id) { device in
                        HStack {
                            
                            VStack(alignment: .leading) {
                                Text(device.id)
                                    .font(.headline)
                                Text("RSSI: \(device.rssi)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            // Signal strength indicator
                            SignalStrengthView(level: RadarConnectionStrength(rssi: device.rssi))
                                .frame(width: 24, height: 24)
                            Button("Connect") {
                                viewModel.connectToDevice(device)
                            }.buttonStyle(.bordered)
                            
                        }
                    }
                }.padding()
            }
        }
    }
    
    @ViewBuilder
    private var scanningButton: some View {
        if viewModel.isScanning {
            Button("Stop Scanning") {
                viewModel.stopScanning()
            }.buttonStyle(.bordered)
        } else {
            Button("Start Scanning") {
                viewModel.startScanning()
            }.buttonStyle(.bordered)
        }
    }
}

#Preview {
    ScanningView()
}

```

## Connection States

Monitor connection state changes using the session state stream:

```swift
let stateStream = try await SmartCoach.sessionStateStream()

for await state in stateStream {
    switch state {
    case .disconnected:
        print("Device disconnected")
        
    case .scanning:
        print("Scanning for devices")
        
    case .connecting:
        print("Connecting to device")
        
    case .connected:
        print("Device connected")
        
    case .measuring:
        print("Receiving measurements")
    }
}
```

See <doc:SessionStateManagement> for more details.

## Common Errors

### Bluetooth Not Available

```swift
catch SmartCoachError.bluetoothNotAvailable {
    // Bluetooth is off or not authorized
    // Prompt user to enable Bluetooth in Settings
}
```

### Failed to Start Scanning

```swift
catch SmartCoachError.failedToStartScanning {
    // Scanning couldn't start
    // This might be temporary - retry after a delay
}
```

### Failed to Connect

```swift
catch SmartCoachError.failedToConnect {
    // Device connection failed
    // Device may be out of range or already connected to another device
}
```

## Best Practices


### 1. Handle Bluetooth Permissions

Request Bluetooth permissions before scanning:

```swift
import CoreBluetooth

func checkBluetoothPermissions() {
    let manager = CBCentralManager()
    
    switch manager.authorization {
    case .allowedAlways:
        // Ready to scan
        break
    case .denied, .restricted:
        // Show settings prompt
        showBluetoothPermissionAlert()
    case .notDetermined:
        // Will prompt automatically
        break
    @unknown default:
        break
    }
}
```

### 2. Provide Visual Feedback

Show users what's happening during discovery:

```swift
struct ScanningView: View {
    @StateObject var viewModel = DeviceDiscoveryViewModel()
    
    var body: some View {
        VStack {
            if viewModel.isScanning {
                ProgressView("Scanning for devices...")
            }
            
            List(viewModel.discoveredDevices) { device in
                Button(device.name) {
                    Task {
                        await viewModel.connect(to: device)
                    }
                }
            }
        }
    }
}
```

### 3. Auto-Connect for Returning Users

Use auto-connect for better UX with returning users:

```swift
func handleAppLaunch() async {
    if hasConnectedBefore {
        do {
            // Seamlessly reconnect
            try await SmartCoach.startScanning(connectToLastPairedDevice: true)
        } catch {
            // Fall back to manual device selection
            showDeviceSelectionScreen()
        }
    } else {
        showDeviceSelectionScreen()
    }
}
```

### 4. Handle Unexpected Disconnections

React appropriately when connection is lost:

```swift
let stateStream = try await SmartCoach.sessionStateStream()

for await state in stateStream {
    if case .disconnected = state {
        // Connection lost
        if shouldAutoReconnect {
            try? await SmartCoach.startScanning(connectToLastPairedDevice: true)
        } else {
            showReconnectPrompt()
        }
    }
}
```
> Note: Unexpected disconnects can be handle by the SDK by sending ``SmartCoachDeviceConfigurationOptions`` when configuring the SDK

## See Also

- ``SmartCoach/startScanning(connectToLastPairedDevice:)``
- ``SmartCoach/stopScanning()``
- ``SmartCoach/connect(to:)``
- ``SmartCoach/disconnect()``
- ``SmartCoachRadar``
- <doc:ConnectionManagement>
- <doc:SessionStateManagement>
