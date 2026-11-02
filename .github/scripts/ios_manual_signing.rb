# Switches the Release config of every app / app-extension target in
# ios/Runner.xcodeproj to manual signing with the given App Store profiles,
# then writes the ExportOptions.plist for `flutter build ipa`.
# CI only: the edit is never committed, so local Xcode keeps automatic signing.
#
# Usage: ruby ios_manual_signing.rb TEAM_ID EXPORT_OPTIONS_PATH BUNDLE_ID=PROFILE_UUID...
require 'xcodeproj'

team, export_path, *pairs = ARGV
abort 'usage: ios_manual_signing.rb TEAM_ID EXPORT_OPTIONS_PATH BUNDLE_ID=PROFILE_UUID...' if team.to_s.empty? || export_path.nil?
profiles = pairs.to_h { |pair| pair.split('=', 2) }

project = Xcodeproj::Project.open('ios/Runner.xcodeproj')
signed = {}
project.native_targets.each do |target|
  next unless %i[application app_extension].include?(target.symbol_type)

  config = target.build_configurations.find { |c| c.name == 'Release' }
  bundle_id = config.build_settings['PRODUCT_BUNDLE_IDENTIFIER']
  uuid = profiles[bundle_id] or abort "No provisioning profile for #{bundle_id} (target #{target.name}). Add its secret; see docs/RELEASE.md."
  config.build_settings.merge!(
    'CODE_SIGN_STYLE' => 'Manual',
    'DEVELOPMENT_TEAM' => team,
    'CODE_SIGN_IDENTITY' => 'Apple Distribution',
    'CODE_SIGN_IDENTITY[sdk=iphoneos*]' => 'Apple Distribution',
    'PROVISIONING_PROFILE_SPECIFIER' => uuid,
  )
  signed[bundle_id] = uuid
  puts "#{target.name}: #{bundle_id} -> #{uuid}"
end
project.save

entries = signed.map { |id, uuid| "    <key>#{id}</key><string>#{uuid}</string>" }.join("\n")
File.write(export_path, <<~PLIST)
  <?xml version="1.0" encoding="UTF-8"?>
  <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
  <plist version="1.0">
  <dict>
    <key>method</key><string>app-store-connect</string>
    <key>teamID</key><string>#{team}</string>
    <key>signingStyle</key><string>manual</string>
    <key>signingCertificate</key><string>Apple Distribution</string>
    <key>provisioningProfiles</key>
    <dict>
  #{entries}
    </dict>
    <key>manageAppVersionAndBuildNumber</key><false/>
    <key>uploadSymbols</key><true/>
  </dict>
  </plist>
PLIST
