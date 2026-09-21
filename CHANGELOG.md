# Changelog

All notable changes to the SmartCoach iOS SDK. The SDK is in beta; APIs may change between releases.

## 0.2.0-beta.1

### Behaviour changes

- **The session state now follows the radar.** When measuring is started or stopped from
  the radar itself, `SmartCoachSessionState` moves between `.connected` and `.measuring`
  exactly as it does for `startMeasuring()` / `stopMeasuring()`, and an active measurement
  stream completes when the radar stops. Apps that switch exhaustively over the session
  state need no code change but should expect `.measuring` without having asked for it.
- **`SmartCoach.startMeasuring()` is valid from `.measuring`.** It sends nothing and returns
  a stream of the readings already in progress. It still throws `invalidSessionState` from
  `.connecting`, `.reconnecting`, `.scanning`, and `.disconnected`.
- **Devices re-emit more often.** `.connected(device)` / `.measuring(device)` are re-emitted
  when the radar's reported measuring state changes, and `AnySmartCoachRadar` equality now
  includes `measurementState`.
- **A failed Bluetooth connect attempt is retried once** (0.2 s) inside `connect(to:)`
  before `failedToConnect` is reported, and a single failed attempt no longer resets the
  SDK's Bluetooth stack.
- **Connection readiness is bounded.** If a radar accepts the Bluetooth link but never
  completes authentication, the session now fails with `failedToConnect` after 10 s instead
  of staying in `.connecting`.

### Added

- **SmartCoach 2 support.** Discovery, connection (customer-ID authentication), measuring,
  stored-pairing auto-connect, unit changes, and speed range on the new radar architecture,
  including the version-1 velocity packet.
- `SmartCoach.setMeasurementUnit(_:)`, `SmartCoach.setSpeedRange(_:)`,
  `SmartCoach.setSensitivity(_:)` with validated value types `RadarSpeedRange` and
  `RadarSensitivity`. Calls wait for the radar's acknowledgement.
- `SmartCoachErrorCode.commandFailed` (4009) and matcher `SmartCoachError.commandFailed`,
  thrown when a settings command is rejected or not acknowledged.
- `SmartCoachRadar.measurementState` (`RadarMeasurementState`): the radar's own
  idle/measuring report. Conformers that predate it default to `.unknown`.
- `MeasurementData.direction` (`RadarDirection`), `.velocityType` (`RadarVelocityType`),
  and `.tilt` (`RadarTilt?`). Populated by SmartCoach 2 radars whose firmware reports them;
  SmartCoach 1 reports `.unknown` / `.generic` / `nil`. The two-argument initializer is
  unchanged.
- Firmware and hardware revision are recorded in connection diagnostics.
- DocC: new *Device Settings* article; agent-skill recipe `settings.md`.

### Requirements

Unchanged: iOS 18.0+, Xcode 26 (Swift tools 6.2).

## 0.1.0-beta.7

- Minor bug fixes; Claude agent skills added (see README).
