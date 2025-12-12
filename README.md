# SmartCoach iOS SDK

The **SmartCoach iOS SDK** provides a modern, Swift-first interface for
discovering, connecting to, and receiving live speed measurements from
SmartCoach radar devices on iOS. The SDK exposes a clean async/await API,
robust Bluetooth lifecycle management, and a unified error model suitable for
partner integration.

This repository is currently under private development and will be made public
once documentation and the initial release are complete.

---

## Overview

SmartCoach is a next-generation radar platform designed for accurate and
responsive speed measurement in sports applications. The SmartCoach iOS SDK
provides the tools required to integrate SmartCoach device data into native
iOS applications, including:

- Device scanning and discovery  
- Bluetooth connection and state management  
- Real-time radar speed streaming  
- Configuration and entitlement validation  
- Unified error handling via `SmartCoachError`  
- Async/await APIs optimized for Swift Concurrency  
- Safe actor-isolated internal state management  

This SDK currently focuses **exclusively on real-time speed measurement**.  
Additional device capabilities and advanced features may be added in future
releases.

---

## Features (Initial Release Scope)

### Core Device Integration
- Scan for SmartCoach devices using CoreBluetooth
- Connect and disconnect from a device
- Monitor device state changes (powered on/off, resetting, unauthorized, etc.)
- Automatically propagate connection errors through async APIs

### Speed Measurements
- Subscribe to real-time radar speed updates
- Receive structured measurement events
- Actor-isolated streaming to ensure thread safety
- Lightweight broadcaster for low-latency data delivery

### Configuration
- Load SmartCoachOptions (API key, bundle ID, partner ID, etc.)
- Initialize SDK configuration with entitlements
- Local feature validation to enable/disable radar operations

### Developer Experience
- Simple async/await API surface
- All public types fully `Sendable`
- Clean error categories (`SmartCoachError`)
- Designed for integration in modern architectures (e.g., TCA)

---

## Installation (Coming Soon)

When the SDK becomes public, it will be installable using Swift Package Manager:

```text
https://github.com/pocketradar/smartcoach-ios-sdk
