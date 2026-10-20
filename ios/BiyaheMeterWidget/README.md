# BiyaheMeterWidget — iOS Live Activity

Shows the running fare, distance and time on the Lock Screen and in the Dynamic
Island while a trip is metering. The Swift files here are ready; the Xcode target
has to be created on a Mac (it cannot be generated or built on Windows).

Data flow: `lib/services/trip_live_service.dart` → `live_activities` plugin →
shared App Group `UserDefaults` → `BiyaheMeterLiveActivity.swift`.

## One-time Xcode setup (Mac)

1. `cd biyahemeter && flutter build ios --config-only`, then open
   `ios/Runner.xcworkspace`.
2. **File → New → Target → Widget Extension**. Product name `BiyaheMeterWidget`,
   tick **Include Live Activity**, untick Configuration Intent. Deployment target
   iOS 16.1 or later. When asked, *don't* activate the new scheme.
3. Xcode creates its own sample files in `ios/BiyaheMeterWidget/`. Delete the
   generated `*.swift` files **except** keep its `Info.plist` and asset catalog, and add
   the two files from this folder (`BiyaheMeterLiveActivity.swift`,
   `BiyaheMeterWidgetBundle.swift`) to the **BiyaheMeterWidget** target.
4. In the extension's `Info.plist` add `NSSupportsLiveActivities` = `YES`
   (Runner's `Info.plist` already has it).
5. **Signing & Capabilities → + Capability → App Groups** on **both** `Runner` and
   `BiyaheMeterWidget`, and add `group.com.example.biyahemeter`.
   - If you change the group id, also change `TripLiveService.appGroupId` and
     `sharedDefaults` in `BiyaheMeterLiveActivity.swift`.
   - The bundle id is still the template `com.example.biyahe_meter`; App Groups
     need a real id registered in your Apple Developer account.
6. Runner target → **Build Phases**: drag **Embed Foundation Extensions** above
   **Run Script** (Thin Binary) to avoid a "Cycle inside Runner" build error.
7. `flutter run` on a real iPhone (Live Activities don't render in every simulator).

## Check

Start a trip, lock the phone: the Lock Screen shows "Trip in progress" with the
fare; on iPhone 14 Pro and later the fare also sits in the Dynamic Island. Stop the
trip and the activity ends. If nothing shows, check Settings → Byahe Meter →
Live Activities is on, and that the App Group id matches in all three places.
