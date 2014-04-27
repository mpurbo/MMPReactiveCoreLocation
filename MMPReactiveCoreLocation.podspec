Pod::Spec.new do |s|
  s.name             = "MMPReactiveCoreLocation"
  s.version          = "0.1.0"
  s.summary          = "A reactive CoreLocation wrapper for use with ReactiveCocoa"
  s.description      = <<-DESC
                       MMPReactiveCoreLocation is a reactive library for using CoreLocation with ReactiveCocoa.

                       Features:
                       * Signals for subscribing to 
                       DESC
  s.homepage         = "https://github.com/mpurbo/MMPReactiveCoreLocation"
  s.license          = 'MIT'
  s.author           = { "Mamad Purbo" => "m.purbo@gmail.com" }
  s.source           = { :git => "https://github.com/mpurbo/MMPReactiveCoreLocation.git", :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/purubo'

  s.platform         = :ios
  s.source_files     = 'Classes'
  s.framework        = 'CoreLocation'
  s.dependency 'ReactiveCocoa', '~> 2.3'
  s.requires_arc     = true    
end
