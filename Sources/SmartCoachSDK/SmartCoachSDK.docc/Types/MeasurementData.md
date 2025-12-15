# MeasurementData

## Declaration
```swift
public struct MeasurementData: Equatable, Sendable {
    public let measurement: Measurement<UnitSpeed>
    public let macAddress: String?
}
```

## Discussion
Represents a single radar speed measurement emitted during measurement mode.

## See Also
- <doc:Measuring>
- <doc:SmartCoachRadar>
- <doc:RadarMeasurementUnit>
