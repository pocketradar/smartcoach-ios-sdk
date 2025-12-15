# FeatureType

## Declaration
```swift
public enum FeatureType: String, Codable, Sendable, Hashable {
    case connect
    case scan
    case measurement
    case directionality
    case interferenceSuppression = "interference_suppression"
}
```

## Discussion
Represents capability flags available in the SDK features.
