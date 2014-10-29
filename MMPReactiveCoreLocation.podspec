Pod::Spec.new do |s|
  s.name             = "MMPReactiveCoreLocation"
  s.version          = "0.5.0"
  s.summary          = "A reactive CoreLocation wrapper for use with ReactiveCocoa"
  s.description      = <<-DESC
                       MMPReactiveCoreLocation is a reactive library for using CoreLocation and iBeacon with ReactiveCocoa. 

                       Features:
                       * Singleton instance managing CLLocationManager(s). 
                       * Easy to use signals for subscribing to location updates.
                       * 3 common usage patterns: global location manager for app-wide location subscription; short-lived location managers for one-time location requests; subscribing to multiple custom location managers with different specifications.
                       * Easy to use signals for subscribing to iBeacon monitoring and ranging.
                       * Supports iOS 8 "Always" and "WhenInUse" authorization.
                       DESC
  s.homepage         = "https://github.com/mpurbo/MMPReactiveCoreLocation"
  s.license          = 'MIT'
  s.author           = { "Mamad Purbo" => "m.purbo@gmail.com" }
  s.source           = { :git => "https://github.com/mpurbo/MMPReactiveCoreLocation.git", :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/purubo'

  s.platform         = :ios
  s.ios.deployment_target = '7.0'
  s.source_files     = 'Classes'
  s.framework        = 'CoreLocation', 'CoreBluetooth'
  s.dependency 'ReactiveCocoa'
  s.requires_arc     = true    
end
