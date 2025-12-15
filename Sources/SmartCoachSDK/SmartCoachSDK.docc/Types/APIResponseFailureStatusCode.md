# APIResponseFailureStatusCode

## Declaration
```swift
public enum APIResponseFailureStatusCode: Equatable, CustomStringConvertible, Sendable {
    case badRequest_400
    case unauthorized_401
    case forbidden_403
    case notFound_404
    case internalServerError_500
    case notImplemented_501
    case unexpected(Int)
}
```

## Discussion
Represents specific HTTP failure codes.
