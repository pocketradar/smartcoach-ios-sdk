# FAQ

A collection of frequently asked questions about integrating the SmartCoach iOS SDK.

---

## Configuration

### **Q: Why must I call `SmartCoach.configure()` before using any SDK method?**

The SDK loads entitlement information (API key, bundle ID) from your app’s Info.plist.  
Until this configuration step succeeds, scanning, connecting, and measuring are not allowed.

If called prematurely, APIs will throw:

```
SmartCoachError.configuratiaonError(.notConfigured)
```

---

### **Q: Can I call configure() more than once?**

No. A second call throws:

```
ConfigurationError.alreadyConfigured
```

Configuration is intended to be performed once at application launch.

---

### **Q: Where do I put the SmartCoachAPIKey?**

Inside your app’s **Info.plist**:

```xml
<key>SmartCoachAPIKey</key>
<string>YOUR_API_KEY</string>
```

---

## Scanning

### **Q: Why is my scan returning an empty list?**

Possible reasons:

- Bluetooth permission not granted  
- Bluetooth is powered off  
- No SmartCoach devices in range  
- Entitlements do not allow scanning  
- The session state stream has not emitted `.scanning` yet  

---

### **Q: What does `autoConnect` actually do?**

`autoConnect` reconnects to **the last successfully connected device**, if detected during scanning.

It does **not** connect to:

- The first discovered device  
- All devices in range  
- Any device you've never manually connected to  

---

### **Q: Can the SDK connect to multiple devices?**

No — only **one active connection** is supported.

---

## Connection

### **Q: Why does connect() throw `RadarError.invalidSessionState`?**

This usually happens if:

- You are already connected to a device  
- A connection attempt is already in progress  
- Scanning was not started  
- The selected device isn’t from the active scan  
- The SDK is configured but not in the correct state  

---

### **Q: How do I know when my device is actually connected?**

Observe the session state transitions:

```
.connecting(radar)
→ .connected(radar)
```

Use:

```swift
for await state in try await SmartCoach.sessionStateStream() {
// Handle state changes
}
```

---

## Measuring

### **Q: Why does `startMeasuring()` throw invalidSessionState?**

This occurs when:

- The device is not fully connected  
- You call startMeasuring while scanning  
- The radar disconnected earlier  

---

### **Q: How do I stop receiving speed measurements?**

Call:

```swift
try await SmartCoach.stopMeasuring()
```

The measurement stream finishes automatically.

---

### **Q: Why did my measurement stream stop?**

Causes include:

- Device disconnected  
- Bluetooth error occurred  
- stopMeasuring() was called  
- The task consuming the stream was cancelled  

---

## Session State

### **Q: What is the difference between `currentSessionState()` and `sessionStateStream()`?**

- `currentSessionState()` provides a **snapshot** (synchronous)  
- `sessionStateStream()` provides a **live asynchronous stream of updates**

Before configuration, the snapshot returns:

```
.disconnected(ConfigurationError.notConfigured)
```

---

### **Q: Do I need to cancel the sessionStateStream()?**

No — it ends automatically when the consuming task is cancelled or deallocated.

---

## Permissions & Bluetooth

### **Q: Do I need `NSBluetoothPeripheralUsageDescription`?**

No.  
Your app acts as a BLE **central**, not a peripheral.

Only this key is required:

```xml
NSBluetoothAlwaysUsageDescription
```

---

### **Q: Why can’t I scan or connect in the background?**

iOS severely restricts background BLE scanning unless you register for specific background modes — which the SDK does not require.

Scanning should be performed in the foreground.

---

## Miscellaneous

### **Q: What unit are speed measurements returned in?**

Speeds are wrapped in:

```swift
Measurement<UnitSpeed>
```

Units are either:

- `.milesPerHour`
- `.kilometersPerHour`

---

### **Q: Does the SDK store user data?**

No.  
The SDK only stores the identifier of the last connected radar for AutoConnect convenience. No personal data is collected or transmitted.

---

