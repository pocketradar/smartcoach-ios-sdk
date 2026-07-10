# Recipe: Stream Measurements

Add live speed measurement streaming to a view model.

**Read `conventions.md` first** — including "contract vs. implementation" and Step 1
(detect the architecture and audit existing SmartCoach usage). Applied after
`connect.md` — you can only measure a connected device.

This recipe's **"Rules specific to measuring"** are the architecture-neutral contract.
The **"Adds"** Swift is the MVVM reference — for a non-MVVM app, apply the rules
idiomatically per conventions.md's "Mapping the contract" instead of pasting it. The
cross-capability cleanup (cancel the measurement task in non-measuring states) is part
of the contract, however the switch/reducer is expressed.

---

## Prerequisites

- The `SmartCoachSDK` package is added and `SmartCoach.configure()` is called at launch.
- A `.connected` device (see `connect.md`). Measuring from any other state throws
  `SmartCoachError.invalidSessionState`.

## Adds

**Properties**

```swift
var speeds: [Measurement<UnitSpeed>] = []
private var speedsTask: Task<Void, Never>?
```

Unlike monitoring, the measurement stream is a **stored** task on the view model
(cancelled on state transitions), because it starts/stops independently of the view's
lifetime.

**Cases in the `startMonitoring()` switch** — measuring introduces cross-capability
cleanup. Add a `.measuring` case that does NOT cancel the speeds task, and ensure the
non-measuring branches DO cancel it:

```swift
case .measuring:
    availableDevices.removeAll()      // keep the speeds task running
```

Then add `cancelSpeedsTask()` to the sibling branches that end measurement —
`.scanning`, `.disconnected`, and `default`:

```swift
case let .scanning(devices):
    availableDevices = devices
    cancelSpeedsTask()
case let .disconnected(error):
    availableDevices.removeAll()
    cancelSpeedsTask()
    if let error { errorMessage = error.localizedDescription }
default:
    availableDevices.removeAll()
    cancelSpeedsTask()
```

**Action methods & helper**

```swift
func startMeasuring() {
    // Measuring is only valid from .connected — the SDK enforces this
    // (SmartCoachError.invalidSessionState); the guard keeps the UI honest.
    guard sessionState.rootState == .connected else { return }
    speeds.removeAll()
    speedsTask = Task { [weak self] in
        do {
            // The stream completes when measuring stops, the device disconnects,
            // or the connection is lost — the loop ends on its own.
            for await speed in try await SmartCoach.startMeasuring() {
                self?.speeds.insert(speed.measurement, at: 0)
            }
        } catch {
            self?.errorMessage = "Failed to start measuring: \(error.localizedDescription)"
        }
    }
}

func stopMeasuring() {
    cancelSpeedsTask()
    guard sessionState.rootState == .measuring else { return }
    Task {
        do {
            try await SmartCoach.stopMeasuring()
        } catch {
            errorMessage = "Failed to stop measuring: \(error.localizedDescription)"
        }
    }
}

private func cancelSpeedsTask() {
    speedsTask?.cancel()
    speedsTask = nil
    speeds.removeAll()
}
```

---

## Rules specific to measuring

- **`startMeasuring()` requires `.connected`.** Not `.connecting`, not "right after
  `connect(to:)` returned." The SDK throws `invalidSessionState` otherwise.
- **The measurement stream self-completes** on `stopMeasuring()`, `disconnect()`, or a
  dropped connection — the `for await` loop ends without you cancelling it. The stored
  `speedsTask` + `cancelSpeedsTask()` handle the cases where *state changes out from
  under* an active measurement.
- **`[weak self]` in the task is required.** It prevents the task from retaining the
  view model, and it is why no `deinit` cleanup is needed (nor possible on a
  `@MainActor` type).
- **Do not wrap `self?.speeds` updates in `MainActor.run`** — the view model is already
  main-actor isolated.

---

## Composability

- Add the `speeds` and `speedsTask` properties, the three methods, and the `.measuring`
  case.
- **Critically**, inject `cancelSpeedsTask()` into the existing non-measuring branches
  (`.scanning`, `.disconnected`, `default`). This is the cross-capability cleanup called
  out in `conventions.md` — measuring is the one recipe that edits sibling cases.
- Requires `connect.md`'s `.connected` state to be reachable; pairs with a
  "Start/Stop Measuring" button shown when connected/measuring.

---

## Minimal illustrative view fragment (adapt — not required UI)

```swift
let formatter: MeasurementFormatter = {
    let f = MeasurementFormatter(); f.unitOptions = .providedUnit; return f
}()

// when connected:
Button("Start Measuring") { viewModel.startMeasuring() }

// when measuring:
Button("Stop Measuring") { viewModel.stopMeasuring() }
ForEach(Array(viewModel.speeds.prefix(10).enumerated()), id: \.offset) { _, speed in
    Text(formatter.string(from: speed)).font(.system(.body, design: .monospaced))
}
```
