---
name: smartcoach-sdk
description: >-
  Integrate the PocketRadar SmartCoach iOS SDK into a Swift/SwiftUI app. Use whenever
  the user asks to set up or configure the SmartCoach SDK (API key, Bluetooth
  permission, configure() at launch) or to add SmartCoach device scanning, connecting,
  measurement streaming, radar settings (units, speed range, sensitivity), or
  session-state handling — whether editing an existing view
  model or scaffolding a new MVVM screen. Ensures the generated code follows the SDK's
  required call sequences and lifecycle instead of improvising the API.
---

# SmartCoach SDK integration

Adds SmartCoach SDK capabilities to a consumer's Swift app by editing their code. This
skill supplies the SDK-correct behavior; you supply the scaffolding and the UI.

## Ownership boundary

- **This skill owns** the SDK specifics: which APIs to call, in what order, the
  session-state observation, teardown, and error handling. Follow the recipes exactly
  for these — do NOT write SmartCoach API calls from memory.
- **You own** everything around them: the app's architecture, locating or creating the
  state container, building views, and matching the project's conventions and style.

## Contract vs. implementation

Each recipe states an **SDK contract** (architecture-neutral rules — the "Rules"
sections) plus an **MVVM reference implementation** (the Swift code). The contract holds
in any architecture (MVVM, MV, TCA, UIKit/MVC, VIPER). If the target app is MVVM, use
the reference code directly. If it is not, implement the same contract idiomatically —
`conventions.md` has a "Mapping the contract to other architectures" section. Never
paste the view-model code into an app that isn't MVVM.

## How to use

1. For the capability recipes, **always read `recipes/conventions.md` first.** It
   defines the shared view-model structure they build on.
2. Then read the recipe(s) for what the user wants:
   - **SDK setup / bootstrap** (API key, permissions, `configure()` at launch) →
     `recipes/configure.md` — standalone; does not use `conventions.md`. It prompts
     the user for their API key and NEVER hand-edits `project.pbxproj`/`Package.swift`
     (it gives Xcode click-path instructions instead).
   - **Device scanning** → `recipes/scan.md`
   - **Connect / disconnect** → `recipes/connect.md`
   - **Stream measurements** → `recipes/measure.md`
   - **Radar settings** (units, speed range, sensitivity) → `recipes/settings.md`
3. For a request spanning capabilities ("connect and measure", "a full scan→connect→
   measure screen"), apply the recipes in order into **one** view model — they share a
   single `startMonitoring()` switch by design (see each recipe's "Composability").
4. Apply into the state container the user names. For an abstract request ("build a
   screen that scans"), first scaffold it in the project's architecture and style, then
   apply the recipe(s).

Before writing any code, do `conventions.md` Step 1: **detect the app's architecture**
(don't assume MVVM) and **audit existing SmartCoach usage** (a partial or non-canonical
prior attempt must be adopted/refactored/reconciled, never duplicated alongside).

## Prerequisites (assumed by every capability recipe)

- The `SmartCoachSDK` package is added to the app.
- `SmartCoach.configure()` is called once at launch. If either is missing, apply
  `recipes/configure.md` first (or offer to) — SDK calls fail with `notConfigured`
  otherwise.

## Non-negotiable rules (all recipes)

- Every `SmartCoach` call is `@MainActor` and mostly `async` — the view model must be
  `@MainActor`. Never wrap property updates in `MainActor.run` inside it.
- Results arrive through `SmartCoach.sessionStateStream()`, not as return values.
- The session follows the radar: `.measuring` can appear without the app calling
  `startMeasuring()` (the radar's own trigger). Handle it; never treat it as an error.
- Session monitoring is one async `startMonitoring()` method driven by the owning
  view's `.task` modifier (structured cancellation — no stored task, no manual
  teardown). Only if the view model owns its lifecycle do you store the task, and then
  cancel it in the existing teardown hook — never in `deinit` (does not compile on a
  `@MainActor` type).
- **Never exit the observation loop on a state-carried error** — surface
  `.disconnected(error)` via the error property and keep iterating.
- **Compose, don't duplicate:** if the view model already observes the session stream,
  extend its existing `switch` — never add a second observation.
