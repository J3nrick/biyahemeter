# Release checklist

App id / bundle id: `ph.biyahemeter.app` (Android `applicationId`, iOS
`PRODUCT_BUNDLE_IDENTIFIER`). App Group: `group.ph.biyahemeter.app`.
Neither can change after the first store upload.

## Android: upload keystore (one time)

The release build is signed with the key in `android/key.properties`. That file
and every `*.jks` / `*.keystore` are gitignored (`android/.gitignore`). **Never
commit them.** Without `key.properties`, release builds fall back to debug keys,
and the Play Console rejects those.

1. Create the keystore outside the repo. `keytool` ships with the JDK; run
   `flutter doctor -v` to find the Java binary path Flutter uses.

   ```bash
   keytool -genkey -v -keystore ~/biyahemeter-upload.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```

2. Create `android/key.properties`:

   ```properties
   storePassword=<keystore password>
   keyPassword=<key password>
   keyAlias=upload
   storeFile=C:/Users/<you>/biyahemeter-upload.jks
   ```

   `storeFile` is resolved relative to `android/app/`, so use an absolute
   path (forward slashes work on Windows).

3. Back up the `.jks` file and both passwords somewhere safe, such as a
   password manager. Enrol in Play App Signing when you create the app in the
   Play Console. Then a lost upload key can be reset, but only Google holds the
   real signing key.

4. Build: `flutter build appbundle --release` →
   `build/app/outputs/bundle/release/app-release.aab`.

Bump `version:` in `pubspec.yaml` (the `+N` build number must increase) for
every upload.

## Android permissions

`ACCESS_BACKGROUND_LOCATION` is not requested. Screen-off metering runs in
geolocator's location foreground service (`FOREGROUND_SERVICE_LOCATION`) with
the ongoing "Trip in progress" notification, which only needs when-in-use
location. In the Play Console's foreground-service declaration, describe it as
location tracking for an active, user-started trip.

The merged manifest also includes `com.google.android.c2dm.permission.RECEIVE`
and a Firebase Messaging service. Both come from `live_activities` 2.4.3, whose
Android side depends on `firebase-messaging`. The app has no
`google-services.json`, so Firebase is never initialised and nothing is sent.
Play may still list the Firebase SDK in its SDK reports.

## iOS (needs a Mac and an Apple Developer account)

1. In Certificates, Identifiers & Profiles, register:
   - App ID `ph.biyahemeter.app` with the **App Groups** capability
   - App ID `ph.biyahemeter.app.BiyaheMeterWidget` with **App Groups**
   - App Group `group.ph.biyahemeter.app`
2. Create the widget extension target and add the App Group to both targets,
   following [ios/BiyaheMeterWidget/README.md](../ios/BiyaheMeterWidget/README.md).
3. In Xcode, set the Team under Signing & Capabilities for `Runner` and
   `BiyaheMeterWidget`, then `flutter build ipa`.

## Store listing

- Host [PRIVACY_POLICY.md](PRIVACY_POLICY.md) at a public URL once its
  bracketed fields are filled in. Both stores require the URL.
- Play Data safety: no data collected or shared. Location is processed only on
  the device, and Play doesn't count on-device processing as collection.
  User-initiated sharing through the share sheet is also exempt.
- App Store privacy: "Data Not Collected". Location never leaves the device.
