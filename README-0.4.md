# MMPReactiveCoreLocation

[![Version](http://cocoapod-badges.herokuapp.com/v/MMPReactiveCoreLocation/badge.png)](http://cocoadocs.org/docsets/MMPReactiveCoreLocation)
[![Platform](http://cocoapod-badges.herokuapp.com/p/MMPReactiveCoreLocation/badge.png)](http://cocoadocs.org/docsets/MMPReactiveCoreLocation)

MMPReactiveCoreLocation is a reactive library for using CoreLocation and iBeacon with ReactiveCocoa. 

Features:
* Singleton instance managing CLLocationManager(s). 
* Easy to use signals for subscribing to location updates.
* 3 common usage patterns: 
    - global location manager for app-wide location subscription; 
    - short-lived location managers for one-time location requests; 
    - subscribing to multiple custom location managers with different specifications.
* Easy to use signals for subscribing to iBeacon monitoring and ranging.
* Supports iOS 8 "Always" and "WhenInUse" authorization.

## Installation

MMPReactiveCoreLocation is available through [CocoaPods](http://cocoapods.org), to install
it simply add the following line to your Podfile:

    pod "MMPReactiveCoreLocation"

## Usage

### Application-wide Location Subscription

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
In order to get the location stream started, you need to call `start`. To stop the stream, call `stop`. For example, to make the stream available
throughout the application but cancelled whenever the application is in background or stopped, do something like:
```objectivec
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [[MMPReactiveCoreLocation instance] start];    
    return YES;
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    [[MMPReactiveCoreLocation instance] stop];
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    [[MMPReactiveCoreLocation instance] start];
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    [[MMPReactiveCoreLocation instance] stop];
}
```

### Application-wide Location Manager Configuration

Before calling `start` on the singleton instance, you can also configure the location manager by setting the instance's properties:
```objectivec
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    MMPReactiveCoreLocation *rcl = [MMPReactiveCoreLocation instance];
    rcl.desiredAccuracy = kCLLocationAccuracyBest;
    rcl.locationUpdateType = MMPRCLLocationUpdateTypeSignificantChange; // only monitors significant change.
    // iOS 8 (no effect for iOS < 8)
    rcl.locationAuthorizationType = MMPRCLLocationAuthorizationTypeAlways;

    [rcl start];
    return YES;
}
```
See the [class reference](http://cocoadocs.org/docsets/MMPReactiveCoreLocation) for detailed information on these configurations.

### One-time Location Requests

Application-wide location subscription is usually only suitable for GPS-heavy location tracking applications. For most of other type of applications, occasional one-time location requests is usually sufficient and it's much less taxing on the battery. Use `single*` methods to request for such location as shown in the following example:

```objectivec
// give me one-time location.
[[rcl singleLocationSignalWithAccuracy:100.0 timeout:15.0]
      subscribeNext:^(CLLocation *location) {
          NSLog(@"next location updated: (%f, %f, %f)", 
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

For this kind of one-time location request, the `MMPReactiveCoreLocation` instance will create a short-lived location manager, start and stop it automatically so you don't need to call `start` and `stop` manually.

### Multiple Location Managers

If you need to subscribe to signals with different location manager specifications/parameters, then you can use `auto*` methods as shown in the following example:

```objectivec
// let's do one standard update with best accuracy
[[[MMPReactiveCoreLocation instance]
   autoLocationSignalWithLocationUpdateType:MMPRCLLocationUpdateTypeStandard]
   subscribeNext:^(CLLocation *location) {
       NSLog(@"Auto signal 1 location updated: (%f, %f, %f)", location.coordinate.latitude, location.coordinate.longitude, location.horizontalAccuracy);
   }
   error:^(NSError *error) {
       NSLog(@"Ouch! Auto signal 1 error: %@", error);
   }
   completed:^{
       NSLog(@"Auto signal 1 completed");
   }];

// then have another one with significant change and 100.0 m accuracy 
[[[MMPReactiveCoreLocation instance]
   autoLocationSignalWithAccuracy:100.0 locationUpdateType:MMPRCLLocationUpdateTypeSignificantChange]
   subscribeNext:^(CLLocation *location) {
       NSLog(@"Auto signal 2 location updated: (%f, %f, %f)", location.coordinate.latitude, location.coordinate.longitude, location.horizontalAccuracy);
   }
   error:^(NSError *error) {
       NSLog(@"Ouch! Auto signal 2 error: %@", error);
   }
   completed:^{
       NSLog(@"Auto signal 2 completed");
   }];
```

For both of these signals, the `MMPReactiveCoreLocation` instance will create a special location manager, start and stop it automatically so you don't need to call `start` and `stop` manually.

### iBeacon Signals

iBeacon related signals are available from `beacon*` methods. These signals emit beacon event object `MMPRCLBeaconEvent` with a property called `eventType` that can be used to determine the type of event produced by the signal. Following sample code shows how to monitor and range an iBeacon:

```objectivec
[[[MMPReactiveCoreLocation instance]
   beaconMonitorWithProximityUUID:[[NSUUID alloc] initWithUUIDString:@"E2C56DB5-DFFB-48D2-B060-D0F5A71096E0"] identifier:@"com.example.apple-samplecode.AirLocate"]
   subscribeNext:^(MMPRCLBeaconEvent *event) {
       if (event.eventType == MMPRCLBeaconEventTypeRegionStateUpdated) {
           // region state is updated
           if (event.regionState == CLRegionStateInside) {
               // entering the beacon region
               CLBeaconRegion *beaconRegion = (CLBeaconRegion *)event.region;
               NSLog(@"Entering beacon region: %@, now ranging...", beaconRegion.identifier);
               
               // start ranging the beacon
               [[[MMPReactiveCoreLocation instance]
                  beaconRangeWithProximityUUID:beaconRegion.proximityUUID identifier:beaconRegion.identifier]
                  subscribeNext:^(MMPRCLBeaconEvent *rangingEvent) {
                      NSLog(@"There are %ld beacons ranged", [rangingEvent.rangedBeacons count]);
                      for (CLBeacon *beacon in rangingEvent.rangedBeacons) {
                          NSString *proximity = @"Unknown";
                          if (beacon.proximity == CLProximityFar) {
                              proximity = @"Far";
                          } else if (beacon.proximity == CLProximityNear) {
                              proximity = @"Near";
                          } else if (beacon.proximity == CLProximityImmediate) {
                              proximity = @"Immediate";
                          }
                          NSLog(@"Beacon UUID: %@, proximity: %@", beacon.proximityUUID, proximity);
                      }
                  }];
               
           } else if (event.regionState == CLRegionStateOutside) {
               // leaving the beacon region
           }
       }
   }];
```

Each of the signals will allocate it's own location manager and it will automatically destroyed when the signal is completed. 

Please check out the sample code for some more subtleties that you may need to be aware of.

## Roadmap

Please note that this library has not been extensively tested so there's bound to be bugs but I'm planning to use this in real world projects so it should be actively maintained. Contributions are welcomed.

* 0.5: Region monitoring.
* 0.6: All other remaining CoreLocation functions.
* 0.7: Unit tests.

## Documentation

Class reference is available here: [![Version](http://cocoapod-badges.herokuapp.com/v/MMPReactiveCoreLocation/badge.png)](http://cocoadocs.org/docsets/MMPReactiveCoreLocation)

## Contact

MMPCoreDataHelper is maintained by [Mamad Purbo](https://twitter.com/purubo)

## License

MMPReactiveCoreLocation is available under the MIT license. See the LICENSE file for more info.
