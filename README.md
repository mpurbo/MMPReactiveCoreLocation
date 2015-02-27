# MMPReactiveCoreLocation

[![Version](http://cocoapod-badges.herokuapp.com/v/MMPReactiveCoreLocation/badge.png)](http://cocoadocs.org/docsets/MMPReactiveCoreLocation)
[![Platform](http://cocoapod-badges.herokuapp.com/p/MMPReactiveCoreLocation/badge.png)](http://cocoadocs.org/docsets/MMPReactiveCoreLocation)

MMPReactiveCoreLocation is a reactive library for using CoreLocation and iBeacon with ReactiveCocoa. 

**Important Notes:**  
* Version 0.6 has been redesigned and rewritten from scratch and is *not compatible* with previous versions. Documentation for version 0.5.\* is still available [here](README-0.5.md), 0.4.\* is [here](README-0.4.md).

Features:
* Globally accessible signals with intelligent resource management for automatically starting and stopping underlying location manager's services.
* No more delegates, all CLLocationManager's functionalities are available as signals.
* Signals for location-related updates, including one-time location query.
* Signals for region monitoring updates, including iBeacon monitoring and ranging.
* Signals for iOS 8 visit monitoring.
* Signals for location manager status updates and errors.
* Supports iOS 8 "Always" and "WhenInUse" authorization.

Although most of the CoreLocation services are implemented, some are not tested and should be considered as alpha quality. Features documented here are tested and should work:

1. [Location subscription](#location-stream-subscription)
1. [Single location subscription](#single-location-subscription)
1. [Significant changes subscription](#significant-changes-subscription)
1. [Region monitoring events subscription](#region-monitoring-events-subscription)
1. [Stopping subscription](#stopping-subscription)
1. [Custom location manager settings](#setting-location-manager)
1. [Handling errors and status changes](#handling-errors-and-status-changes)
1. [Manual authorization request](#manual-authorization-request)

## Installation

MMPReactiveCoreLocation is available through [CocoaPods](http://cocoapods.org), to install
it simply add the following line to your Podfile:
```
pod "MMPReactiveCoreLocation"
```

## Usage

### Location Stream Subscription

The easiest way to subscribe to a location stream with [sensible default settings](#setting-location-manager) is by calling `locations` method to get the signal:
```objc
// import the header
#import <MMPReactiveCoreLocation/MMPReactiveCoreLocation.h>

// build service, subscribe to 'locations' signal
[[[MMPReactiveCoreLocation service] 
                           locations] 
                           subscribeNext:^(CLLocation *location) {
                               NSLog(@"[INFO] received location: %@", location);
                           }];
```
Calling this exact same code from multiple places in the application _will not_ produce multiple `CLLocationManager`+`CLLocationManagerDelegate` sets. The library will manage, start and stop shared instances of `CLLocationManager`+`CLLocationManagerDelegate` based on settings specified when defining the service. For example, following code _will_ create a new `CLLocationManager`+`CLLocationManagerDelegate` set because it requires a custom `activityType`:
```objc
[[[[MMPReactiveCoreLocation service] 
                            activityType:CLActivityTypeFitness]
                            locations] 
                            subscribeNext:^(CLLocation *location) {
                                NSLog(@"[INFO] received location: %@", location);
                            }];
```

### Single Location Subscription

If you don't need a constant stream of location updates, you can use `location` (note the lack of plural `s`) to get the latest location once and the library will automatically stop CLLocationManager and cleanup resources:
```objc
// one-time location
[[[MMPReactiveCoreLocation service] 
                           location] 
                           subscribeNext:^(CLLocation *location) {
                               NSLog(@"[INFO] received single location: %@", location);
                           }];
```
There is a useful option specific to single location subscription called `timeout`. This option can be used to specify whether the signal should give up after after an amount of time waiting for location. This is particularly useful when the application should keep functioning even when there currently is no location available (underground, etc.). Timing out the service will produce signal error as shown in the following example:
```objc
// one-time location with 5 sec. timeout
[[[[MMPReactiveCoreLocation service]
                            timeout:5.0]
                            location]
                            subscribeNext:^(CLLocation *location) {
                                NSLog(@"[INFO] received single location: %@", location);
                            }
                            error:^(NSError *error) {
                                NSLog(@"[ERROR] error getting location: %@", error);
                            }
                            completed:^{
                                NSLog(@"[INFO] single location signal completed.");
                            }];
```

### Significant Changes Subscription

For significant change updates, use `significantLocationChanges` signal instead:
```objc
// build service, subscribe to 'significantLocationChanges' signal
[[[MMPReactiveCoreLocation service] 
                           significantLocationChanges] 
                           subscribeNext:^(CLLocation *location) {
                               NSLog(@"[INFO] received location: %@", location);
                           }];
```
Just as `locations` for constant updates and `location` for single update, use `significantLocationChanges` for constant significant location change updates and use `significantLocationChange` for single significant location change only.

### Region Monitoring Events Subscription

For region monitoring, use `region` for adding region to monitor, and `regionEvents` to get the signal:
```objc
// build service, add 2 regions to monitor, subscribe to region events
[[[[[MMPReactiveCoreLocation service] 
                             region:region1] 
                             region:region2] 
                             regionEvents] 
                             subscribeNext:^(MMPRegionEvent *regionEvent) {
                                 NSLog(@"[INFO] received event: %ld for region: %@", regionEvent.type, regionEvent.region.identifier);
                             }];
```
You can also call `region` method multiple times to define multiple regions to monitor. See `MMPRegionEventType` for more details on what region events are available.

### Stopping Subscription

To stop any signals and automatically cleanup the underlying location manager and requests, simply use the `stop` method:
```objc
self.service = [MMPReactiveCoreLocation service];

// use 'stop' to tell the service that it should stop the subscription. Underlying location manager (CLLocationManager) 
// will automatically be stopped and cleaned up if there are no other subscriber.
[self.service stop];
```
Note that if there are multiple subscribers to signals that use shared underlying location manager (i.e. services built and configured with exactly the same settings), stopping one subscriber may not necessarily stopped the location manager.

### Setting Location Manager

Default settings for the location signals are:
- Automatically pauses for location updates. See [here](https://developer.apple.com/library/ios/documentation/CoreLocation/Reference/CLLocationManager_Class/#//apple_ref/occ/instp/CLLocationManager/pausesLocationUpdatesAutomatically).
- Distance filter is [kCLDistanceFilterNone](https://developer.apple.com/LIBRARY/IOS/documentation/CoreLocation/Reference/CoreLocationConstantsRef/index.html#//apple_ref/doc/constant_group/Distance_Filter_Value). 
- Desired accuracy is [kCLLocationAccuracyBest](https://developer.apple.com/library/mac/documentation/CoreLocation/Reference/CoreLocationConstantsRef/index.html#//apple_ref/c/data/kCLLocationAccuracyBest).
- Activity type is [CLActivityTypeOther](https://developer.apple.com/library/ios/Documentation/CoreLocation/Reference/CLLocationManager_Class/index.html#//apple_ref/c/tdef/CLActivityType).
- On iOS 8, authorization type is "WhenInUse" for `locations` and "Always" for `significantLocationChanges` and `regionEvents`.

Following table shows default authorization that will be used for available signals. You can also [manually specify authorization](#manual-authorization-request).

Signal                      | Authorization
----------------------------|--------------
`locations`                 |`WhenInUse`
`location`                  |`WhenInUse`
`significantLocationChanges`|`Always`
`significantLocationChange` |`Always`
`regionEvents`              |`Always`
`beaconRanges`              |`WhenInUse`
`headingUpdates`            |`WhenInUse`
`visits`                    |`Always`

If you need other than default settings, then you chain-call following methods to set values that you want to customize:
- `distanceFilter` for setting distance filter.
- `desiredAccuracy` for setting desired accuracy.
- `activityType` for setting activity type.
- `pauseLocationUpdatesAutomatically` or `pauseLocationUpdatesManually` to set auto or manual update of location pauses.
- `authorizeAlways` for `Always` authorization and `authorizeWhenInUse` for `WhenInUse` authorization.

Here's a sample code on how to customize location manager settings before subscribing to a signal:
```objc
MMPReactiveCoreLocation *service = [MMPReactiveCoreLocation service];

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
[[[[MMPReactiveCoreLocation service]
                            authorizeAlways]
                            requestAuthorization]
                            subscribeNext:^(NSNumber *statusNumber) {      
                                CLAuthorizationStatus status = [statusNumber intValue];
                                switch (status) {
                                    case kCLAuthorizationStatusAuthorizedAlways:
                                    case kCLAuthorizationStatusAuthorizedWhenInUse:
                                        _mapView.showsUserLocation = YES;
                                        break;
                                    case kCLAuthorizationStatusAuthorized:
                                        _mapView.showsUserLocation = YES;
                                        break;
                                    default:
                                        break;
                                }
                            }];
```

## Roadmap

Most of the CLLocationManager functionalities including iBeacon, visit monitoring, heading updates, etc. has been implemented *but* has not been extensively tested so there's bound to be bugs. I'm planning to use this in real world projects so it should be actively maintained. Contributions are welcomed.

I will write more usage samples and documentation as I fix bugs and write tests. In the meantime, if you have any question on how to apply certain CLLocationManager usage pattern using this library, please feel free to contact me or open issues.

* 0.7: CoreBluetooth integration for iBeacon publishing.
* 0.8: Unit tests and documentations.

## Contact

MMPReactiveCoreLocation is maintained by [Mamad Purbo](https://twitter.com/purubo)

## License

MMPReactiveCoreLocation is available under the MIT license. See the LICENSE file for more info.

