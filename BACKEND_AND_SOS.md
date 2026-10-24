# Backend connection and SOS

Debug Android emulator builds default to `http://10.0.2.2:8000`; iOS simulator and web use `http://localhost:8000`. Authentication, chat, visitor, security tips and SOS use the configured backend origin. Physical devices must share the development machine's network:

```sh
flutter run --dart-define=API_BASE_URL=http://192.168.1.101:8000
flutter build apk --debug --dart-define=API_BASE_URL=http://192.168.1.101:8000
```

Replace the IP if the development machine's address changes. Release builds require an explicit HTTPS backend origin via `API_BASE_URL`. Failed login/registration requests no longer enter fake offline sessions. Explicit demo accounts cannot send real SOS or chat requests.

## SOS behavior

Hold continuously for four seconds. Release early, drag outside, cancel the touch or background the app to cancel. The same request ID is reused when retrying an uncertain network failure. The server records the authenticated sender's name and saved house/street (or linked landlord's address), never a client-supplied identity/location. Missing addresses are labeled, not fabricated.

The durable outbox sends high-priority FCM alarms to every registered device belonging to non-revoked users in that estate. It retries failures and expires undelivered alarms after ten minutes. Account changes transfer device ownership; logout unregisters the current device when reachable. Duplicate Android notifications share an alert tag; foreground alarms are deduplicated. Queued-device counts do not guarantee receipt.

Foreground alerts show identity and house location and play a repeating bundled siren until silenced. Android background notifications use the SOS sound channel. iOS background notifications use system sound and open the alarm screen on tapping. Notification permission, connectivity, device volume, DND and OS background restrictions still apply; Apple critical alerts and DND bypass are not requested. Sender, guards and caretaker can resolve an alert. SOS notifications use FCM, without mobile polling.

## Remaining release gaps / checks

- Test two physical phones: foreground, background, locked screen, denied notifications, mute/DND, offline sender and revoked account. No physical Android/iOS device is connected to this workspace.
- Verify Apple APNs credentials and signed Push Notifications provisioning on Xcode; entitlements/background mode are included in source.
- Replace Android release debug signing and example app identifiers for store release.
- Add secure session persistence and expiry/refresh handling; sessions currently live in memory.
- Finish remaining local-fixture gatehouse management/overview and profile settings controls. Visitor verification and chat have live services, while some overview UI still uses demo data.
