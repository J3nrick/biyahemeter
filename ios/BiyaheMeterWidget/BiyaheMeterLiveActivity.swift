import ActivityKit
import SwiftUI
import WidgetKit

// Must match live_activities' own struct EXACTLY (name and fields), or the
// activity is created but never shown.
struct LiveActivitiesAppAttributes: ActivityAttributes, Identifiable {
  public typealias LiveDeliveryData = ContentState

  public struct ContentState: Codable, Hashable {
    var appGroupId: String
  }

  var id = UUID()
}

extension LiveActivitiesAppAttributes {
  func prefixedKey(_ key: String) -> String { "\(id)_\(key)" }
}

// Same value as TripLiveService.appGroupId in lib/services/trip_live_service.dart.
private let sharedDefaults = UserDefaults(suiteName: "group.com.example.biyahemeter")

// Brand accent from AppTheme: #1F4B99 light, #7AA2E3 dark (both ≥4.5:1 on their backgrounds).
private let accent = Color(UIColor { traits in
  traits.userInterfaceStyle == .dark
    ? UIColor(red: 0x7A / 255, green: 0xA2 / 255, blue: 0xE3 / 255, alpha: 1)
    : UIColor(red: 0x1F / 255, green: 0x4B / 255, blue: 0x99 / 255, alpha: 1)
})
private let islandAccent = Color(red: 0x7A / 255, green: 0xA2 / 255, blue: 0xE3 / 255)

/// Values written by TripLiveService (keys: fare, distance, elapsed, waiting, preset).
private struct Trip {
  let fare, distance, elapsed, waiting, preset: String

  init(_ attributes: LiveActivitiesAppAttributes) {
    func value(_ key: String) -> String {
      sharedDefaults?.string(forKey: attributes.prefixedKey(key)) ?? ""
    }
    fare = value("fare")
    distance = value("distance")
    elapsed = value("elapsed")
    waiting = value("waiting")
    preset = value("preset")
  }

  var details: String {
    [distance, elapsed, waiting].filter { !$0.isEmpty }.joined(separator: " · ")
  }

  /// "₱123.45" read aloud as "123.45 pesos".
  var spokenFare: String {
    fare.replacingOccurrences(of: "₱", with: "") + " pesos"
  }
}

struct BiyaheMeterLiveActivity: Widget {
  var body: some WidgetConfiguration {
    ActivityConfiguration(for: LiveActivitiesAppAttributes.self) { context in
      LockScreenTripView(trip: Trip(context.attributes))
        .activityBackgroundTint(Color(.systemBackground))
        .activitySystemActionForegroundColor(accent)
    } dynamicIsland: { context in
      let trip = Trip(context.attributes)
      return DynamicIsland {
        DynamicIslandExpandedRegion(.leading) {
          Label("Trip", systemImage: "car.fill")
            .font(.caption.weight(.semibold))
            .foregroundStyle(islandAccent)
        }
        DynamicIslandExpandedRegion(.trailing) {
          Text(trip.fare)
            .font(.title3.weight(.bold).monospacedDigit())
            .accessibilityLabel("Fare \(trip.spokenFare)")
        }
        DynamicIslandExpandedRegion(.bottom) {
          Text(trip.details)
            .font(.footnote.monospacedDigit())
            .foregroundStyle(.secondary)
        }
      } compactLeading: {
        Image(systemName: "car.fill")
          .foregroundStyle(islandAccent)
          .accessibilityHidden(true)
      } compactTrailing: {
        Text(trip.fare)
          .font(.caption.weight(.bold).monospacedDigit())
          .accessibilityLabel("Fare \(trip.spokenFare)")
      } minimal: {
        Image(systemName: "car.fill")
          .foregroundStyle(islandAccent)
          .accessibilityLabel("Trip in progress")
      }
    }
  }
}

private struct LockScreenTripView: View {
  let trip: Trip

  var body: some View {
    HStack(alignment: .center, spacing: 14) {
      VStack(alignment: .leading, spacing: 4) {
        Label("Trip in progress", systemImage: "car.fill")
          .font(.caption.weight(.semibold))
          .foregroundStyle(accent)
        Text(trip.fare)
          .font(.system(.largeTitle, design: .rounded).weight(.bold).monospacedDigit())
          .minimumScaleFactor(0.6)
          .lineLimit(1)
          .accessibilityLabel("Fare \(trip.spokenFare)")
        if !trip.preset.isEmpty {
          Text(trip.preset)
            .font(.caption)
            .foregroundStyle(.secondary)
        }
      }
      Spacer(minLength: 8)
      Text(trip.details.replacingOccurrences(of: " · ", with: "\n"))
        .font(.subheadline.monospacedDigit())
        .multilineTextAlignment(.trailing)
        .foregroundStyle(.secondary)
    }
    .padding(16)
  }
}
