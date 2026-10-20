# Biyahe Meter Privacy Policy

> **Draft for review.** Fill in the bracketed fields, check that it still matches
> the app, then host it at a public URL (both Google Play and the App Store ask
> for one). Settings/agreement storage describes the persistence work on the
> `feat/persist-state` branch; adjust if that lands differently.

_Last updated: [DATE]_

Biyahe Meter ("the app") is a fare estimator for taxis and other rides in the
Philippines. It is not a sealed taximeter and is not affiliated with the LTFRB. It is made by [DEVELOPER NAME] ("we"). This policy explains what
the app does with your information.

**Summary:** the app uses your location only to measure your trip and work out
the fare. Your trips are saved only on your phone. We have no servers, no
accounts and no analytics or advertising SDKs, and we do not collect, sell or
share your personal data.

## Location

- The app asks for precise location so it can measure the distance you travel
  and calculate the fare.
- It reads your location only while you have the map open or a trip is
  running. During a trip it keeps tracking with the screen off or the app in
  the background, so the fare stays accurate:
  - **Android:** a "Trip in progress" notification stays visible for as long as
    tracking runs.
  - **iOS:** the location indicator in the status bar shows while tracking runs.
- When you stop the trip, background tracking stops. The app never reads your
  location in the background when no trip is running.
- Location is never sent to us.

## Data stored on your phone

Trip history (start and end time, distance, waiting time, fare breakdown and
discount, fuel estimate, fare preset, and the start and end coordinates), your
settings and your acceptance of the in-app agreements are saved on your phone
in the app's local database (Hive). Map tiles are cached on your phone
too, so maps load faster and work offline.

This data never leaves your phone unless you share it yourself (see below). It
is deleted when you clear the app's data or uninstall the app.

## Services the app connects to

To show the map (in both light and dark mode), the app downloads map tiles from
OpenStreetMap ([tile.openstreetmap.org](https://tile.openstreetmap.org)),
covered by the
[OSMF Privacy Policy](https://osmfoundation.org/wiki/Privacy_Policy).

Like any website you visit, this server receives your IP address and which
map tiles you requested, which reveals the area you are looking at. It does
not receive your GPS location, your trips or any account information.

The **Check official rates** link opens the LTFRB website in your browser, and
**Call 911** opens your phone's dialer. The app sends nothing in either case.

## Sharing you choose to do

When you use **Share receipt** or **Share my trip**, the app opens your
phone's share sheet with a receipt or message containing the trip details, your
current coordinates and a Google Maps link. Nothing is sent until you choose
an app and a recipient. What happens after that is up to the app you send it
with.

## Notifications

During a trip the app shows an ongoing notification (Android) or a Live
Activity on the Lock Screen and in the Dynamic Island (iOS) with the running
fare, distance and time. These are created on your phone; we do not send push
notifications and the app does not use a push notification service.

## Children

The app is not directed at children under 13 and does not knowingly collect
data from anyone.

## Changes

If this policy changes, we will update this page and the "Last updated" date.

## Contact

Questions about this policy: [CONTACT EMAIL]
