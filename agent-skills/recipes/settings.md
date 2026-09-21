# Recipe: Radar Settings (units, speed range, sensitivity)

Add controls that change settings on the connected radar.

**Read `conventions.md` first** — including "contract vs. implementation" and Step 1
(detect the architecture and audit existing SmartCoach usage). Applied after
`connect.md`: settings need a connected radar.

This recipe's **"Rules specific to settings"** are the architecture-neutral contract.
The **"Adds"** Swift is the MVVM reference — for a non-MVVM app, apply the rules
idiomatically per conventions.md's "Mapping the contract" instead of pasting it.

---

## Prerequisites

- The `SmartCoachSDK` package is added and `SmartCoach.configure()` is called at launch.
- The session is `.connected` or `.measuring`. Settings calls from any other state throw
  `SmartCoachError.invalidSessionState`.

## The three settings

| Call | Value type | Effect | Devices |
|---|---|---|---|
| `SmartCoach.setMeasurementUnit(_:)` | `RadarMeasurementUnit` (`.mph` / `.kph`) | The radar displays and reports in this unit; `MeasurementData.measurement` follows it. | SmartCoach 1 & 2 |
| `SmartCoach.setSpeedRange(_:)` | `RadarSpeedRange` | The radar ignores readings outside the window. | SmartCoach 1 & 2 |
| `SmartCoach.setSensitivity(_:)` | `RadarSensitivity` | Detection sensitivity, 1 (least) … 10 (default). | SmartCoach 1 only |

`RadarSpeedRange` and `RadarSensitivity` have **failable initializers** that enforce the
hardware limits (`25 ≤ low ≤ high ≤ 130` mph; level `1…10`). A `nil` result means the
user's input is out of range — report it in the UI; there is nothing to send.

## Adds (MVVM reference implementation)

**Property**

```swift
var settingsMessage: String?
```

**Action methods**

```swift
func setUnit(_ unit: RadarMeasurementUnit) {
    runSetting("Units") { try await SmartCoach.setMeasurementUnit(unit) }
}

func setSpeedRange(lowMPH: UInt8, highMPH: UInt8) {
    guard let range = RadarSpeedRange(lowMPH: lowMPH, highMPH: highMPH) else {
        errorMessage = "Speed range must satisfy 25 ≤ low ≤ high ≤ 130 mph"
        return
    }
    runSetting("Speed range") { try await SmartCoach.setSpeedRange(range) }
}

func setSensitivity(level: UInt8) {
    guard let sensitivity = RadarSensitivity(level: level) else {
        errorMessage = "Sensitivity must be 1…10"
        return
    }
    runSetting("Sensitivity") { try await SmartCoach.setSensitivity(sensitivity) }
}

private func runSetting(_ label: String, _ body: @escaping @MainActor () async throws -> Void) {
    settingsMessage = "\(label): waiting for the radar…"
    Task {
        do {
            try await body()
            settingsMessage = "\(label): applied"
        } catch SmartCoachError.commandFailed {
            settingsMessage = "\(label): the radar did not accept the change"
        } catch SmartCoachError.featureNotSupported {
            settingsMessage = "\(label): not supported on this radar"
        } catch {
            settingsMessage = "\(label): failed"
            errorMessage = error.localizedDescription
        }
    }
}
```

**Reading the current values.** The radar's unit is on the device in the session state
(`device.measurementUnit`) and updates once the radar confirms — read it from
`sessionState`, don't cache it. The SDK does not expose the current range or
sensitivity; the app owns those values.

---

## Rules specific to settings

- **Each call waits for the radar's acknowledgement** and returns only when the radar
  has confirmed (or throws `commandFailed` after a few seconds). Show a pending state.
- **Radars reset to defaults on every connection** (full range, default sensitivity, and
  the unit the radar was last left in). If the app has a preferred range/sensitivity,
  re-apply it in the `.connected` case of `startMonitoring()` — including after an
  auto-reconnect, which also lands in `.connected`.
- **Validate with the failable initializers**, never by hand; the SDK will not send an
  invalid value.
- **`setSensitivity` throws `featureNotSupported` on SmartCoach 2.** Hide or disable the
  control when `device.deviceType == .smartCoach2`.
- **One setting at a time.** Calls are serialized inside the SDK; awaiting them in
  sequence is fine, but don't fire several concurrently from the UI and expect ordering.

---

## Composability

- Add `settingsMessage`, the three action methods, and `runSetting`.
- Re-apply persisted settings in the existing `.connected` case (do not add a second
  observation).
- Pairs with `connect.md` (needs `.connected`) and is independent of `measure.md`.

---

## Minimal illustrative view fragment (adapt — not required UI)

```swift
if case let .connected(device) = viewModel.sessionState {
    HStack {
        Button("mph") { viewModel.setUnit(.mph) }.disabled(device.measurementUnit == .mph)
        Button("kph") { viewModel.setUnit(.kph) }.disabled(device.measurementUnit == .kph)
    }
    Button("40–100 mph") { viewModel.setSpeedRange(lowMPH: 40, highMPH: 100) }
    if device.deviceType == .smartCoach1 {
        Button("Sensitivity 7") { viewModel.setSensitivity(level: 7) }
    }
    if let message = viewModel.settingsMessage { Text(message).font(.caption) }
}
```
