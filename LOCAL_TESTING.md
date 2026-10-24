# Local Android testing

The local backend is served by the `residence_backend` Docker container on port 8000.
For the current Wi-Fi network, use `http://192.168.1.101:8000` from the phone.
Keep the phone and development computer on the same network.

Build the local testing APK from `mobile/`:

```sh
flutter build apk --debug --dart-define=API_BASE_URL=http://192.168.1.101:8000
```

Debug builds permit HTTP for local testing. Release builds retain the HTTPS requirement.
If the computer's LAN address changes, rebuild with its new address.
A different backend origin requires signing in again; saved sessions are bound to their backend.

The local backend token generator was updated and its Gunicorn workers gracefully reloaded,
without restarting the migration entrypoint or changing database records. New passcodes have
one uppercase letter and digits in all other positions, at the estate's configured length.
Previously issued codes retain their original values.

## Estate settings synchronization

The app fetches `GET /api/v1/estates/mobile-settings` after session restoration/sign-in
and when returning to the foreground. A caretaker's saved code-length change queues
a silent estate-scoped `estate_settings_changed` FCM event. Foreground clients fetch
a fresh snapshot; background/offline clients refresh when they next open/resume.
There is no periodic polling timer. Repeated events during a request trigger one
follow-up fetch, so delayed events cannot overwrite newer settings with old values.

The last valid snapshot remains encrypted with the session while offline. Guard
screens observe the shared length notifier and update without signing out. Guards
confirm verification explicitly; longer codes remain enterable when the estate selects a shorter length. The
verifier initially shows exactly the configured number of boxes, adds boxes as
input exceeds that length, and wraps longer input onto additional rows. Clearing
the input returns to the configured count.

## SOS delivery timing

The urgent delivery window is 40 seconds from the server's original SOS timestamp.
Foreground and background devices qualify equally. The backend puts the remaining
window into FCM/APNs expiry and the app checks the original timestamp before playing.
Notification taps open details without starting a fresh siren. Sirens are capped at
30 seconds by native playback safeguards and notification audio is shorter than 30 seconds.

FCM acceptance is not treated as device receipt. The foreground/background handler
acknowledges receipt using the signed-in estate session and this phone's FCM token.
Unacknowledged deliveries become normal SOS reports after a 10-second receipt grace
period beyond the delivery deadline. Reports include the sender, house, original time,
and status, and can remain queued for up to 28 days; they never use the alarm channel.
No database migration is required: delivery phases use the existing SOS outbox.
