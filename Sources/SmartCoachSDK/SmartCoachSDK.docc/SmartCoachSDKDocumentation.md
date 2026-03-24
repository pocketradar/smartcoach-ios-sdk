# ``SmartCoachSDKDocumentation``

@Metadata {
    @DisplayName("SmartCoachSDK")
}

A powerful Swift SDK for integrating Pocket Radar's Smart Coach devices into your own applications.

## Overview

SmartCoachSDK provides a simple yet powerful interface to connect, communicate, and receive real-time measurement data from SmartCoach radar devices via Bluetooth. The SDK handles all the complexity of device discovery, connection management, and data streaming, allowing you to focus on building great user experiences.

### Key Features

- **Easy Configuration**: One-line SDK initialization with sensible defaults
- **Device Discovery**: Automatic Bluetooth scanning and device pairing
- **Real-Time Measurements**: Stream measurement data using modern Swift concurrency
- **State Management**: Reactive session state tracking with AsyncStream
- **Auto-Reconnect**: Optional automatic reconnection to previously paired devices and unintended disconnects
- **Comprehensive Error Handling**: Detailed error codes for every scenario

## Topics

### Getting Started

- <doc:GettingStarted>
- <doc:Configuration>
- <doc:ErrorHandling>

### Tutorials

- <doc:ConnectingYourFirstDevice>
- <doc:StreamingMeasurementData>

### Core APIs

- ``SmartCoach``
- ``SmartCoachDeviceConfigurationOptions``
- ``SmartCoachSessionState``
- ``MeasurementData``

### Device Management

- ``SmartCoachRadar``
- <doc:DeviceDiscovery>
- <doc:ConnectionManagement>

### Error Handling

- ``SmartCoachError``
- ``SmartCoachErrorCode``
- ``SmartCoachErrorMatcher``
- <doc:CommonErrors>

### Advanced Topics

- <doc:SessionStateManagement>
- <doc:AutoReconnect>
- <doc:BestPractices>
