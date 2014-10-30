# MMPReactiveCoreLocation

[![Version](http://cocoapod-badges.herokuapp.com/v/MMPReactiveCoreLocation/badge.png)](http://cocoadocs.org/docsets/MMPReactiveCoreLocation)
[![Platform](http://cocoapod-badges.herokuapp.com/p/MMPReactiveCoreLocation/badge.png)](http://cocoadocs.org/docsets/MMPReactiveCoreLocation)

MMPReactiveCoreLocation is a reactive library for using CoreLocation and iBeacon with ReactiveCocoa. 

**Important Note:**  version 0.5 has been redesigned and rewritten from scratch and is *incompatible* with version 0.4.\*. Documentation for version 0.4.\* is still available [here](README-0.4.md).

Features:
* No more of that pesky delegates, all CLLocationManager's functionalities are available as signals.
* Signals for location-related updates, including one-time location query.
* Signals for region monitoring updates, including iBeacon monitoring and ranging.
* Signals for iOS 8 visit monitoring.
* Signals for location manager status updates and errors.
* Supports iOS 8 "Always" and "WhenInUse" authorization.
* CLLocationManager automatically started and stopped when the signal is subscribed or stopped.

## Installation

MMPReactiveCoreLocation is available through [CocoaPods](http://cocoapods.org), to install
it simply add the following line to your Podfile:

    pod "MMPReactiveCoreLocation"

## Usage

The easiest way to subscribe to a location stream with sensible default settings is by calling `locations` method to get the signal:
```objectivec
// import the header
#import <MMPReactiveCoreLocation/MMPReactiveCoreLocation.h>

// create MMPLocationManager, subscribe to 'locations' signal
[[[MMPLocationManager new] locations] subscribeNext:^(CLLocation *location) {
    NSLog(@"[INFO] received location: %@", location);
}];
```

If you don't need a constant stream of location updates, you can use `location` (note the lack of plural `s`) to get the latest location once and the library will automatically stop CLLocationManager and cleanup resources:
```objectivec
// one-time location
[[[MMPLocationManager new] location] subscribeNext:^(CLLocation *location) {
    NSLog(@"[INFO] received location: %@", location);
}];
```

For significant change updates, use `significantLocationChanges` signal instead:
```objectivec
// create MMPLocationManager, subscribe to 'significantLocationChanges' signal
[[[MMPLocationManager new] significantLocationChanges] subscribeNext:^(CLLocation *location) {
    NSLog(@"[INFO] received location: %@", location);
}];
```

Default settings for the location signals are:
- Automatically pauses for location updates. See [here](https://developer.apple.com/library/ios/documentation/CoreLocation/Reference/CLLocationManager_Class/#//apple_ref/occ/instp/CLLocationManager/pausesLocationUpdatesAutomatically).
- Distance filter is [kCLDistanceFilterNone](https://developer.apple.com/LIBRARY/IOS/documentation/CoreLocation/Reference/CoreLocationConstantsRef/index.html#//apple_ref/doc/constant_group/Distance_Filter_Value). 
- Desired accuracy is [kCLLocationAccuracyBest](https://developer.apple.com/library/mac/documentation/CoreLocation/Reference/CoreLocationConstantsRef/index.html#//apple_ref/c/data/kCLLocationAccuracyBest).
- Activity type is [CLActivityTypeOther](https://developer.apple.com/library/ios/Documentation/CoreLocation/Reference/CLLocationManager_Class/index.html#//apple_ref/c/tdef/CLActivityType).
- On iOS 8, authorization type is "WhenInUse" for `locations` and "Always" for `significantLocationChanges`.

### Setting Location Manager

If you need other than default settings, then you chain-call following methods to set values that you want to customize:
- `distanceFilter` for setting distance filter.
- `desiredAccuracy` for setting desired accuracy.
- `activityType` for setting activity type.
- `pauseLocationUpdatesAutomatically` or `pauseLocationUpdatesManually` to set auto or manual update of location pauses.

Here's a sample code on how to customize location manager settings before subscribing to a signal:
```objectivec
MMPLocationManager *service = [MMPLocationManager new];

RACSignal *locations = [[[[service distanceFilter:kCLDistanceFilterNone]
                                   desiredAccuracy:kCLLocationAccuracyBestForNavigation]
                                   activityType:CLActivityTypeFitness]
                                   locations];
```

Please see the header file for more setting possibilities.

### Handling Errors and Status Changes

```objectivec
// handling authorization status change
[[service authorizationStatus] subscribeNext:^(NSNumber *statusNumber) {
    CLAuthorizationStatus status = [statusNumber intValue];
    switch (status) {
        case kCLAuthorizationStatusNotDetermined:
            NSLog(@"[INFO] Status changed: kCLAuthorizationStatusNotDetermined");
            break;
        case kCLAuthorizationStatusRestricted:
            NSLog(@"[INFO] Status changed: kCLAuthorizationStatusRestricted");
            break;
        case kCLAuthorizationStatusDenied:
            NSLog(@"[INFO] Status changed: kCLAuthorizationStatusDenied");
            break;
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 80000
        case kCLAuthorizationStatusAuthorizedAlways:
            NSLog(@"[INFO] Status changed: kCLAuthorizationStatusAuthorizedAlways");
            break;
        case kCLAuthorizationStatusAuthorizedWhenInUse:
            NSLog(@"[INFO] Status changed: kCLAuthorizationStatusAuthorizedWhenInUse");
            break;
#else
        case kCLAuthorizationStatusAuthorized:
            NSLog(@"[INFO] Status changed: kCLAuthorizationStatusAuthorized");
            break;
#endif
        default:
            break;
    }
}];

// handling errors
[[service errors] subscribeNext:^(NSError *error) {
    NSLog(@"[ERROR] Location service error: %@", error);
}];
```

## Roadmap

Most of the CLLocationManager functionalities including iBeacon, region monitoring, visit monitoring, etc. has been implemented *but* has not been extensively tested so there's bound to be bugs. I'm planning to use this in real world projects so it should be actively maintained. Contributions are welcomed.

I will write more usage samples and documentation as I fix bugs and write tests. In the meantime, if you have any question on how to apply certain CLLocationManager usage pattern using this library, please feel free to contact me or open issues.

* 0.6: Core Bluetooth integration for iBeacon publishing.
* 0.7: Unit tests and documentations.

## Contact

MMPCoreDataHelper is maintained by [Mamad Purbo](https://twitter.com/purubo)

## License

MMPReactiveCoreLocation is available under the MIT license. See the LICENSE file for more info.

