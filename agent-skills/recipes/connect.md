# Recipe: Connect & Disconnect

Add connecting to a discovered device (and disconnecting) to a view model.

**Read `conventions.md` first** — including "contract vs. implementation" and Step 1
(detect the architecture and audit existing SmartCoach usage). Usually applied after
`scan.md` (you connect to a device the user picked from the scan list).

This recipe's **"Rules specific to connecting"** are the architecture-neutral contract.
The **"Adds"** Swift is the MVVM reference — for a non-MVVM app, apply the rules
idiomatically per conventions.md's "Mapping the contract" instead of pasting it.

---

## Prerequisites

- The `SmartCoachSDK` package is added and `SmartCoach.configure()` is called at launch.
- A device to connect to — typically from the `.scanning` list (`scan.md`), or the last
  paired device via `startScanning(autoConnect: true)`.

## Adds (MVVM reference implementation)

**No new stored property is required** — the connected device is carried in
`sessionState` (`.connecting`/`.connected`/`.reconnecting` associated value). Read it
where you need it, e.g. in the view: `if case let .connected(device) = viewModel.sessionState`.

**Cases in the `startMonitoring()` switch** — connection states are handled by the
canonical `default` branch already (clear transient lists). Add explicit cases only if
the UI must react. Common additions:

```swift
case .connected:
    availableDevices.removeAll()   // stop showing the scan list once connected
```

(`.connecting` and `.reconnecting` typically fall through to `default`.)

**Action methods**

```swift
func connectToDevice(_ device: any SmartCoachRadar) {
    guard sessionState.rootState != .connected else { return }
    Task {
        do {
            try await SmartCoach.connect(to: device)
        } catch {
            errorMessage = "Connection failed: \(error.localizedDescription)"
        }
    }
}

func disconnect() {
    Task {
        await SmartCoach.disconnect()
    }
}
```

---

## Rules specific to connecting

- **`connect(to:)` returning does NOT mean "ready."** The BLE link is up and the
  encryption handshake is initiated, but the session only becomes `.connected`
  afterward via the stream. Anything that needs a ready device (e.g. `startMeasuring`)
  must wait for the `.connected` state, not for `connect(to:)` to return.
- **`disconnect()` does not throw and returns `Void`.** `await` it — never `try`. If an
  error occurred it arrives as `.disconnected(error)` on the stream.
- **Connecting while already connected/connecting throws
  `SmartCoachError.invalidSessionState`.** The `guard` above avoids the common case.
- **Reconnection is automatic only for *unexpected* disconnects**, and only when the SDK
  was configured with `autoReconnect: true`. The SDK drives it and surfaces
  `.reconnecting(device)` on the stream; show it in the UI if you want, but do not call
  `connect` yourself to "help." A user-initiated `disconnect()` never auto-reconnects.

---

## Composability

- Add the two action methods.
- Optionally add the `.connected` case (to hide the scan list); otherwise `default`
  handles it.
- If `scan.md` is present, `connectToDevice(_:)` pairs with the scan list's "Connect"
  buttons.
- If `measure.md` is present, the `.connected` state is the gate for `startMeasuring()`.

---

## Minimal illustrative view fragment (adapt — not required UI)

```swift
// A "Connect" button per scanned device:
Button("Connect") { viewModel.connectToDevice(device) }

// A single action button reacting to state:
switch viewModel.sessionState {
case .disconnected:
    Button("Scan") { viewModel.startScanning() }
case .connected, .connecting, .reconnecting, .measuring:
    Button("Disconnect") { viewModel.disconnect() }
case .scanning:
    Button("Stop Scanning") { viewModel.stopScanning() }
}
```
