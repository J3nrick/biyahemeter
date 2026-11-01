# BiyaheMeterWidget — iOS Live Activity

Shows the running fare, distance and time on the Lock Screen and in the Dynamic
Island while a trip is metering.

Data flow: `lib/services/trip_live_service.dart` → `live_activities` plugin →
shared App Group `UserDefaults` → `BiyaheMeterLiveActivity.swift`.

## What's already set up

The `BiyaheMeterWidget` app-extension target is in `ios/Runner.xcodeproj`
(iOS 16.1+, bundle id `ph.biyahemeter.app.BiyaheMeterWidget`). It compiles
`BiyaheMeterLiveActivity.swift` and `BiyaheMeterWidgetBundle.swift`, copies
`PrivacyInfo.xcprivacy` (App Store Connect rejects an extension that uses
`UserDefaults` without one, ITMS-91053), uses this folder's `Info.plist`
(`NSSupportsLiveActivities` = YES) and is embedded in Runner by an
*Embed Foundation Extensions* phase that sits before Flutter's *Thin Binary*
script (otherwise Xcode reports a build cycle). Both targets have the App Group
`group.ph.biyahemeter.app` in their `.entitlements` files. CI's `build-ios` job
compiles it on every push.

If you change the group id, change it in `Runner/Runner.entitlements`,
`BiyaheMeterWidget.entitlements`, `TripLiveService.appGroupId` and
`sharedDefaults` in `BiyaheMeterLiveActivity.swift`.

## Signing (Mac, Apple Developer account)

1. In Certificates, Identifiers & Profiles, register the app id
   `ph.biyahemeter.app`, the extension id `ph.biyahemeter.app.BiyaheMeterWidget`
   (both with **App Groups**) and the App Group `group.ph.biyahemeter.app`.
2. Open `ios/Runner.xcworkspace`, and under **Signing & Capabilities** pick your
   Team for both `Runner` and `BiyaheMeterWidget`.
3. `flutter run` on a real iPhone (Live Activities don't render in every simulator).

## Check

Start a trip, lock the phone: the Lock Screen shows "Trip in progress" with the
fare; on iPhone 14 Pro and later the fare also sits in the Dynamic Island. Stop the
trip and the activity ends. If nothing shows, check Settings → Byahe Meter →
Live Activities is on, and that the App Group id matches in all three places.
