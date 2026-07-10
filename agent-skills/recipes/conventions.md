# SmartCoach Recipes — Shared Conventions

Read this **before** any capability recipe (`scan.md`, `connect.md`, `measure.md`).

## How to read these recipes: contract vs. implementation

Every capability recipe contains two separable things:

- **The SDK contract** — the required call sequences, the session state machine, the
  lifecycle rules, and the gotchas. This is **architecture-independent** and is the
  actual value of these recipes. It is correct in MVVM, MV, TCA, UIKit/MVC, VIPER, or
  any other architecture. The contract appears as the "Rules" sections and this file's
  "Core contract" below.
- **A reference implementation** — Swift code that realizes the contract in a
  `@MainActor @Observable` **MVVM view model**. This is *one* way to house the contract,
  shown because it's the most common. In a different architecture, **do not paste the
  view-model code** — implement the same contract idiomatically (see "Mapping the
  contract to other architectures" below). The invariants never change; only where the
  state lives and how the side effect is spawned.

If the target app is MVVM, follow the reference implementation directly. Otherwise, take
the contract and map it.

---

## Step 1 — Inspect the target first (every recipe)

Do all of this before writing or prompting:

1. **Detect the architecture.** Look at how existing screens are built:
   - `@Observable` / `ObservableObject` view models per screen → **MVVM** (use the
     reference implementation directly).
   - State held in Views or in a shared `@Observable` model, no per-screen VM → **MV**.
   - `Reducer`/`Store`/`@Reducer`/`Effect` → **TCA**.
   - `UIViewController` subclasses, storyboards/xibs, no SwiftUI → **UIKit / MVC**.
   - Presenter/Interactor/Router, etc. → **VIPER/Clean** or similar.
   If it isn't MVVM, plan to map the contract (see below), not paste the VM code.
2. **Audit existing SmartCoach usage.** Search the whole codebase for `SmartCoach.`,
   `sessionStateStream`, `startScanning`, `startMeasuring`, `SmartCoachSessionState`,
   `import SmartCoachSDK`. A consumer may have a prior, partial, or non-canonical
   attempt (polling `currentSessionState()` on a timer, observing inline in a View, a
   singleton holding devices, scattered duplicate calls). Decide explicitly:
   - **Adopt** — the existing integration already matches the contract → extend it.
   - **Refactor** — it works but diverges from the contract (e.g. polling instead of
     the stream, a second observation) → migrate it to the contract, don't add beside it.
   - **Reconcile** — it's broken/half-done → repair to the contract, removing the dead
     or conflicting pieces.
   Never blindly add a fresh integration alongside an existing one — that reintroduces
   duplicate observation and conflicting state.
3. **Match local conventions** — observation style (`@Observable` vs `ObservableObject`),
   error surface (`errorMessage`/`errorText`/an error enum), naming. Reuse what's there.
4. **Isolation** — SDK calls are `@MainActor`; whatever hosts them must be main-actor
   isolated.
5. **Lifecycle** — where does observation start/stop in this architecture (SwiftUI
   `.task`, TCA `.run` effect, `viewDidAppear`/`viewDidDisappear`, an existing
   `onAppear()`/`onDisappear()` on the VM)?

---

## Core contract (architecture-neutral — applies everywhere)

These hold no matter how the app is structured:

- **Observe `SmartCoach.sessionStateStream()`; do not poll `currentSessionState()`.**
  `currentSessionState()` is for a one-shot read (e.g. seeding initial state), not for
  tracking changes.
- **All SmartCoach calls are `@MainActor`** and mostly `async`. Never wrap the resulting
  property updates in `MainActor.run` from an already-main-actor context.
- **Results arrive via the state stream, not return values.** Actions start work; the
  outcome shows up as a later `SmartCoachSessionState`.
- **Never terminate the observation on a state-carried error.** `.disconnected(error)`
  is data — surface the error and keep observing. Throwing/returning out of the loop
  permanently blinds the app to later states.
- **One observation, one place.** Exactly one active subscription to
  `sessionStateStream()`; route all state handling through its single `switch`.
- **Cancel the observation when its owner goes away** — via structured concurrency
  (SwiftUI `.task`, TCA effect cancellation) or an explicit stored task cancelled in the
  teardown hook. Never in a `@MainActor` type's `deinit` (nonisolated — won't compile).

Per-capability contract additions (the `.connected` precondition for measuring, the
"`connect()` returning ≠ ready" rule, etc.) live in each recipe's "Rules" section.

---

## Reference implementation (MVVM)

The base type, before any capability is added. Capability recipes add properties,
`switch` cases, and action methods to this.

```swift
import Foundation
import SmartCoachSDK

@MainActor
@Observable
final class RadarViewModel {
    var sessionState: SmartCoachSessionState = SmartCoach.currentSessionState()
    var errorMessage: String?

    /// Observes SDK session state for the lifetime of the calling task.
    /// Drive this from the owning view's `.task` modifier.
    func startMonitoring() async {
        do {
            for await state in try await SmartCoach.sessionStateStream() {
                sessionState = state
                switch state {
                case let .disconnected(error):
                    if let error {
                        errorMessage = error.localizedDescription
                    }
                default:
                    break
                }
                // Capability recipes add cases and per-state work here.
            }
        } catch SmartCoachError.notConfigured {
            errorMessage = "Please configure the SDK — call SmartCoach.configure() at launch."
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
```

Lifecycle (MVVM reference):

```swift
.task { await viewModel.startMonitoring() }
```

That single modifier starts observation on appear and cancels it on disappear. Do not
add `.onDisappear` cleanup for monitoring. Variant — if the view model owns its
lifecycle via `onAppear()`/`onDisappear()`, store the task and cancel it in
`onDisappear()` (never `deinit`):

```swift
private var monitoringTask: Task<Void, Never>?
func onAppear() { guard monitoringTask == nil else { return }
                  monitoringTask = Task { await startMonitoring() } }
func onDisappear() { monitoringTask?.cancel(); monitoringTask = nil }
```

`ObservableObject` variant: same code, but declare
`final class RadarViewModel: ObservableObject` and mark each stored property `@Published`.

---

## Mapping the contract to other architectures

Same contract, different home for three roles — **state**, **the observation side
effect**, and **actions**. Implement idiomatically; keep every invariant above.

- **MV / no view model** (SwiftUI state in the View or a shared `@Observable` model):
  put `sessionState` + capability state on the `@Observable` model (or `@State`); run
  `startMonitoring()` from the View's `.task`. Essentially the reference minus a
  dedicated VM class.
- **TCA**: session/capability state → the reducer `State`; the observation → a
  long-running `.run` `Effect` that iterates `sessionStateStream()` and sends an action
  per state (cancel it with a cancellation id on the view's disappearance action);
  actions (`startScanning`, `connect`, `startMeasuring`) → `Effect`s returned from the
  reducer. The `.connected`-before-measure and never-exit-the-loop rules become reducer
  logic.
- **UIKit / MVC**: state → view-controller properties (or a presenter); observation → a
  stored `Task` started in `viewDidAppear`, cancelled in `viewDidDisappear`; actions →
  controller methods. No `.task`, so the stored-task lifecycle is mandatory.
- **VIPER / Clean / other**: put state in the entity/presenter, the observation in the
  interactor/service, actions as use-cases. The SDK contract is unchanged.

If the architecture isn't listed, map the same three roles into its idioms. When in
doubt about *what* to do, the contract governs; only the *where* is architecture-specific.

---

## Composability (any architecture)

When adding a capability to code that already observes the stream:

- Add the capability's **state**.
- Add/extend its **cases** in the single existing `switch` (or the TCA reducer's state
  handling, etc.).
- Add its **actions**.
- Honor **cross-capability cleanup** — some recipes require work in *other* capabilities'
  cases (e.g. `measure` cancels its speeds task in the non-measuring branches). Each
  recipe's "Composability" section spells out exactly what to add where.

Never add a second observation of `sessionStateStream()`.

---

## Verify

- The project builds.
- Live behavior (discovery, connection, measurement) needs a **real device** (no BLE on
  the Simulator), Bluetooth enabled, and a configured SDK with a valid API key. A build
  success confirms wiring; live results need hardware.
