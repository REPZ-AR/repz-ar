# Native Google Sign-In setup

This app now uses the native Google account chooser on Android/iOS and exchanges the Google tokens with Supabase.

## What changed
- Mobile (`android`/`ios`): native Google sign-in via `google_sign_in`
- Web: still uses Supabase OAuth redirect flow

## Required setup

### 1) Create Google OAuth client IDs
In Google Cloud Console, create:
- **Android OAuth client** for package `lk.repz_ar.repz` with your SHA-1/SHA-256 fingerprints
- **iOS OAuth client** for your iOS bundle identifier
- **Web OAuth client** if you also use Flutter web

### 2) Supabase Google provider
In Supabase Auth → Providers → Google:
- enable Google
- add the relevant client IDs/secrets expected by your project
- make sure the provider accepts the same Google project used by the mobile apps

### 3) Android
You typically need either:
- `google-services.json` from Firebase/Google services, or
- explicit server/web client configuration depending on your sign-in setup

For release builds, be sure your release SHA fingerprints are registered.

### 4) iOS
Add the reversed iOS client ID to `ios/Runner/Info.plist` under `CFBundleURLTypes`.
Example shape:

```xml
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleTypeRole</key>
    <string>Editor</string>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>com.googleusercontent.apps.YOUR_REVERSED_CLIENT_ID</string>
    </array>
  </dict>
</array>
```

### 5) Test checklist
- Tap **Continue with Google**
- Native account chooser appears instead of browser
- Choose account
- App receives Supabase session
- `avatar_url` is present on the signed-in user
- Canceling the chooser returns to login without crashing

## Notes
- The old custom browser callback (`lk.repz_ar.repz://login-callback`) is no longer needed for mobile if you fully migrate off browser OAuth.
- If native sign-in fails on device, missing client IDs or SHA fingerprints are the most common cause.

