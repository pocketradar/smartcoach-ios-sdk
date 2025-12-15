# APIError

## Declaration
```swift
public enum APIError: Error, Sendable {
    case invalidRequest
    case invalidResponseType
    case invalidURL(String)
    case jsonDecoderError(Error)
    case responseHTTPFailure(APIResponseFailureStatusCode)
    case networkError(Error)
    case unexpected(NSError)
    case unknown(Error)
}
```

## Discussion
Represents HTTP and decoding failures.
