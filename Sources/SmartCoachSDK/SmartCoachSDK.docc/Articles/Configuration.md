# Configuration

Before interacting with SmartCoach radar devices, your application must configure
the SDK once at application launch. Configuration initializes internal state,
reads required entitlement values from the app bundle, validates them, and
prepares the SDK for all subsequent operations.

The SDK **must be configured exactly once** and cannot be reconfigured at runtime.

---

## Required Info.plist Keys

The SmartCoach SDK relies on Bluetooth Low Energy (BLE) to discover and connect
to SmartCoach radar devices. To comply with iOS privacy requirements, your app
must include the following usage description keys in **Info.plist**:

### 1. Bluetooth Always Usage (Required)

```xml
<key>NSBluetoothAlwaysUsageDescription</key>
<string>This app uses Bluetooth to connect to SmartCoach radar devices.</string>
```

This is the **primary requirement**.  
It enables your app to perform BLE scanning and connections.

### 2. SmartCoach API Key (Required)

```xml
<key>SmartCoachAPIKey</key>
<string>YOUR_API_KEY_HERE</string>
```

This is provided by Pocket Radar and is required for entitlement validation.

### Keys You Do *Not* Need

You **do not** need:

```xml
NSBluetoothPeripheralUsageDescription
```

This key is only required when your application advertises itself as a Bluetooth
**peripheral**—for example, when other devices connect *to your app*.

The SmartCoach SDK only performs **central**-side BLE operations (scanning and
connecting to external hardware), so this key is unnecessary.

---

## How Configuration Works

The SDK obtains its configuration from:

- `SmartCoachAPIKey` in **Info.plist**  
- `Bundle.main.bundleIdentifier` (your app’s bundle ID)

It then constructs:

```swift
struct SmartCoachOptions: Sendable, Equatable {
    let apiKey: String
    let bundleId: String
}
```

Resolution is performed internally via:

```swift
let options = try SmartCoachOptions.resolve()
```

---

## Calling `SmartCoach.configure()`

Configuration must occur once during app launch:

```swift
class AppDelegate: NSObject, UIApplicationDelegate {

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: 
                                [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        do {
            try SmartCoach.configure()
        } catch {
            print(error.localizedDescription)
        }
        return true
    }
}
```

SwiftUI integration:

```swift
@main
struct SmartCoachSDKApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        WindowGroup {
            MainView()
        }
    }
}
```

## Observing Session State Before and After Configuration

The SmartCoach SDK exposes device and connection progress through
`SmartCoachSessionState`, which updates as scanning, connecting, and measuring
occur.

```swift
public enum SmartCoachSessionState: Sendable {
    case disconnected(Error?)
    case scanning([any SmartCoachRadar])
    case connecting(any SmartCoachRadar)
    case connected(any SmartCoachRadar)
    case measuring(any SmartCoachRadar)
}
```

There are two ways to access this state:

---

### 1. `currentSessionState()` — Safe to Call Before Configuration

You may call:

```swift
let state = SmartCoach.currentSessionState()
```

**before** calling `SmartCoach.configure()`.

In this case, it will always return:

```swift
.disconnected(ConfigurationError.notConfigured)
```

This is useful for:

- Initial UI setup  
- Checking readiness before launching async streams  
- Avoiding early async/await requirements  

---

### 2. `sessionStateStream()` — Requires Successful Configuration

You must call `SmartCoach.configure()` **before** subscribing to the state
stream:

```swift
let stream = try await SmartCoach.sessionStateStream()
```

If you attempt to call this prior to configuration, the SDK throws:

```swift
SmartCoachError.configuratiaonError(.notConfigured)
```

The state stream becomes the primary mechanism for:

- Receiving discovered devices during scanning  
- Monitoring connection attempts  
- Receiving measurement state transitions  

A full walkthrough of session state usage appears in <doc:Scanning>.

---

## Configuration Rules

### 1. Must Be Called Once

```swift
ConfigurationError.alreadyConfigured
```

is thrown if `configure()` is called more than once.

### 2. Must Occur Before Any SDK Operation

If scanning or connecting is attempted before configuration:

```swift
ConfigurationError.notConfigured
```

will be thrown.

### 3. No Runtime Reconfiguration

Because values are loaded from the bundle and Info.plist,
the SDK **does not support reconfiguration** during app execution.

### 4. Missing or Invalid Keys Throw Errors

- `ConfigurationError.missingApiKey`  
- `ConfigurationError.invalidBundleId`  
- `ConfigurationError.invlaidConfiguration`  

---

## Configuration Error Model

Errors originate from:

```swift
public enum SmartCoachError: Error {
    case configuratiaonError(ConfigurationError)
    case apiError(APIError)
    case unknown(Error)
}
```




Example handling:

```swift
catch SmartCoachError.configuratiaonError(let configError) {
    print("Configuration failed:", configError.localizedDescription)
}
```

---

## Summary

After reviewing this section, you should understand:

1. Which Info.plist keys are required  
2. Why only *central* Bluetooth permissions are needed  
3. How configuration is resolved automatically at runtime  
4. Why reconfiguration is not supported  
5. How to properly initialize the SDK at app launch  

Proceed to <doc:Scanning> to discover SmartCoach radar devices.
