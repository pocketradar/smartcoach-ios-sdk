
# Overview

The **SmartCoach iOS SDK** enables applications to interact with SmartCoach radar
devices for real-time speed measurement. This SDK is designed with modern Swift
Concurrency, providing async/await APIs, strong type safety, and actor-isolated
internal state.

The initial release focuses exclusively on **speed measurement**.

---

## Architecture

The SDK consists of three conceptual layers:

### 1. Public API (`SmartCoachSDK`)
Provides simple async methods for:

- Scanning
- Connecting
- Streaming speed measurements

### 2. Core Logic
Manages:

- Bluetooth state transitions
- Device selection
- Entitlement validation
- Error propagation

### 3. Bluetooth Integration
Wraps CoreBluetooth to provide a reliable and testable device communication layer.

---

## Workflow Summary

1. Configure the SDK  
2. Scan for nearby SmartCoach devices  
3. Connect to a specific device  
4. Subscribe to speed updates via an `AsyncSequence`  
5. Handle errors and disconnections gracefully  
