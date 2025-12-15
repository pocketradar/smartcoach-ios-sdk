# SmartCoachSessionState

## Declaration
```swift
public enum SmartCoachSessionState: Sendable {
    case disconnected(Error?)
    case scanning([any SmartCoachRadar])
    case connecting(any SmartCoachRadar)
    case connected(any SmartCoachRadar)
    case measuring(any SmartCoachRadar)
}
```

## Discussion
Represents the session lifecycle of the SmartCoach SDK.

## See Also
- <doc:SmartCoachRadar>
- <doc:MeasurementData>
