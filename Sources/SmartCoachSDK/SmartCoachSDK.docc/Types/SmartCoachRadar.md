# SmartCoachRadar

## Declaration
```swift
public protocol SmartCoachRadar: Sendable, Identifiable {
    var id: String { get }
    var rssi: Int { get }
    var deviceType: DeviceType { get }
    var macAddress: String? { get }
    var measurementUnit: RadarMeasurementUnit { get }
    var batteryLevel: RadarBatteryLevel { get }
    var measurementState: RadarMeasurementState { get }
    var powerSource: RadarPowerSource { get }
}
```

## Discussion
Represents a SmartCoach radar device discovered during BLE scanning.

## See Also
- <doc:DeviceType>
- <doc:RadarBatteryLevel>
- <doc:RadarMeasurementUnit>
