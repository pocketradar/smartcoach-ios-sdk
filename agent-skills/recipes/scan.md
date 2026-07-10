# Recipe: Device Scanning

Add SmartCoach device discovery to a view model — a live list of nearby devices plus
start/stop scanning.

**Read `conventions.md` first** — including "contract vs. implementation" and Step 1
(detect the architecture and audit existing SmartCoach usage).

This recipe's **"Rules specific to scanning"** are the architecture-neutral contract.
The **"Adds"** Swift is the MVVM reference implementation — for a non-MVVM app, apply the
rules idiomatically per conventions.md's "Mapping the contract" instead of pasting it.

---

## Prerequisites

- The `SmartCoachSDK` package is added and `SmartCoach.configure()` is called once at
  launch (otherwise scanning throws `SmartCoachError.notConfigured`).

## Adds (MVVM reference implementation)

**Property**

```swift
var availableDevices: [any SmartCoachRadar] = []
```

**Cases in the `startMonitoring()` switch**

```swift
case let .scanning(devices):
    availableDevices = devices
```

Also clear stale results when leaving the scanning context — add
`availableDevices.removeAll()` to `.disconnected` and to the `default` branch (and to
any other non-scanning case a sibling recipe introduces).

**Action methods**

```swift
func startScanning(autoConnect: Bool = false) {
    guard sessionState.rootState != .scanning else { return }
    Task {
        do {
            try await SmartCoach.startScanning(connectToLastPairedDevice: autoConnect)
        } catch {
            errorMessage = "Failed to start scan: \(error.localizedDescription)"
        }
    }
}

func stopScanning() {
    Task {
        do {
            try await SmartCoach.stopScanning()
        } catch {
            errorMessage = "Failed to stop scan: \(error.localizedDescription)"
        }
    }
}
```

`autoConnect: true` asks the SDK to connect automatically to the last paired device if
it is found during the scan.

---

## Rules specific to scanning

- **Devices arrive via `.scanning`, never as a return value** from `startScanning()`.
- **Scanning is invalid while connected/connecting** — `startScanning()` throws
  `SmartCoachError.invalidSessionState`. Surface it; don't retry blindly.
- **`stopScanning()` is safe** — a no-op if not scanning, and it never drops an
  established connection.

---

## Composability

- Applied alone: it creates the canonical structure (from `conventions.md`) plus the
  above.
- Applied to a view model that already observes the stream: add `availableDevices`, add
  the `.scanning` case, ensure non-scanning cases clear `availableDevices`, and add the
  two action methods. Do not add a second `startMonitoring()`.

---

## Minimal illustrative view (adapt to the app's design — not required UI)

```swift
import SwiftUI
import SmartCoachSDK

struct DeviceScanView: View {
    @State private var viewModel = RadarViewModel()

    var body: some View {
        List(viewModel.availableDevices, id: \.id) { device in
            VStack(alignment: .leading) {
                Text(device.id).font(.headline)
                Text("RSSI \(device.rssi)").font(.caption).foregroundStyle(.secondary)
            }
        }
        .task { await viewModel.startMonitoring() }
        .toolbar {
            if viewModel.sessionState.rootState == .scanning {
                Button("Stop") { viewModel.stopScanning() }
            } else {
                Button("Scan") { viewModel.startScanning() }
            }
        }
    }
}
```
