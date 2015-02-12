Pod::Spec.new do |s|
  s.name             = "MMPReactiveCoreLocation"
  s.version          = "0.6.0"
  s.summary          = "A reactive CoreLocation wrapper for use with ReactiveCocoa"
  s.description      = <<-DESC
                       MMPReactiveCoreLocation is a reactive library for using CoreLocation and iBeacon with ReactiveCocoa. 

                       Features:
                       * No more of that pesky delegates, all CLLocationManager's functionalities are available as signals.
                       * Signals for location-related updates, including one-time location query.
                       * Signals for region monitoring updates, including iBeacon monitoring and ranging.
                       * Signals for iOS 8 visit monitoring.
                       * Signals for location manager status updates and errors.
                       * Supports iOS 8 "Always" and "WhenInUse" authorization.
                      * CLLocationManager automatically started and stopped when the signal is subscribed or stopped.
                       DESC
  s.homepage         = "https://github.com/mpurbo/MMPReactiveCoreLocation"
  s.license          = 'MIT'
  s.author           = { "Mamad Purbo" => "m.purbo@gmail.com" }
  s.source           = { :git => "https://github.com/mpurbo/MMPReactiveCoreLocation.git", :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/purubo'

  s.platform         = :ios
  s.ios.deployment_target = '8.1'
  s.source_files     = 'Classes'
  s.framework        = 'CoreLocation', 'CoreBluetooth'
  s.dependency 'ReactiveCocoa'
  s.requires_arc     = true    
end
