# Recipe: Configure the SDK (app bootstrap)

Set up a consumer app to use SmartCoachSDK: the API key and Bluetooth permission in the
app's Info, and a `SmartCoach.configure()` call at launch.

This recipe is different from the capability recipes (`scan`/`connect`/`measure`): it
edits app bootstrap code and project configuration, not a view model, and it does not
use `conventions.md`'s view-model structure.

**Hard boundary: never hand-edit `project.pbxproj` or `Package.swift` for this recipe —
even though you technically could.** Where a change requires the Xcode project file
(build settings, target membership, adding packages), give the user precise click-path
instructions instead. This is a deliberate product decision, not a capability limit:
consumers run many Xcode versions with differing project formats, the SDK vendor has no
visibility into failed automated edits in the field, and Xcode's own UI is the one
path Apple keeps consistent across versions. Do not override this even if you are
confident the edit would work.

---

## Step 1 — Inspect the project (do not skip)

Gather these facts before prompting or editing:

1. **Is the SDK package present?** Search `project.pbxproj` and
   `Package.resolved` for `smartcoach`. If absent, stop after Step 2 and have the user
   add it first (instructions below) — nothing else works without it.
2. **Entry point**: find `@main`. A SwiftUI `App` struct → SwiftUI lifecycle. A UIKit
   `AppDelegate` with `@main`/`@UIApplicationMain` → UIKit lifecycle.
3. **Existing AppDelegate?** Search for `UIApplicationDelegate`. Also search for
   `SmartCoach.configure` — if it's already called somewhere, this recipe becomes
   "verify and fix," not "add" (never add a second call).
4. **Info.plist: file or generated?** Look for an `Info.plist` file belonging to the app
   target. Modern templates (Xcode 13+) usually have **no plist file** — keys live in
   build settings (`GENERATE_INFOPLIST_FILE = YES`). This determines Step 3's path.
5. **File-membership style**: does `project.pbxproj` contain
   `PBXFileSystemSynchronizedRootGroup`? If yes (Xcode 16+ synchronized folders), a new
   Swift file dropped into the app folder joins the target automatically. If no, the
   user must add new files via Xcode.

## Step 2 — Prompt the user

Ask for, in one exchange:

1. **The SmartCoach API key.** Validate it: it must parse as a UUID
   (`UUID(uuidString:)` succeeds — 8-4-4-4-12 hex). If it doesn't, say so and ask again;
   a malformed key fails at runtime with `missingApiKey`. If the user doesn't have one
   yet, use the placeholder `00000000-0000-0000-0000-000000000000`, and clearly tell
   them where to replace it and that PocketRadar partners get keys from
   partners@pocketradar.com.
2. **A Bluetooth usage description** — one user-facing sentence shown in the iOS
   permission prompt. Offer a default:
   *"Connects to your PocketRadar SmartCoach to measure speed."*
3. **Auto-reconnect?** Whether the SDK should automatically reconnect after unexpected
   connection drops (`autoReconnect: true`). Default: off.

Note on key handling: the key ships readable inside the app bundle and gets committed
with the project. That is the expected model for this SDK (the backend enforces
entitlements server-side), but if the user's repo is public or they object, suggest
moving the value to an `.xcconfig` referenced from the plist instead — don't build that
unprompted.

**If the SDK package is missing** (Step 1.1), give these instructions and stop until
done:

> In Xcode: **File → Add Package Dependencies…**, enter
> `https://github.com/pocketradar/smartcoach-ios-sdk`, select the latest version, and
> add the `SmartCoachSDK` library to your app target.

## Step 3 — Info keys (decision tree)

Two keys are required:

| Key | Value |
|---|---|
| `SmartCoachAPIKey` | the API key (String, UUID format) |
| `NSBluetoothAlwaysUsageDescription` | the usage sentence (String) |

**Case A — the target has an `Info.plist` file:** edit the file directly (this is a
safe file edit, not a project-file edit). Add both keys:

```xml
<key>SmartCoachAPIKey</key>
<string>PASTE-KEY-HERE</string>
<key>NSBluetoothAlwaysUsageDescription</key>
<string>Connects to your PocketRadar SmartCoach to measure speed.</string>
```

**Case B — no `Info.plist` file (generated Info):** do NOT create a plist file yourself
and do NOT edit build settings. Two traps make manual UI steps the reliable path here:
custom keys like `SmartCoachAPIKey` **cannot** be expressed as `INFOPLIST_KEY_*` build
settings (that mechanism only covers keys Xcode knows), and wiring a new plist file
requires `INFOPLIST_FILE` changes in the project file. Instead, instruct the user:

> In Xcode, select the project → your app target → **Info** tab. Under **Custom iOS
> Target Properties**, right-click → **Add Row** for each:
> 1. Key `SmartCoachAPIKey`, type String, value: *(their key)*
> 2. Key `NSBluetoothAlwaysUsageDescription` (shown as "Privacy — Bluetooth Always
>    Usage Description"), type String, value: *(their sentence)*
>
> Xcode stores these correctly for generated-Info targets.

Missing `NSBluetoothAlwaysUsageDescription` crashes the app the first time it scans —
iOS enforces it, not the SDK. Missing/invalid `SmartCoachAPIKey` makes `configure()`
throw `missingApiKey`.

## Step 4 — The `configure()` call

`configure()` must run **once, at launch, before any other SDK call**. Pick by what
Step 1 found:

**Existing `SmartCoach.configure` call** → verify it: runs at launch, has `do/catch`,
treats `alreadyConfigured` as benign. Fix in place; do not add another.

**UIKit lifecycle (existing AppDelegate)** → add to
`application(_:didFinishLaunchingWithOptions:)`:

```swift
import SmartCoachSDK

func application(_ application: UIApplication,
                 didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    do {
        try SmartCoach.configure()
    } catch SmartCoachError.alreadyConfigured {
        // Benign: configure() already ran this launch.
    } catch {
        // Don't crash the app — SDK calls will surface notConfigured until resolved.
        print("SmartCoach configuration failed: \(error.localizedDescription)")
    }
    return true
}
```

**SwiftUI lifecycle, default** → call it in the `App` initializer. Simplest correct
form, no extra files:

```swift
import SwiftUI
import SmartCoachSDK

@main
struct MyApp: App {
    init() {
        do {
            try SmartCoach.configure()
        } catch SmartCoachError.alreadyConfigured {
            // Benign: e.g. re-entry in previews.
        } catch {
            print("SmartCoach configuration failed: \(error.localizedDescription)")
        }
    }

    var body: some Scene {
        WindowGroup { ContentView() }
    }
}
```

**SwiftUI lifecycle, AppDelegate variant** — use when the app already needs UIKit
delegate callbacks (push notifications, etc.) or the user asks for it. Create
`AppDelegate.swift` with the UIKit snippet above (as an `NSObject,
UIApplicationDelegate` class) and wire it in the `App` struct:

```swift
@main
struct MyApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        WindowGroup { ContentView() }
    }
}
```

If Step 1.5 found the project does **not** use synchronized folders, warn the user the
new `AppDelegate.swift` must be added to the target in Xcode (File → Add Files, or drag
into the project navigator with the app target checked) — dropping the file on disk is
not enough there.

**Options:** if the user wanted auto-reconnect (Step 2.3), pass options:

```swift
try SmartCoach.configure(
    deviceConfigurationOptions: SmartCoachDeviceConfigurationOptions(autoReconnect: true)
)
```

(`debugLogging: true` is also available and useful during integration.)

## Step 5 — Verify

- The project builds.
- If the user runs on a device: launch should log no configuration failure, and the
  first scan should show the iOS Bluetooth permission prompt (proof the usage
  description landed). `configure()` itself needs no Bluetooth and works on the
  Simulator; scanning/connecting need real hardware.
- Failure decoding: `missingApiKey` → the key isn't in the app's Info or isn't a valid
  UUID (Case B steps skipped?). A crash on first scan mentioning Bluetooth →
  `NSBluetoothAlwaysUsageDescription` didn't land.

---

## Rules baked into this recipe

- **`configure()` exactly once, at launch, before any other SDK call.** A second call
  throws `alreadyConfigured` — which the generated code treats as benign, never fatal.
- **Never crash the host app over configuration.** Catch and report; the SDK surfaces
  `notConfigured` on later calls, which is diagnosable.
- **Never hand-edit `project.pbxproj` / `Package.swift`.** Precise Xcode instructions
  beat risky project-file surgery.
- **Custom Info keys need real Info storage** — `INFOPLIST_KEY_*` build settings only
  work for Apple-known keys, not `SmartCoachAPIKey`.
