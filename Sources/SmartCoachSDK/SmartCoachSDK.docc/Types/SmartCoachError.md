# SmartCoachError

## Declaration
```swift
public enum SmartCoachError: Error {
    case configuratiaonError(ConfigurationError)
    case apiError(APIError)
    case unknown(Error)
}
```

## Discussion
Top-level SDK error wrapper.

## See Also
- <doc:ConfigurationError>
- <doc:APIError>
