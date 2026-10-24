# Authentication and chat push checks

Authentication uses a shared, centered, scrollable layout with email/password autofill,
inline validation, visible password controls, explicit estate identity, and landlord
invitation guidance. Google sign-in and fabricated security claims were removed because
those flows were not implemented. First-login password replacement remains mandatory.

Chat push recipients include all registered devices of eligible users in the same estate,
plus legacy single-token accounts, with duplicate tokens removed. Opening another
household's thread never grants notification access. Existing room-presence suppression
continues to skip recipients actively viewing the thread.

Messages include a visible notification and thread deep-link data. Android chat delivery
uses the `residence_chat` high-importance channel and an explicit 28-day transport TTL.
SOS retains its shorter 10-minute TTL. A disconnected phone receives eligible pending
notifications after it reconnects; this is not an immediate delivery guarantee.
The app refreshes device registration on foreground events without polling. Missing
FCM credentials are reported as failures outside development.

Verification performed on 2026-10-23:
- 33 isolated backend chat, FCM payload/configuration, and SOS tests passed. FCM sends
  were mocked; tests did not send messages to real users.
- 15 mobile tests passed and Flutter analysis reported no issues.
- Local service-account configuration is present and its project matches Android.
- Auth layouts checked at 320px with 1.6x text in light and dark mode; actual widget
  previews rendered and inspected.
- No Android device was attached. Lock-screen delivery and notification tap routing
  still require a device test after deploying the backend source changes and installing
  the updated app. Check notification permissions, send a chat from another account,
  background the recipient app, then repeat with recipient connectivity disabled and
  restored. Confirm the notification opens the correct authorized thread.

FCM acceptance is not proof that a notification was displayed. OS force-stop, denied
permissions, provider outages, and expired/stale device tokens can prevent delivery.
Chat currently dispatches pushes in request background tasks rather than a durable push
outbox; server crashes before dispatch remain a reliability limitation.

Auth appearance update: version 1.0.2 uses the web dashboard’s forest primary
(#265947), warm background (#f9f8f6), and bundled Inter/Outfit fonts. Both sign-in
and registration place fields directly on the page with no form card.

Version 1.0.3 removes introductory auth headings and estate-ID footer guidance.
Registration has no estate-ID field: the backend resolves it from the valid host
invitation, and the app uses the returned estate ID for automatic sign-in.
The matching backend source must be deployed with this version; no database
migration is required for this change. Existing estate-scoped clients remain
compatible. Displayed role wording is Host; API role identifiers are unchanged.

Version 1.0.4 adds encrypted device session storage and startup restoration. No
password is saved. The token, profile and estate identity are restored only while
both the signed token expiry and the 60-day local maximum remain valid. Logout
clears the saved session and attempts server-side token revocation. A normal
estate login issues a 60-day token; first-login password-change tokens remain
30 minutes. Previously issued tokens retain their original expiry; sign in once
after updating to obtain the new lifetime. Platform-owner token policy is unchanged.
Android backup of the encrypted session is disabled; iOS Keychain capability is
included. Android/iOS physical restart testing still needs a connected device.

The mobile bottom navigation now includes Chat, and the home floating action opens
New Pass. New visitor, departure and invitation codes contain uppercase letters and
numbers. Existing codes are accepted until their normal expiry. SOS excludes the
sender's account across every registered device, and skips legacy queued sender
records; foreground handlers also ignore self-originated alarms.

The directory tracker is collapsed at rest, expands for an import while work is
pending, hides after success, and shows a compact flag for failed jobs. Saved-file
controls are only loaded when import history is explicitly opened. Backend and
Admin source updates need deployment with this APK. These changes need no new
schema migration, but all previously required migrations must already be applied.

Version 1.0.5 adds server-backed editing for name, email, phone, house number and
street. Profile details are shown directly on the profile screen. Email changes
require the current password, rotate the token and retain its original expiry.
Estate, host, RFID and role assignments cannot be changed through self-service.
Host address changes also update linked household addresses and unused invitations,
without rewriting historical access records. Backend deployment is required for
GET/PATCH users/me/profile; this update adds no schema migration.

New passcodes have exactly one letter, with all remaining characters numeric at
the estate's configured length (six characters = five digits plus one letter).
An exact 90/10 per-code split would require ten characters. Newly generated
invitation codes use eight digits and one letter, without a fixed REG prefix.
Existing issued codes remain valid. Recent activity displays the corresponding
entry or departure code. The expired-token auto-refresh widget has been removed.

Biometric app lock is off by default and stored separately per account in secure
storage. Enabling requires enrolled biometrics and a successful native prompt;
cancellation, denied permission or unavailable hardware never marks it enabled.
Opted-in accounts are locked on app restart and after backgrounding. Unlock can
use native biometrics or the device credential; disabling also requires native
authentication. Android biometric/fingerprint declarations, FragmentActivity and
AppCompat themes are configured. iOS includes the Face ID purpose string.
Physical Android/iOS biometric enrollment, permission denial, background/resume,
and device-passcode fallback still need hardware verification; automated tests
exercise the service and screen-gating behavior with simulated native results.
