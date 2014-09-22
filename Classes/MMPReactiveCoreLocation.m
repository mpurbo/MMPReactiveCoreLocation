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
#import <ReactiveCocoa/RACEXTScope.h>

#ifdef DEBUG
#   define MMPRxCL_LOG(fmt, ...) NSLog((@"%s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__);
#else
#   define MMPRxCL_LOG(...)
#endif

NSString * const MMPRCLSignalErrorDomain = @"MMPRCLSignalErrorDomain";
const NSInteger MMPRCLSignalErrorServiceUnavailable = 1;
const NSInteger MMPRCLSignalErrorServiceFailure = 2;

/**
 *  Delegate for custom location request.
 */
@interface MMPSignalDelegate : NSObject<CLLocationManagerDelegate>

@property(nonatomic, weak) id<RACSubscriber>subscriber;
@property(assign, nonatomic) NSTimeInterval locationAgeLimit;
@property(assign, nonatomic) BOOL signalOnce;

- (instancetype)initWithSubscriber:(id<RACSubscriber>)subscriber
                  locationAgeLimit:(NSTimeInterval)locationAgeLimit
                        signalOnce:(BOOL)signalOnce;

@end

@interface MMPBeaconSignalDelegate : NSObject<CLLocationManagerDelegate, CBPeripheralManagerDelegate>

@property(nonatomic, weak) id<RACSubscriber>subscriber;
@property(nonatomic, weak) CLLocationManager *locationManager;
@property(nonatomic, weak) CBPeripheralManager *peripheralManager;
@property(nonatomic, weak) CLBeaconRegion *beaconRegion;
@property(nonatomic, assign) MMPRCLBeaconSignalType beaconSignalType;
@property(nonatomic, assign) BOOL autoStartOnStatusChange;

- (instancetype)initWithSubscriber:(id<RACSubscriber>)subscriber
                   locationManager:(CLLocationManager *)locationManager
                 peripheralManager:(CBPeripheralManager *)peripheralManager
                      beaconRegion:(CLBeaconRegion *)beaconRegion
                  beaconSignalType:(MMPRCLBeaconSignalType)beaconSignalType
           autoStartOnStatusChange:(BOOL)autoStartOnStatusChange;

@end

@interface MMPRCLBeaconEvent()

@property (nonatomic, readwrite, assign) MMPRCLBeaconEventType eventType;
@property (nonatomic, readwrite, assign) CBPeripheralManagerState peripheralState;
@property (nonatomic, readwrite, assign) CLAuthorizationStatus authorizationStatus;
@property (nonatomic, readwrite, assign) CLRegionState regionState;
@property (nonatomic, readwrite, assign) CLRegion *region;
@property (nonatomic, readwrite, strong) NSArray *rangedBeacons;
@property (nonatomic, readwrite, strong) CLBeaconRegion *rangedRegion;

@end

@interface MMPReactiveCoreLocation()<CLLocationManagerDelegate>

@property(nonatomic, strong) CLLocationManager *defaultLocationManager;
@property(nonatomic, strong) RACSubject *defaultLocationManagerDelegateSubject;
@property(assign, nonatomic) MMPRCLLocationUpdateType lastUsedlocationUpdateType;
@property(nonatomic, strong, readwrite) CLLocation *lastKnownLocation;

@property(nonatomic, strong) NSMutableArray *signalDelegates;

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
        _locationAuthorizationType = MMPRCLLocationAuthorizationTypeWhenInUse;
        _locationAgeLimit = MMPRCL_LOCATION_AGE_LIMIT_DEFAULT;
        _defaultTimeout = MMPRCL_LOCATION_TIMEOUT_DEFAULT;
        
        _lastKnownLocation = nil;
        _defaultLocationManager = [[CLLocationManager alloc] init];
        _defaultLocationManager.delegate = self;
        
        self.signalDelegates = [NSMutableArray array];
    }
    return self;
}

- (BOOL)locationServicesAvailable
{
    return
        [CLLocationManager locationServicesEnabled] &&
        [CLLocationManager authorizationStatus] != kCLAuthorizationStatusDenied &&
        [CLLocationManager authorizationStatus] != kCLAuthorizationStatusRestricted;
}

- (void)sendUnavailableError
{
    @synchronized(self) {
        if (_defaultLocationManagerDelegateSubject) {
            [_defaultLocationManagerDelegateSubject sendError:[NSError errorWithDomain:MMPRCLSignalErrorDomain
                                                                                  code:MMPRCLSignalErrorServiceUnavailable
                                                                              userInfo:nil]];
            _defaultLocationManagerDelegateSubject = nil;
        }
    }
}

- (void)start
{
    // start only if location service available
    if (![self locationServicesAvailable]) {
        [self sendUnavailableError];
    }
    
    _defaultLocationManager.pausesLocationUpdatesAutomatically = _pausesLocationUpdatesAutomatically;
    _defaultLocationManager.distanceFilter = _distanceFilter;
    _defaultLocationManager.desiredAccuracy = _desiredAccuracy;
    _defaultLocationManager.activityType = _activityType;
    
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 80000
    if (_locationAuthorizationType == MMPRCLLocationAuthorizationTypeAlways) {
        if ([_defaultLocationManager respondsToSelector:@selector(requestAlwaysAuthorization)]) {
            [_defaultLocationManager requestAlwaysAuthorization];
        }
    } else if (_locationAuthorizationType == MMPRCLLocationAuthorizationTypeWhenInUse) {
        if ([_defaultLocationManager respondsToSelector:@selector(requestWhenInUseAuthorization)]) {
            [_defaultLocationManager requestWhenInUseAuthorization];
        }
    }
#endif
    
    // not thread-safe, should start/stop be thread safe?
    
    _lastUsedlocationUpdateType = _locationUpdateType;
    if (_locationUpdateType == MMPRCLLocationUpdateTypeStandard) {
        [_defaultLocationManager startUpdatingLocation];
    } else if (_locationUpdateType == MMPRCLLocationUpdateTypeSignificantChange) {
        [_defaultLocationManager startMonitoringSignificantLocationChanges];
    } else {
        NSLog(@"[WARN] Unknown location update type: %ld, not doing anything.", (long)_locationUpdateType);
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

#pragma mark Standard location signals

- (RACSignal *)locationSignal
{
    return [self defaultLocationManagerDelegateSubject];
}

- (RACSignal *)locationSignalWithAccuracy:(CLLocationAccuracy)desiredAccuracy
{
    return [[self defaultLocationManagerDelegateSubject] filter:^BOOL(CLLocation *location) {
        return (location.horizontalAccuracy <= desiredAccuracy);
    }];
}

- (RACSignal *)locationSignalWithAccuracy:(CLLocationAccuracy)desiredAccuracy timeout:(NSTimeInterval)timeout
{
    return [[[self defaultLocationManagerDelegateSubject]
                   takeUntilBlock:^BOOL(CLLocation *location) {
                       return (location.horizontalAccuracy <= desiredAccuracy);
                   }]
                   timeout:timeout onScheduler:[RACScheduler scheduler]];
}

#pragma mark Common custom location signal

- (RACSignal *)customLocationSignalWithPausesLocationUpdatesAutomatically:(BOOL)pausesLocationUpdatesAutomatically
                                                           distanceFilter:(CLLocationDistance)distanceFilter
                                                          desiredAccuracy:(CLLocationAccuracy)desiredAccuracy
                                                             activityType:(CLActivityType)activityType
                                                       locationUpdateType:(MMPRCLLocationUpdateType)locationUpdateType
                                                locationAuthorizationType:(MMPRCLLocationAuthorizationType)authorizationType
                                                         locationAgeLimit:(NSTimeInterval)locationAgeLimit
                                                                  timeout:(NSTimeInterval)timeout
                                                               signalOnce:(BOOL)signalOnce
{
    @weakify(self)
    
    RACSignal *signal = [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        
        @strongify(self)
        
        CLLocationManager *locationManager = [[CLLocationManager alloc] init];
        MMPSignalDelegate *delegate = [[MMPSignalDelegate alloc] initWithSubscriber:subscriber
                                                                   locationAgeLimit:locationAgeLimit
                                                                         signalOnce:signalOnce];
        // so that the delegate can be retained
        [self.signalDelegates addObject:delegate];
        
        locationManager.pausesLocationUpdatesAutomatically = pausesLocationUpdatesAutomatically;
        locationManager.distanceFilter = distanceFilter;
        locationManager.desiredAccuracy = desiredAccuracy;
        locationManager.activityType = activityType;
        locationManager.delegate = delegate;
        
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 80000
        if (authorizationType == MMPRCLLocationAuthorizationTypeAlways) {
            if ([locationManager respondsToSelector:@selector(requestAlwaysAuthorization)]) {
                [locationManager requestAlwaysAuthorization];
            }
        } else if (authorizationType == MMPRCLLocationAuthorizationTypeWhenInUse) {
            if ([locationManager respondsToSelector:@selector(requestWhenInUseAuthorization)]) {
                [locationManager requestWhenInUseAuthorization];
            }
        }
#endif
        
        if (locationUpdateType == MMPRCLLocationUpdateTypeStandard) {
            [locationManager startUpdatingLocation];
        } else if (locationUpdateType == MMPRCLLocationUpdateTypeSignificantChange) {
            [locationManager startMonitoringSignificantLocationChanges];
        } else {
            NSLog(@"[WARN] Unknown location update type: %ld, not doing anything.", (long)locationUpdateType);
        }
        
        MMPRxCL_LOG(@"custom CL manager started")
        
        return [RACDisposable disposableWithBlock:^{
            
            locationManager.delegate = nil; // fix delegate leak bug
            
            if (locationUpdateType == MMPRCLLocationUpdateTypeStandard) {
                [locationManager stopUpdatingLocation];
            } else if (locationUpdateType == MMPRCLLocationUpdateTypeSignificantChange) {
                [locationManager stopMonitoringSignificantLocationChanges];
            } else {
                NSLog(@"[WARN] Unknown location update type: %ld, not doing anything.", (long)locationUpdateType);
            }
            
            [self.signalDelegates removeObject:delegate];
            
            MMPRxCL_LOG(@"custom CL manager stopped, number of delegates = %ld", [self.signalDelegates count])
        }];
    }];
    
    if (timeout > 0) {
        return [signal timeout:timeout onScheduler:[RACScheduler scheduler]];
    } else {
        return signal;
    }
}

#pragma mark One-time location signals

- (RACSignal *)singleLocationSignal
{
    return [self singleLocationSignalWithPausesLocationUpdatesAutomatically:_pausesLocationUpdatesAutomatically
                                                             distanceFilter:_distanceFilter
                                                            desiredAccuracy:_desiredAccuracy
                                                               activityType:_activityType
                                                         locationUpdateType:MMPRCLLocationUpdateTypeStandard
                                                           locationAgeLimit:_locationAgeLimit
                                                                    timeout:self.defaultTimeout];
}

- (RACSignal *)singleLocationSignalWithAccuracy:(CLLocationAccuracy)desiredAccuracy
{
    return [self singleLocationSignalWithPausesLocationUpdatesAutomatically:_pausesLocationUpdatesAutomatically
                                                             distanceFilter:_distanceFilter
                                                            desiredAccuracy:desiredAccuracy
                                                               activityType:_activityType
                                                         locationUpdateType:MMPRCLLocationUpdateTypeStandard
                                                           locationAgeLimit:_locationAgeLimit
                                                                    timeout:self.defaultTimeout];
}

- (RACSignal *)singleLocationSignalWithAccuracy:(CLLocationAccuracy)desiredAccuracy timeout:(NSTimeInterval)timeout
{
    return [self singleLocationSignalWithPausesLocationUpdatesAutomatically:_pausesLocationUpdatesAutomatically
                                                             distanceFilter:_distanceFilter
                                                            desiredAccuracy:desiredAccuracy
                                                               activityType:_activityType
                                                         locationUpdateType:MMPRCLLocationUpdateTypeStandard
                                                           locationAgeLimit:_locationAgeLimit
                                                                    timeout:timeout];
}

- (RACSignal *)singleLocationSignalWithPausesLocationUpdatesAutomatically:(BOOL)pausesLocationUpdatesAutomatically
                                                           distanceFilter:(CLLocationDistance)distanceFilter
                                                          desiredAccuracy:(CLLocationAccuracy)desiredAccuracy
                                                             activityType:(CLActivityType)activityType
                                                       locationUpdateType:(MMPRCLLocationUpdateType)locationUpdateType
                                                         locationAgeLimit:(NSTimeInterval)locationAgeLimit
                                                                  timeout:(NSTimeInterval)timeout
{
    return [self customLocationSignalWithPausesLocationUpdatesAutomatically:pausesLocationUpdatesAutomatically
                                                             distanceFilter:distanceFilter
                                                            desiredAccuracy:desiredAccuracy
                                                               activityType:activityType
                                                         locationUpdateType:locationUpdateType
                                                  locationAuthorizationType:MMPRCLLocationAuthorizationTypeWhenInUse
                                                           locationAgeLimit:locationAgeLimit
                                                                    timeout:timeout
                                                                 signalOnce:YES];
}

#pragma mark Automatic location signals

- (RACSignal *)autoLocationSignalWithLocationUpdateType:(MMPRCLLocationUpdateType)locationUpdateType
{
    return [self autoLocationSignalWithPausesLocationUpdatesAutomatically:_pausesLocationUpdatesAutomatically
                                                           distanceFilter:_distanceFilter
                                                          desiredAccuracy:_desiredAccuracy
                                                             activityType:_activityType
                                                       locationUpdateType:locationUpdateType
                                                         locationAgeLimit:_locationAgeLimit];
}

- (RACSignal *)autoLocationSignalWithAccuracy:(CLLocationAccuracy)desiredAccuracy
                           locationUpdateType:(MMPRCLLocationUpdateType)locationUpdateType;
{
    return [self autoLocationSignalWithPausesLocationUpdatesAutomatically:_pausesLocationUpdatesAutomatically
                                                           distanceFilter:_distanceFilter
                                                          desiredAccuracy:desiredAccuracy
                                                             activityType:_activityType
                                                       locationUpdateType:locationUpdateType
                                                         locationAgeLimit:_locationAgeLimit];
}

- (RACSignal *)autoLocationSignalWithPausesLocationUpdatesAutomatically:(BOOL)pausesLocationUpdatesAutomatically
                                                         distanceFilter:(CLLocationDistance)distanceFilter
                                                        desiredAccuracy:(CLLocationAccuracy)desiredAccuracy
                                                           activityType:(CLActivityType)activityType
                                                     locationUpdateType:(MMPRCLLocationUpdateType)locationUpdateType
                                                       locationAgeLimit:(NSTimeInterval)locationAgeLimit
{
    return [self autoLocationSignalWithPausesLocationUpdatesAutomatically:pausesLocationUpdatesAutomatically
                                                           distanceFilter:distanceFilter
                                                          desiredAccuracy:desiredAccuracy
                                                             activityType:activityType
                                                       locationUpdateType:locationUpdateType
                                                locationAuthorizationType:(locationUpdateType == MMPRCLLocationUpdateTypeSignificantChange) ? MMPRCLLocationAuthorizationTypeAlways : _locationAuthorizationType // significant change requires "Always"
                                                         locationAgeLimit:locationAgeLimit];
}

- (RACSignal *)autoLocationSignalWithPausesLocationUpdatesAutomatically:(BOOL)pausesLocationUpdatesAutomatically
                                                         distanceFilter:(CLLocationDistance)distanceFilter
                                                        desiredAccuracy:(CLLocationAccuracy)desiredAccuracy
                                                           activityType:(CLActivityType)activityType
                                                     locationUpdateType:(MMPRCLLocationUpdateType)locationUpdateType
                                              locationAuthorizationType:(MMPRCLLocationAuthorizationType)authorizationType
                                                       locationAgeLimit:(NSTimeInterval)locationAgeLimit
{
    return [self customLocationSignalWithPausesLocationUpdatesAutomatically:pausesLocationUpdatesAutomatically
                                                             distanceFilter:distanceFilter
                                                            desiredAccuracy:desiredAccuracy
                                                               activityType:activityType
                                                         locationUpdateType:locationUpdateType
                                                  locationAuthorizationType:authorizationType
                                                           locationAgeLimit:locationAgeLimit
                                                                    timeout:MMPRCL_LOCATION_TIMEOUT_DEFAULT
                                                                 signalOnce:NO];
}

#pragma mark Beacon location signals

- (RACSignal *)beaconWithProximityUUID:(NSUUID *)proximityUUID
                                 major:(NSNumber *)major
                                 minor:(NSNumber *)minor
                            identifier:(NSString *)identifier
                         notifyOnEntry:(BOOL)notifyOnEntry
                          notifyOnExit:(BOOL)notifyOnExit
             notifyEntryStateOnDisplay:(BOOL)notifyEntryStateOnDisplay
                      beaconSignalType:(MMPRCLBeaconSignalType)beaconSignalType
               autoStartOnStatusChange:(BOOL)autoStartOnStatusChange
{
    @weakify(self)
    
    RACSignal *signal = [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        
        @strongify(self)
        
        // initialize beacon region
        
        CLBeaconRegion *beaconRegion = nil;
        if (major) {
            if (minor) {
                beaconRegion = [[CLBeaconRegion alloc] initWithProximityUUID:proximityUUID
                                                                       major:[major unsignedIntegerValue]
                                                                       minor:[minor unsignedIntegerValue]
                                                                  identifier:identifier];
            } else {
                beaconRegion = [[CLBeaconRegion alloc] initWithProximityUUID:proximityUUID
                                                                       major:[major unsignedIntegerValue]
                                                                  identifier:identifier];
            }
        } else {
            beaconRegion = [[CLBeaconRegion alloc] initWithProximityUUID:proximityUUID
                                                              identifier:identifier];
        }
        beaconRegion.notifyEntryStateOnDisplay = notifyEntryStateOnDisplay;
        beaconRegion.notifyOnEntry = notifyOnEntry;
        beaconRegion.notifyOnExit = notifyOnExit;
        
        // managers
        
        CLLocationManager *locationManager = [[CLLocationManager alloc] init];
        CBPeripheralManager *peripheralManager = [[CBPeripheralManager alloc] init];
        
        // setup delegate
        
        MMPBeaconSignalDelegate *delegate = [[MMPBeaconSignalDelegate alloc] initWithSubscriber:subscriber
                                                                                locationManager:locationManager
                                                                              peripheralManager:peripheralManager
                                                                                   beaconRegion:beaconRegion
                                                                               beaconSignalType:beaconSignalType
                                                                        autoStartOnStatusChange:autoStartOnStatusChange];
        
        locationManager.delegate = delegate;
        peripheralManager.delegate = delegate;
        
        // so that the delegate can be retained
        [self.signalDelegates addObject:delegate];
        
        if (beaconSignalType == MMPRCLBeaconSignalTypeMonitor) {
            [locationManager startMonitoringForRegion:beaconRegion];
            MMPRxCL_LOG(@"Starting to monitor region: %@", beaconRegion.proximityUUID)
        } else if (beaconSignalType == MMPRCLBeaconSignalTypeRange) {
            [locationManager startRangingBeaconsInRegion:beaconRegion];
            MMPRxCL_LOG(@"Starting to range region: %@", beaconRegion.proximityUUID)
        } else {
            NSLog(@"[WARN] Unknown beaconSignalType: %ld, signal won't generate event.", beaconSignalType);
        }
        
        return [RACDisposable disposableWithBlock:^{
            
            locationManager.delegate = nil;
            peripheralManager.delegate = nil;
            
            if (beaconSignalType == MMPRCLBeaconSignalTypeMonitor) {
                [locationManager stopMonitoringForRegion:beaconRegion];
            } else if (beaconSignalType == MMPRCLBeaconSignalTypeRange) {
                [locationManager stopRangingBeaconsInRegion:beaconRegion];
            }
            
            [self.signalDelegates removeObject:delegate];
            
            MMPRxCL_LOG(@"custom CL manager stopped, number of delegates = %ld", [self.signalDelegates count])
        }];
    }];
    
    return signal;
}

- (RACSignal *)beaconMonitorWithProximityUUID:(NSUUID *)proximityUUID
                                   identifier:(NSString *)identifier
{
    return [self beaconWithProximityUUID:proximityUUID
                                   major:nil
                                   minor:nil
                              identifier:identifier
                           notifyOnEntry:YES
                            notifyOnExit:YES
               notifyEntryStateOnDisplay:YES
                        beaconSignalType:MMPRCLBeaconSignalTypeMonitor
                 autoStartOnStatusChange:YES];
}

- (RACSignal *)beaconRangeWithProximityUUID:(NSUUID *)proximityUUID
                                 identifier:(NSString *)identifier
{
    return [self beaconWithProximityUUID:proximityUUID
                                   major:nil
                                   minor:nil
                              identifier:identifier
                           notifyOnEntry:YES
                            notifyOnExit:YES
               notifyEntryStateOnDisplay:YES
                        beaconSignalType:MMPRCLBeaconSignalTypeRange
                 autoStartOnStatusChange:YES];
}

#pragma mark CLLocationManagerDelegate implementation

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    // get latest location
    if (![locations count]) return;
    CLLocation *newLocation = [locations lastObject];
    
    // test the age of the location measurement to determine if the measurement is cached
    // in most cases you will not want to rely on cached measurements
    NSTimeInterval locationAge = -[newLocation.timestamp timeIntervalSinceNow];
    if (locationAge > _locationAgeLimit) return;
    
    // test that the horizontal accuracy does not indicate an invalid measurement
    if (newLocation.horizontalAccuracy < 0) return;
    
    self.lastKnownLocation = [newLocation copy];
    //MMPRxCL_LOG(@"default CL manager updated: (%f, %f, %f)", _lastKnownLocation.coordinate.latitude, _lastKnownLocation.coordinate.longitude, _lastKnownLocation.horizontalAccuracy)
    
    // send to default subject
    [[self defaultLocationManagerDelegateSubject] sendNext:[newLocation copy]];
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    // kCLErrorLocationUnknown: location is currently unknown, but CL will keep trying
    if (error.code != kCLErrorLocationUnknown) {
        MMPRxCL_LOG(@"default CL manager failed, error.code: %ld", (long)error.code)
        @synchronized(self) {
            if (_defaultLocationManagerDelegateSubject) {
                [_defaultLocationManagerDelegateSubject sendError:error];
                _defaultLocationManagerDelegateSubject = nil;
            }
        }
    }
}

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    if (status == kCLAuthorizationStatusDenied || status == kCLAuthorizationStatusRestricted) {
        [self sendUnavailableError];
    }
}

@end

#pragma mark - MMPSignalDelegate implementation

@implementation MMPSignalDelegate

- (instancetype)initWithSubscriber:(id<RACSubscriber>)subscriber
                  locationAgeLimit:(NSTimeInterval)locationAgeLimit
                        signalOnce:(BOOL)signalOnce
{
    if (self = [super init]) {
        self.subscriber = subscriber;
        self.locationAgeLimit = locationAgeLimit;
        self.signalOnce = signalOnce;
    }
    return self;
}

#pragma mark CLLocationManagerDelegate implementation

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    // get latest location
    if (![locations count]) return;
    CLLocation *newLocation = [locations lastObject];
    
    // test the age of the location measurement to determine if the measurement is cached
    // in most cases you will not want to rely on cached measurements
    NSTimeInterval locationAge = -[newLocation.timestamp timeIntervalSinceNow];
    if (locationAge > _locationAgeLimit) return;
    
    // test that the horizontal accuracy does not indicate an invalid measurement
    if (newLocation.horizontalAccuracy < 0) return;
    
    MMPRxCL_LOG(@"custom CL manager updated: (%f, %f, %f)", newLocation.coordinate.latitude, newLocation.coordinate.longitude, newLocation.horizontalAccuracy)
    
    [_subscriber sendNext:[newLocation copy]];
    
    if (_signalOnce) {
        // subscriber only wants one signal
        [_subscriber sendCompleted];
    }
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    if (error.code != kCLErrorLocationUnknown) {
        [_subscriber sendError:[NSError errorWithDomain:MMPRCLSignalErrorDomain
                                                   code:MMPRCLSignalErrorServiceFailure
                                               userInfo:@{@"error" : error}]];
    }
}

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    if (status == kCLAuthorizationStatusDenied || status == kCLAuthorizationStatusRestricted) {
        [_subscriber sendError:[NSError errorWithDomain:MMPRCLSignalErrorDomain
                                                   code:MMPRCLSignalErrorServiceUnavailable
                                               userInfo:nil]];
    }
}

@end

#pragma mark - MMPBeaconSignalDelegate implementation

@implementation MMPBeaconSignalDelegate

- (instancetype)initWithSubscriber:(id<RACSubscriber>)subscriber
                   locationManager:(CLLocationManager *)locationManager
                 peripheralManager:(CBPeripheralManager *)peripheralManager
                      beaconRegion:(CLBeaconRegion *)beaconRegion
                  beaconSignalType:(MMPRCLBeaconSignalType)beaconSignalType
           autoStartOnStatusChange:(BOOL)autoStartOnStatusChange
{
    if (self = [super init]) {
        self.subscriber = subscriber;
        self.locationManager = locationManager;
        self.peripheralManager = peripheralManager;
        self.beaconRegion = beaconRegion;
        self.beaconSignalType = beaconSignalType;
        self.autoStartOnStatusChange = autoStartOnStatusChange;
    }
    return self;
}

- (BOOL)available
{
    return ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorized &&
            self.peripheralManager.state == CBPeripheralManagerStatePoweredOn);
}

#pragma mark CLLocationManagerDelegate implementation

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    // notify subscriber on location authorization event change
    MMPRCLBeaconEvent *event = [[MMPRCLBeaconEvent alloc] init];
    event.eventType = MMPRCLBeaconEventTypeAuthorizationStatusUpdated;
    event.authorizationStatus = status;
    [_subscriber sendNext:event];
    
    if (_autoStartOnStatusChange) {
        // start/stop monitoring/ranging automatically on status change
        if (status == kCLAuthorizationStatusAuthorized) {
            if ([self available]) {
                if (_beaconSignalType == MMPRCLBeaconSignalTypeMonitor) {
                    [_locationManager startMonitoringForRegion:_beaconRegion];
                } else if (_beaconSignalType == MMPRCLBeaconSignalTypeRange) {
                    [_locationManager startRangingBeaconsInRegion:_beaconRegion];
                }
            } else {
                NSLog(@"[WARN] Location manager is authorized but bluetooth is not on, beacon monitoring/ranging will NOT be started");
            }
        } else {
            if (_beaconSignalType == MMPRCLBeaconSignalTypeMonitor) {
                [_locationManager stopMonitoringForRegion:_beaconRegion];
            } else if (_beaconSignalType == MMPRCLBeaconSignalTypeRange) {
                [_locationManager stopRangingBeaconsInRegion:_beaconRegion];
            }
        }
    }
}

- (void)locationManager:(CLLocationManager *)manager didDetermineState:(CLRegionState)state forRegion:(CLRegion *)region
{
    MMPRCLBeaconEvent *event = [[MMPRCLBeaconEvent alloc] init];
    event.eventType = MMPRCLBeaconEventTypeRegionStateUpdated;
    event.regionState = state;
    event.region = [region copy];
    [_subscriber sendNext:event];
}

- (void)locationManager:(CLLocationManager*)manager didRangeBeacons:(NSArray*)beacons inRegion:(CLBeaconRegion*)region
{
    MMPRCLBeaconEvent *event = [[MMPRCLBeaconEvent alloc] init];
    event.eventType = MMPRCLBeaconEventTypeRanged;
    event.rangedBeacons = [beacons copy];
    event.rangedRegion = [region copy];
    [_subscriber sendNext:event];
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    [_subscriber sendError:error];
}

- (void)locationManager:(CLLocationManager *)manager monitoringDidFailForRegion:(CLRegion *)region withError:(NSError *)error
{
    [_subscriber sendError:error];
}

- (void)locationManager:(CLLocationManager *)manager rangingBeaconsDidFailForRegion:(CLBeaconRegion *)region withError:(NSError *)error
{
    [_subscriber sendError:error];
}

#pragma mark CBPeripheralManagerDelegate implementation

- (void)peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheral {
    
    // notify subscriber on bluetooth event
    MMPRCLBeaconEvent *event = [[MMPRCLBeaconEvent alloc] init];
    event.eventType = MMPRCLBeaconEventTypePeripheralStateUpdated;
    event.peripheralState = peripheral.state;
    [_subscriber sendNext:event];
    
    if (_autoStartOnStatusChange) {
        // start/stop monitoring/ranging automatically on status change
        if (peripheral.state == CBPeripheralManagerStatePoweredOn) {
            MMPRxCL_LOG(@"Peripheral state updated to: CBPeripheralManagerStatePoweredOn")
            // because bluetooth has just been turned on, resume monitoring/ranging
            if ([self available]) {
                if (_beaconSignalType == MMPRCLBeaconSignalTypeMonitor) {
                    [_locationManager startMonitoringForRegion:_beaconRegion];
                } else if (_beaconSignalType == MMPRCLBeaconSignalTypeRange) {
                    [_locationManager startRangingBeaconsInRegion:_beaconRegion];
                }
            } else {
                NSLog(@"[WARN] Bluetooth turned on but location manager is not authorized, beacon monitoring/ranging will NOT be started");
            }
        } else {
            MMPRxCL_LOG(@"Peripheral state updated to: %ld", peripheral.state)
            // bluetooth is not on, stop monitoring/ranging
            if (_beaconSignalType == MMPRCLBeaconSignalTypeMonitor) {
                [_locationManager stopMonitoringForRegion:_beaconRegion];
            } else if (_beaconSignalType == MMPRCLBeaconSignalTypeRange) {
                [_locationManager stopRangingBeaconsInRegion:_beaconRegion];
            }
        }
    }
}

@end

@implementation MMPRCLBeaconEvent

@end

