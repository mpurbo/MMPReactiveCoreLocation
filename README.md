# MMPReactiveCoreLocation

[![Version](http://cocoapod-badges.herokuapp.com/v/MMPReactiveCoreLocation/badge.png)](http://cocoadocs.org/docsets/MMPReactiveCoreLocation)
[![Platform](http://cocoapod-badges.herokuapp.com/p/MMPReactiveCoreLocation/badge.png)](http://cocoadocs.org/docsets/MMPReactiveCoreLocation)

MMPReactiveCoreLocation is a reactive library for using CoreLocation with ReactiveCocoa. Currently this library only provides
basic signal for receiving location updates.

Features:
* Singleton instance managing CLLocationManager(s). The instance manages one default location manager for app-wide location subscription, and short-lived location managers for one-time location requests.
* Easy to use signals for subscribing to location updates.
* Signals for customizable one-time location requests.

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

    [rcl start];
    return YES;
}
```
See the [class reference](http://cocoadocs.org/docsets/MMPReactiveCoreLocation) for detailed information on these configurations.

### One-time Location Requests.

Application-wide location subscription is usually only suitable for GPS-heavy location tracking applications. For most of other type of applications, occasional one-time location requests is usually sufficient and it's much less taxing on the battery. Following example shows how to request for such location:

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

## Documentation

Class reference is available here: [![Version](http://cocoapod-badges.herokuapp.com/v/MMPReactiveCoreLocation/badge.png)](http://cocoadocs.org/docsets/MMPReactiveCoreLocation)

## Contact

MMPCoreDataHelper is maintained by [Mamad Purbo](https://twitter.com/purubo)

## License

MMPReactiveCoreLocation is available under the MIT license. See the LICENSE file for more info.

