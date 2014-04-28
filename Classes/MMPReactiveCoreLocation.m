//
//  MMPReactiveCoreLocation.m
//
//  The MIT License (MIT)
//  Copyright (c) 2014 Mamad Purbo, purbo.org
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

#import "MMPReactiveCoreLocation.h"

#ifdef DEBUG
#   define MMPRxCL_LOG(fmt, ...) NSLog((@"%s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__);
#else
#   define MMPRxCL_LOG(...)
#endif

/**
 *  Delegate for custom location request.
 */
@interface MMPLocationManagerDelegate : NSObject<CLLocationManagerDelegate>

@end

@interface MMPReactiveCoreLocation()<CLLocationManagerDelegate>

@property(nonatomic, strong) CLLocationManager *defaultLocationManager;
@property(nonatomic, strong) RACSubject *defaultLocationManagerDelegateSubject;
@property(assign, nonatomic) MMPRCLLocationUpdateType lastUsedlocationUpdateType;
@property(nonatomic, strong, readwrite) CLLocation *lastKnownLocation;

@end

@implementation MMPReactiveCoreLocation

+ (instancetype)instance
{
    static dispatch_once_t once;
    static id shared = nil;
    dispatch_once(&once, ^{
        shared = [[super alloc] initSingletonInstance];
    });
    return shared;
}

- (instancetype)initSingletonInstance
{
    if (self = [super init]) {
        // default values (same as the default values for CLLocationManager)
        _pausesLocationUpdatesAutomatically = YES;
        _distanceFilter = kCLDistanceFilterNone;
        _desiredAccuracy = kCLLocationAccuracyBest;
        _activityType = CLActivityTypeOther;
        _locationUpdateType = MMPRCLLocationUpdateTypeStandard;
        
        _lastKnownLocation = nil;
        _defaultLocationManager = [[CLLocationManager alloc] init];
        _defaultLocationManager.delegate = self;
    }
    return self;
}

- (void)start
{
    _defaultLocationManager.pausesLocationUpdatesAutomatically = _pausesLocationUpdatesAutomatically;
    _defaultLocationManager.distanceFilter = _distanceFilter;
    _defaultLocationManager.desiredAccuracy = _desiredAccuracy;
    _defaultLocationManager.activityType = _activityType;
    
    // not thread-safe, should start/stop be thread safe?
    
    _lastUsedlocationUpdateType = _locationUpdateType;
    if (_locationUpdateType == MMPRCLLocationUpdateTypeStandard) {
        [_defaultLocationManager startUpdatingLocation];
    } else if (_locationUpdateType == MMPRCLLocationUpdateTypeSignificantChange) {
        [_defaultLocationManager startMonitoringSignificantLocationChanges];
    } else {
        NSLog(@"[WARN] Unknown location update type: %ld, not doing anything.", _locationUpdateType);
    }
}

- (void)stop
{
    // if subject has been used before, complete the subject first.
    @synchronized(self) {
        if (_defaultLocationManagerDelegateSubject) {
            [_defaultLocationManagerDelegateSubject sendCompleted];
            _defaultLocationManagerDelegateSubject = nil;
        }
    }
    
    if (_lastUsedlocationUpdateType == MMPRCLLocationUpdateTypeStandard) {
        [_defaultLocationManager stopUpdatingLocation];
    } else if (_locationUpdateType == MMPRCLLocationUpdateTypeSignificantChange) {
        [_defaultLocationManager stopMonitoringSignificantLocationChanges];
    }
}

- (RACSubject *)defaultLocationManagerDelegateSubject
{
    @synchronized(self) {
        if (!_defaultLocationManagerDelegateSubject) {
            _defaultLocationManagerDelegateSubject = [RACSubject subject];
        }
    }
    return _defaultLocationManagerDelegateSubject;
}

- (RACSignal *)locationSignal
{
    return [self defaultLocationManagerDelegateSubject];
}

- (RACSignal *)locationSignalWithDesiredAccuracy:(CLLocationAccuracy)desiredAccuracy
{
    //TODO: implement
    return nil;
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    if (![locations count])
        return;
    
    if (nil != self.lastKnownLocation && [[locations lastObject] isEqual:self.lastKnownLocation]) {
        return;
    }
    
    self.lastKnownLocation = [[locations lastObject] copy];
    MMPRxCL_LOG(@"default CL manager updated: (%f, %f, %f)", _lastKnownLocation.coordinate.latitude, _lastKnownLocation.coordinate.longitude, _lastKnownLocation.horizontalAccuracy)
    
    // send to default subject
    [[self defaultLocationManagerDelegateSubject] sendNext:[[locations lastObject] copy]];
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    MMPRxCL_LOG(@"default CL manager failed, error.code: %ld", error.code)
    
    // kCLErrorLocationUnknown: location is currently unknown, but CL will keep trying
    if (error.code != kCLErrorLocationUnknown) {
        [[self defaultLocationManagerDelegateSubject] sendError:error];
    }
}

@end

@implementation MMPLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    
}

@end