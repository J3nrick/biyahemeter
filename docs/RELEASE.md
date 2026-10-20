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

`live_activities` 2.4.3 (used only on iOS) depends on `firebase-messaging` on
Android. The app manifest removes its push permission
(`com.google.android.c2dm.permission.RECEIVE`), messaging services, instance-ID
receiver and `FirebaseInitProvider` with `tools:node="remove"`, so Firebase never
starts and nothing is sent. The library code is still in the bundle, so Play's
SDK report may list Firebase; answer that it is unused.

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

## Store policy checklist (do before every first submission)

### Wording: fare estimator, not a taximeter
Philippine taxis must use sealed, LTFRB-approved taximeters. Present the app as
a **fare estimator / trip fare calculator** in the store name, subtitle,
description and screenshots. Don't say "taxi meter" or imply it replaces one.
Suggested short description:

> Estimate taxi, TNVS, tricycle and jeepney fares from your GPS trip. Not
> affiliated with the LTFRB; not a substitute for a sealed taximeter.

### Government information (Google Play policy)
The app shows rates based on LTFRB fares. Keep the in-app notice (Settings →
Fare matrix) and put the same in the store description: *"Not affiliated with
or endorsed by the LTFRB. Rate source: LTFRB public fare announcements —
https://ltfrb.gov.ph."* When rates change, update `FarePreset.presets` and the
store text together.

### Google Play: foreground service declaration
Play Console → App content → **Foreground service permissions** →
`FOREGROUND_SERVICE_LOCATION`:
- Use case: *Location — user-initiated trip tracking.*
- Description: *"While the user runs a trip, the app measures distance by GPS
  with the screen off so the fare estimate stays accurate. Tracking starts only
  when the user taps Start Trip, shows an ongoing 'Trip in progress'
  notification, and stops when they tap Stop Trip."*
- Video (about 30 s, screen recording): open app → Start Trip → the
  notification appears → lock the screen → unlock, the distance has grown →
  Stop Trip → the notification disappears.

### Google Play: Data safety
- Data collected: **none**. Data shared: **none**. (Location is processed on
  the device only; share-sheet sharing is user-initiated and exempt.)
- Data encrypted in transit: yes (HTTPS map tiles). Deletion: clear app data /
  uninstall.
- Content rating questionnaire: no user-generated content, no ads.

### App Store: App Privacy and App Review notes
- App Privacy: **Data Not Collected**. Privacy policy URL required.
- App Review notes (paste in App Store Connect):
  > "Background location (UIBackgroundModes: location) is used only during a
  > trip the user starts, to keep measuring distance for the fare estimate
  > while the phone is locked. The blue location indicator is shown. Tracking
  > stops when the trip stops. A Live Activity shows the running fare.
  > No account is needed."
- Required before upload: iOS build tested on a real iPhone via TestFlight;
  Live Activity extension created with its `PrivacyInfo.xcprivacy`
  ([ios/BiyaheMeterWidget/README.md](../ios/BiyaheMeterWidget/README.md)).

### Maps
Map tiles come from OpenStreetMap's public servers, which only allow light use
([tile usage policy](https://operations.osmfoundation.org/policies/tiles/)):
the app sends its own User-Agent (`ph.biyahemeter.app`), shows
"© OpenStreetMap contributors" with a link, and never bulk-downloads tiles.
Before traffic grows, move to the planned Apple Maps integration (MapKit on
iOS; check MapKit JS terms for Android/web) or a keyed tile provider.

### Safety features
"Call 911" opens the dialer; "Share my trip" opens the share sheet and says it
is not an emergency service. Keep both wordings if these screens change.
