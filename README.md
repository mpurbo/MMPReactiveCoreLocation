# MMPReactiveCoreLocation

[![Version](http://cocoapod-badges.herokuapp.com/v/MMPReactiveCoreLocation/badge.png)](http://cocoadocs.org/docsets/MMPReactiveCoreLocation)
[![Platform](http://cocoapod-badges.herokuapp.com/p/MMPReactiveCoreLocation/badge.png)](http://cocoadocs.org/docsets/MMPReactiveCoreLocation)

MMPReactiveCoreLocation is a reactive library for using CoreLocation with ReactiveCocoa. Currently this library only provides
basic signal for receiving location updates.

Features:
* Singleton instance managing CLLocationManager so you don't have to.
* Providing easy to use signals for subscribing to location updates.

## Installation

MMPReactiveCoreLocation is available through [CocoaPods](http://cocoapods.org), to install
it simply add the following line to your Podfile:

    pod "MMPReactiveCoreLocation"

## Usage

Use the singleton instance anywhere in the application and subscribe to signals provided by the instance:
```objectivec
// get the singleton instance
MMPReactiveCoreLocation *rcl = [MMPReactiveCoreLocation instance];

// subscribe to location updates
[[rcl locationSignal] subscribeNext:^(CLLocation *location) {
    NSLog(@"next location updated: (%f, %f, %f)",
          location.coordinate.latitude,
          location.coordinate.longitude,
          location.horizontalAccuracy);
}];
```

You can also subscribe to location updates filtered with accuracy and optional timeout:
```objectivec
// give me only locations when the GPS is accurate within 100m!
[[rcl locationSignalWithAccuracy:100.0] subscribeNext:^(CLLocation *location) {
    NSLog(@"accurate location: (%f, %f, %f)",
          location.coordinate.latitude,
          location.coordinate.longitude,
          location.horizontalAccuracy);
}];

// try to get GPS location that is accurate within 100m, but give up after 15 seconds 
[[rcl locationSignalWithAccuracy:100.0 timeout:15.0]
      subscribeNext:^(CLLocation *location) {
          NSLog(@"Accurate location: (%f, %f, %f)",
                location.coordinate.latitude,
                location.coordinate.longitude,
                location.horizontalAccuracy);
      }
      error:^(NSError *error) {
          if ([error.domain isEqualToString:RACSignalErrorDomain] && error.code == RACSignalErrorTimedOut) {
              NSLog(@"It's been 15 seconds but I still haven't received accurate location.");
          }
      }];
```

## Documentation

Not currently available, but I'll write documentation as I update the library.

## Contact

MMPCoreDataHelper is maintained by [Mamad Purbo](https://twitter.com/purubo)

## License

MMPReactiveCoreLocation is available under the MIT license. See the LICENSE file for more info.

