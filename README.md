# MMPReactiveCoreLocation

[![Version](http://cocoapod-badges.herokuapp.com/v/MMPReactiveCoreLocation/badge.png)](http://cocoadocs.org/docsets/MMPReactiveCoreLocation)
[![Platform](http://cocoapod-badges.herokuapp.com/p/MMPReactiveCoreLocation/badge.png)](http://cocoadocs.org/docsets/MMPReactiveCoreLocation)

MMPReactiveCoreLocation is a reactive library for using CoreLocation and iBeacon with ReactiveCocoa. 

**Important Notes:**  
* I'm currently working on a new branch `exp` that will become the base for future versions (0.6~) and *will not be* backward compatible. There is a reason why I kept the version to be 0.x: I'm still experimenting and trying to find the best signal design for CoreLocation. The plan is to finalize the library design by 0.6.x and make it relatively stable. Version 0.6 will introduce simpler functions, safer signals, and smarter resource management.
* Version 0.5 has been redesigned and rewritten from scratch and is *incompatible* with version 0.4.\*. Documentation for version 0.4.\* is still available [here](README-0.4.md).

Features:
* No more of that pesky delegates, all CLLocationManager's functionalities are available as signals.
* Signals for location-related updates, including one-time location query.
* Signals for region monitoring updates, including iBeacon monitoring and ranging.
* Signals for iOS 8 visit monitoring.
* Signals for location manager status updates and errors.
* Supports iOS 8 "Always" and "WhenInUse" authorization.
* CLLocationManager automatically started and stopped when the signal is subscribed or stopped.

Although most CoreLocation services are implemented, many are not tested and should be considered as alpha quality. Features documented here are tested and should work:

1. [Location subscription](#location-subscription)
1. [Significant changes subscription](#significant-changes-subscription)
1. [Region monitoring events subscription](#region-monitoring-events-subscription)
1. [Stopping subscription](#stopping-subscription)
1. [Custom location manager settings](#setting-location-manager)
1. [Handling errors and status changes](#handling-errors-and-status-changes)
1. [Manual authorization request](#manual-authorization-request)

## Installation

MMPReactiveCoreLocation is available through [CocoaPods](http://cocoapods.org), to install
it simply add the following line to your Podfile:

    pod "MMPReactiveCoreLocation"

## Usage

### Location Subscription

The easiest way to subscribe to a location stream with [sensible default settings](#setting-location-manager) is by calling `locations` method to get the signal:
```objc
// import the header
#import <MMPReactiveCoreLocation/MMPReactiveCoreLocation.h>

// create MMPLocationManager, subscribe to 'locations' signal
[[[MMPLocationManager new] locations] subscribeNext:^(CLLocation *location) {
    NSLog(@"[INFO] received location: %@", location);
}];
```

If you don't need a constant stream of location updates, you can use `location` (note the lack of plural `s`) to get the latest location once and the library will automatically stop CLLocationManager and cleanup resources:
```objc
// one-time location
[[[MMPLocationManager new] location] subscribeNext:^(CLLocation *location) {
    NSLog(@"[INFO] received location: %@", location);
}];
```

### Significant Changes Subscription

For significant change updates, use `significantLocationChanges` signal instead:
```objc
// create MMPLocationManager, subscribe to 'significantLocationChanges' signal
[[[MMPLocationManager new] significantLocationChanges] subscribeNext:^(CLLocation *location) {
    NSLog(@"[INFO] received location: %@", location);
}];
```
Just as `locations` for constant updates and `location` for single update, use `significantLocationChanges` for constant significant location change updates and use `significantLocationChange` for single significant location change only.

### Region Monitoring Events Subscription

For region monitoring, use `region` for adding region to monitor, and `regionEvents` to get the signal:
```objc
[[[[MMPLocationManager new] region:region]
                            regionEvents]
                            subscribeNext:^(MMPRegionEvent *regionEvent) {
                                NSLog(@"[INFO] received event: %ld for region: %@", regionEvent.type, regionEvent.region.identifier);
                            }];
```
You can also call `region` method multiple times to define multiple regions to monitor. See `MMPRegionEventType` for more details on what region events are available.

### Stopping Subscription

To stop any signals and automatically cleanup the underlying location manager and requests, use `stop` method to specify a signal that would send a 'stop' notification when it is completed. For example, following code shows how to stop a location subscription using a subject:
```objc
// doneSubject is the subject that will be used to control location subscription stoppage
self.doneSubject = [RACSubject subject];

MMPLocationManager *service = [MMPLocationManager new];
// use 'stop' to tell the service that it should stop when doneSubject is completed
[[[[service stop:self.doneSubject]
            locations]
            subscribeOn:[RACScheduler mainThreadScheduler]]
            subscribeNext:^(CLLocation *location) {
                
                NSString *locString = [NSString stringWithFormat:@"(%f, %f, %f)",
                                       location.coordinate.latitude,
                                       location.coordinate.longitude,
                                       location.horizontalAccuracy];
                NSLog(@"[INFO] received location: %@", locString);
                self.locationLabel.text = locString;
                
            }
            completed:^{
                // by this time, the underlying CLLocationManager's service should be stopped and cleaned up.
                // we can clean the subject here because it's should be completed already
                self.doneSubject = nil;
            }];

// ... somewhere else when we want the service to stop
[self.doneSubject sendCompleted];
```

### Setting Location Manager

Default settings for the location signals are:
- Automatically pauses for location updates. See [here](https://developer.apple.com/library/ios/documentation/CoreLocation/Reference/CLLocationManager_Class/#//apple_ref/occ/instp/CLLocationManager/pausesLocationUpdatesAutomatically).
- Distance filter is [kCLDistanceFilterNone](https://developer.apple.com/LIBRARY/IOS/documentation/CoreLocation/Reference/CoreLocationConstantsRef/index.html#//apple_ref/doc/constant_group/Distance_Filter_Value). 
- Desired accuracy is [kCLLocationAccuracyBest](https://developer.apple.com/library/mac/documentation/CoreLocation/Reference/CoreLocationConstantsRef/index.html#//apple_ref/c/data/kCLLocationAccuracyBest).
- Activity type is [CLActivityTypeOther](https://developer.apple.com/library/ios/Documentation/CoreLocation/Reference/CLLocationManager_Class/index.html#//apple_ref/c/tdef/CLActivityType).
- On iOS 8, authorization type is "WhenInUse" for `locations` and "Always" for `significantLocationChanges` and `regionEvents`.

If you need other than default settings, then you chain-call following methods to set values that you want to customize:
- `distanceFilter` for setting distance filter.
- `desiredAccuracy` for setting desired accuracy.
- `activityType` for setting activity type.
- `pauseLocationUpdatesAutomatically` or `pauseLocationUpdatesManually` to set auto or manual update of location pauses.

Here's a sample code on how to customize location manager settings before subscribing to a signal:
```objc
MMPLocationManager *service = [MMPLocationManager new];

RACSignal *locations = [[[[service distanceFilter:kCLDistanceFilterNone]
                                   desiredAccuracy:kCLLocationAccuracyBestForNavigation]
                                   activityType:CLActivityTypeFitness]
                                   locations];
```

Please see the header file for more setting possibilities.

### Handling Errors and Status Changes

```objc
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

### Manual Authorization Request

When you need to send request for authorization manually, for example when using `MKMapView` and you just need to send the request before setting `showsUserLocation`, you can use `requestAuthorization` method that returns a signal producing status change events (same as `authorizationStatus` signal):
```objc
// you need to have a strong reference to the manager, otherwise the manager
// will be disposed before you receive authorization.
@property (nonatomic, strong) MMPLocationManager *locationManagerForAuth;

// .... 

self.locationManagerForAuth = [MMPLocationManager new];

[[[self.locationManagerForAuth
   authorizeAlways]
   requestAuthorization]
   subscribeNext:^(NSNumber *statusNumber) {      
       CLAuthorizationStatus status = [statusNumber intValue];
       switch (status) {
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 80000
           case kCLAuthorizationStatusAuthorizedAlways:
           case kCLAuthorizationStatusAuthorizedWhenInUse:
               _mapView.showsUserLocation = YES;
               break;
#else
           case kCLAuthorizationStatusAuthorized:
               _mapView.showsUserLocation = YES;
               break;
#endif
           default:
               break;
       }
   }];
```

## Roadmap

Most of the CLLocationManager functionalities including iBeacon, visit monitoring, heading updates, etc. has been implemented *but* has not been extensively tested so there's bound to be bugs. I'm planning to use this in real world projects so it should be actively maintained. Contributions are welcomed.

I will write more usage samples and documentation as I fix bugs and write tests. In the meantime, if you have any question on how to apply certain CLLocationManager usage pattern using this library, please feel free to contact me or open issues.

* 0.6: Refactors with simpler functions, safer signals, and smarter resource management.
* 0.7: CoreBluetooth integration for iBeacon publishing.
* 0.8: Unit tests and documentations.

## Contact

MMPReactiveCoreLocation is maintained by [Mamad Purbo](https://twitter.com/purubo)

## License

MMPReactiveCoreLocation is available under the MIT license. See the LICENSE file for more info.

