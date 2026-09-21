# Device Settings

Change the radar's measurement unit, speed range, and sensitivity — and know when the radar has applied them.

## Overview

Three settings can be changed on a connected radar. Each call sends the command, waits
for the radar to confirm it, and only then returns; if the radar rejects the change or
does not answer within a few seconds the call throws
``SmartCoachErrorCode/commandFailed``. The connection is never affected by a failed
setting.

| Setting | API | Value | Devices |
|---|---|---|---|
| Measurement unit | ``SmartCoach/setMeasurementUnit(_:)`` | ``RadarMeasurementUnit/mph`` or ``RadarMeasurementUnit/kph`` | SmartCoach 1 and 2 |
| Speed range | ``SmartCoach/setSpeedRange(_:)`` | ``RadarSpeedRange`` | SmartCoach 1 and 2 |
| Sensitivity | ``SmartCoach/setSensitivity(_:)`` | ``RadarSensitivity`` | SmartCoach 1 only |

All three require the session to be ``SmartCoachSessionState/connected(_:)`` or
``SmartCoachSessionState/measuring(_:)``; otherwise they throw
``SmartCoachErrorCode/invalidSessionState``.

## Measurement Unit

```swift
try await SmartCoach.setMeasurementUnit(.kph)
```

Readings from ``SmartCoach/startMeasuring()`` are delivered in the radar's unit, and the
connected device's ``SmartCoachRadar/measurementUnit`` updates on the session state stream
once the radar confirms. Passing ``RadarMeasurementUnit/unknown`` throws
``SmartCoachErrorCode/featureNotSupported``.

## Speed Range

The radar ignores readings outside the window. Limits are the hardware's: 25 to 130 mph.

```swift
// Whole mph:
if let range = RadarSpeedRange(lowMPH: 40, highMPH: 100) {
    try await SmartCoach.setSpeedRange(range)
}

// Or from measurements in any unit (rounded to whole mph):
let low = Measurement(value: 60, unit: UnitSpeed.kilometersPerHour)
let high = Measurement(value: 160, unit: UnitSpeed.kilometersPerHour)
if let range = RadarSpeedRange(low: low, high: high) {
    try await SmartCoach.setSpeedRange(range)
}
```

Both initializers return `nil` unless `25 ≤ low ≤ high ≤ 130` mph, so an invalid value is
caught before anything is sent. ``RadarSpeedRange/full`` is the radar's default.

## Sensitivity

SmartCoach 1 radars accept a detection sensitivity from 1 (least sensitive) to 10 (most
sensitive, the default). Lower levels reject weaker signals, which helps in noisy
environments at the cost of missing softer throws.

```swift
if let sensitivity = RadarSensitivity(level: 7) {
    do {
        try await SmartCoach.setSensitivity(sensitivity)
    } catch SmartCoachError.featureNotSupported {
        // SmartCoach 2 — hide the control for device.deviceType == .smartCoach2
    }
}
```

## Settings Reset on Every Connection

Radars return to the full speed range and default sensitivity each time they connect,
and keep whatever unit they were last set to. If your app has preferred values, re-apply
them when the session reaches `.connected` — including after an auto-reconnect, which
also lands in `.connected`:

```swift
for await state in try await SmartCoach.sessionStateStream() {
    if case .connected = state {
        try? await SmartCoach.setMeasurementUnit(preferredUnit)
        if let range = preferredRange {
            try? await SmartCoach.setSpeedRange(range)
        }
    }
}
```

## Handling Failures

```swift
do {
    try await SmartCoach.setSpeedRange(range)
} catch SmartCoachError.commandFailed {
    // Rejected or not acknowledged — the connection is fine; offer a retry.
} catch SmartCoachError.invalidSessionState {
    // Not connected yet.
} catch SmartCoachError.featureNotSupported {
    // This radar doesn't support the setting (sensitivity on SmartCoach 2).
}
```

Settings calls are serialized inside the SDK, so awaiting them one after another is safe;
avoid firing several concurrently from the UI if their order matters.

## See Also

- ``SmartCoach/setMeasurementUnit(_:)``
- ``SmartCoach/setSpeedRange(_:)``
- ``SmartCoach/setSensitivity(_:)``
- ``RadarSpeedRange``
- ``RadarSensitivity``
- <doc:ErrorHandling>
