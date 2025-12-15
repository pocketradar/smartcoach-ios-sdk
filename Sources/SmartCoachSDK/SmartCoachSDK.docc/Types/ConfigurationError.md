# ConfigurationError

## Declaration
```swift
public enum ConfigurationError: Sendable, Error {
    case alreadyConfigured
    case notConfigured
    case missingApiKey
    case invalidBundleId
    case invlaidConfiguration
}
```

## Discussion
Errors thrown during SmartCoach SDK configuration.
