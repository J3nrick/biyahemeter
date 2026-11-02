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

## iOS: TestFlight from GitHub Actions (no Mac needed)

[`.github/workflows/testflight.yml`](../.github/workflows/testflight.yml) builds
a signed release on a macOS runner and uploads it to TestFlight. Everything below
is done in a browser plus Git Bash / PowerShell on Windows. All the files you
create here (`.key`, `.p12`, `.mobileprovision`, `.p8`) are private: keep them
**outside the repo** (for example `C:\Users\<you>\apple-signing\`), back them up
in a password manager, and never commit them.

The extension target itself (`BiyaheMeterWidget`) is set up as described in
[ios/BiyaheMeterWidget/README.md](../ios/BiyaheMeterWidget/README.md).

### 1. Apple Developer Program

Enrol at <https://developer.apple.com/programs/enroll/> (paid, yearly). Once
approved, open <https://developer.apple.com/account> → **Membership details** and
copy the **Team ID** (10 characters). That is the `APPLE_TEAM_ID` secret.

### 2. Identifiers

<https://developer.apple.com/account/resources/identifiers/list>:

1. **+** → **App Groups** → Continue. Identifier `group.ph.biyahemeter.app`.
2. **+** → **App IDs** → **App**. Bundle ID **Explicit** `ph.biyahemeter.app`.
   Under Capabilities tick **App Groups**. Register.
3. Same again for `ph.biyahemeter.app.BiyaheMeterWidget`, also with **App Groups**.
4. Open each of the two App IDs → App Groups → **Configure** → tick
   `group.ph.biyahemeter.app` → Save.

### 3. Distribution certificate (`.p12`)

Run in **Git Bash** (it ships `openssl`). `MSYS_NO_PATHCONV=1` stops Git Bash
from turning `/CN=` into a Windows path.

```bash
mkdir -p ~/apple-signing && cd ~/apple-signing
openssl genrsa -out ios_distribution.key 2048
MSYS_NO_PATHCONV=1 openssl req -new -key ios_distribution.key -out ios_distribution.csr -subj "/CN=Biyahe Meter Distribution/C=PH"
```

1. <https://developer.apple.com/account/resources/certificates/list> → **+** →
   **Apple Distribution** → Continue → upload `ios_distribution.csr` → Download.
   Save `distribution.cer` into `~/apple-signing`.
2. Back in Git Bash, combine the certificate and key. Pick a password when
   asked; it is the `IOS_DIST_CERT_PASSWORD` secret. The `PBE-SHA1-3DES` flags
   keep the file in the older format that the macOS keychain can import.

   ```bash
   openssl x509 -inform DER -in distribution.cer -out distribution.pem
   openssl pkcs12 -export -inkey ios_distribution.key -in distribution.pem -out ios_distribution.p12 -keypbe PBE-SHA1-3DES -certpbe PBE-SHA1-3DES -macalg sha1
   ```

The certificate is valid for one year. To renew it, repeat this section and
section 4, then update the four secrets those sections produce.

### 4. App Store provisioning profiles

<https://developer.apple.com/account/resources/profiles/list> → **+** →
**Distribution → App Store Connect** → Continue:

1. App ID `ph.biyahemeter.app` → the certificate from step 3 → name
   `Biyahe Meter App Store` → Generate → Download.
2. Again for `ph.biyahemeter.app.BiyaheMeterWidget`, named
   `Biyahe Meter Widget App Store`.

If you later change an App ID's capabilities, the profile turns **Invalid**. Then
open it → Edit → Save → Download again and update the secret.

### 5. App record and API key in App Store Connect

1. <https://appstoreconnect.apple.com/apps> → **+** → **New App**. Platform iOS,
   name, primary language, Bundle ID `ph.biyahemeter.app`, SKU `biyahemeter`,
   User Access: Full Access. The upload fails until this record exists.
2. <https://appstoreconnect.apple.com/access/integrations/api> → **Team Keys**.
   The first time, the Account Holder must click **Request Access**. Then **+**,
   name `GitHub Actions`, Access **App Manager** → Generate.
   - **Download** the `AuthKey_XXXXXXXXXX.p8`. Apple lets you download it only
     once.
   - Copy the **Key ID** (from the row) and the **Issuer ID** (above the table).

### 6. GitHub secrets

<https://github.com/J3nrick/biyahemeter/settings/secrets/actions> → **New
repository secret** for each row. To copy a file as base64, run this in
PowerShell; it puts the text on the clipboard, ready to paste:

```powershell
[Convert]::ToBase64String([IO.File]::ReadAllBytes("$HOME\apple-signing\ios_distribution.p12")) | Set-Clipboard
```

| Secret | Value |
|---|---|
| `APPLE_TEAM_ID` | Team ID from step 1 |
| `IOS_DIST_CERT_P12_BASE64` | base64 of `ios_distribution.p12` |
| `IOS_DIST_CERT_PASSWORD` | the `.p12` password from step 3 |
| `IOS_PROFILE_APP_BASE64` | base64 of the `Biyahe_Meter_App_Store.mobileprovision` file |
| `IOS_PROFILE_WIDGET_BASE64` | base64 of the widget profile (required: the `BiyaheMeterWidget` target is in the Xcode project) |
| `APP_STORE_CONNECT_API_KEY_ID` | Key ID from step 5 |
| `APP_STORE_CONNECT_ISSUER_ID` | Issuer ID from step 5 |
| `APP_STORE_CONNECT_API_KEY_P8` | open the `.p8` in Notepad and paste all of it, including the `BEGIN`/`END` lines |

### 7. Build and install

- GitHub → **Actions** → **TestFlight** → **Run workflow** (branch `main`), or
  push a tag like `v1.0.0`. The first step names any missing secret.
- The version comes from `pubspec.yaml` (`1.0.0`). The build number is the
  workflow's run number, so it rises on every run. **Re-run jobs** reuses the run
  number, and Apple rejects a build number it already has. If an earlier attempt
  got as far as uploading, start a new run instead.
- App Store Connect → the app → **TestFlight**. Processing takes about 5–30
  minutes; Apple emails you if it rejects the build (for example, a missing
  privacy manifest). Export compliance is already answered:
  `ITSAppUsesNonExemptEncryption` = NO in `Info.plist`.
- **Internal Testing** → **+** → create a group, then add yourself. On the
  iPhone, install **TestFlight** from the App Store and sign in with the same
  Apple ID. The build shows up there to install.

How signing works: the workflow imports the certificate into a temporary
keychain and installs the profiles. Then
[`.github/scripts/ios_manual_signing.rb`](../.github/scripts/ios_manual_signing.rb)
switches the Release config of each app and extension target to manual signing
with the matching profile, on the runner only (nothing is committed). It fails
and names the bundle id if a target has no profile. Then `flutter build ipa`
runs, and `xcodebuild -exportArchive` uploads the result with the API key.

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
- Required before upload: iOS build tested on a real iPhone via TestFlight,
  including the Live Activity
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
