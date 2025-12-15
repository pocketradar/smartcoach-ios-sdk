# BluetoothError

## Declaration
```swift
public enum BluetoothError: Error {
    case unavailable(CBManagerState)
    case connectionFailed(Error?)
    case connectionAlreadyInProgress(UUID)
    case disconnectAlreadyInProgress(UUID)
    case discoverServicesFailed(Error)
    case disconnectFailure(Error)
    case writeFailure(Error)
    case discoverCharacteristicsFailure(Error)
    case duplicateCharacteristicNotification(CBUUID)
    case notificationFailure(Error)
}
```

## Discussion
Errors related to CoreBluetooth operations.
