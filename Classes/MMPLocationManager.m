//
//  MMPLocationManager.m
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

#import "MMPLocationManager.h"
#import <ReactiveCocoa/RACEXTScope.h>

#ifdef DEBUG
#   define MMPRxCL_LOG(fmt, ...) NSLog((@"%s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__);
#else
#   define MMPRxCL_LOG(...)
#endif

NSString * const MMPLocationErrorDomain = @"MMPLocationErrorDomain";

typedef NS_ENUM(NSInteger, MMPLocationUpdateType) {
    MMPLocationUpdateTypeUnknown = 0,
    MMPLocationUpdateTypeStandard,
    MMPLocationUpdateTypeSignificantChange
};

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 80000

typedef NS_ENUM(NSInteger, MMPLocationAuthorizationType) {
    MMPLocationAuthorizationTypeAlways,
    MMPLocationAuthorizationTypeWhenInUse
};

#endif

@interface MMPLocationManager()<CLLocationManagerDelegate>

@property(assign, nonatomic) BOOL pausesLocationUpdatesAutomatically;
@property(assign, nonatomic) CLLocationDistance distanceFilter;
@property(assign, nonatomic) CLLocationAccuracy desiredAccuracy;
@property(assign, nonatomic) CLActivityType activityType;
@property(assign, nonatomic) NSTimeInterval locationAgeLimit;
@property(assign, nonatomic) NSTimeInterval timeout;
@property(assign, nonatomic) MMPLocationUpdateType updateType;
@property(assign, nonatomic) CLLocationDegrees headingFilter;
@property(assign, nonatomic) CLDeviceOrientation headingOrientation;
@property(copy) BOOL(^shouldDisplayHeadingCalibrationBlock)(CLLocationManager *);

@property(strong, nonatomic) CLLocationManager *locationManager;
@property(strong, nonatomic) CLLocation *lastKnownLocation;

@property(strong, nonatomic) RACSignal *stopSignal;
@property(strong, nonatomic) RACSignal *deferSignal;
@property(strong, nonatomic) RACSignal *regionCommandSignal;

@property(strong, nonatomic) RACSubject *errorSubject;

@property(strong, nonatomic) RACSubject *locationEventSubject;
@property(strong, nonatomic) RACSignal *regionEventSignal;
@property(strong, nonatomic) RACSubject *regionEventSubject;

@property(strong, nonatomic) RACSignal *locationSignal;
@property(strong, nonatomic) RACSubject *locationSubject;

@property(strong, nonatomic) RACSignal *headingSignal;
@property(strong, nonatomic) RACSubject *headingSubject;

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 80000

@property(strong, nonatomic) RACSignal *visitSignal;
@property(strong, nonatomic) RACSubject *visitSubject;

@property(assign, nonatomic) MMPLocationAuthorizationType authorizationType;

#endif

@property(strong, nonatomic) RACSubject *authorizationStatusSubject;

@end

@implementation MMPLocationManager

#pragma mark - General

- (id)init
{
    if (self = [super init]) {
        [self defaultSettings];
        [self resetSignals];
    }
    return self;
}

- (void)defaultSettings
{
    _pausesLocationUpdatesAutomatically = YES;
    _distanceFilter = kCLDistanceFilterNone;
    _desiredAccuracy = kCLLocationAccuracyBest;
    _activityType = CLActivityTypeOther;
    _locationAgeLimit = MMP_LOCATION_AGE_LIMIT_DEFAULT;
    _timeout = MMP_LOCATION_TIMEOUT_DEFAULT;
    _updateType = MMPLocationUpdateTypeUnknown;
    _headingFilter = 1;
    _headingOrientation = CLDeviceOrientationUnknown;
    self.shouldDisplayHeadingCalibrationBlock = nil;
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 80000
    _authorizationType = MMPLocationAuthorizationTypeWhenInUse;
#endif
}

- (void)resetSignals
{
    _updateType = MMPLocationUpdateTypeUnknown;
    
    // complete current subjects
    if (_errorSubject) [_errorSubject sendCompleted];
    if (_locationEventSubject) [_locationEventSubject sendCompleted];
    if (_regionEventSubject) [_regionEventSubject sendCompleted];
    if (_locationSubject) [_locationSubject sendCompleted];
    if (_headingSubject) [_headingSubject sendCompleted];
    // reset subjects
    self.errorSubject = nil;
    self.locationEventSubject = nil;
    self.regionEventSubject = nil;
    self.locationSubject = nil;
    self.headingSubject = nil;
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 80000
    // complete current subjects
    if (_visitSubject) [_visitSubject sendCompleted];
    // reset subjects
    self.visitSubject = nil;
    self.authorizationStatusSubject = nil;
#endif
    if (_authorizationStatusSubject) [_authorizationStatusSubject sendCompleted];
}

#pragma mark - Location settings

- (instancetype)pauseLocationUpdatesAutomatically
{
    _pausesLocationUpdatesAutomatically = YES;
    return self;
}

- (instancetype)pauseLocationUpdatesManually
{
    _pausesLocationUpdatesAutomatically = NO;
    return self;
}

- (instancetype)distanceFilter:(CLLocationDistance)distanceFilter
{
    _distanceFilter = distanceFilter;
    return self;
}

- (instancetype)desiredAccuracy:(CLLocationAccuracy)desiredAccuracy
{
    _desiredAccuracy = desiredAccuracy;
    return self;
}

- (instancetype)activityType:(CLActivityType)activityType
{
    _activityType = activityType;
    return self;
}

- (instancetype)locationAgeLimit:(NSTimeInterval)locationAgeLimit
{
    _locationAgeLimit = locationAgeLimit;
    return self;
}

- (instancetype)timeout:(NSTimeInterval)timeout
{
    _timeout = timeout;
    return self;
}

- (instancetype)stop:(RACSignal *)stopSignal
{
    self.stopSignal = stopSignal;
    
    @weakify(self)
    [self.stopSignal subscribeCompleted:^{
        @strongify(self)
        MMPRxCL_LOG(@"[INFO] location signal completed because stop signal is completed");
        [self resetSignals];
    }];
    
    return self;
}

- (instancetype)defer:(RACSignal *)deferSignal
{
    
    self.deferSignal = deferSignal;
    
    @weakify(self)
    [self.deferSignal subscribeNext:^(MMPDeferEvent *deferEvent) {
        @strongify(self)
        if (self.locationManager) {
            if (deferEvent.type == MMPDeferEventTypeAllow) {
                MMPRxCL_LOG(@"[INFO] Allowing deferred location updates");
                [self.locationManager allowDeferredLocationUpdatesUntilTraveled:deferEvent.untilTraveledDistance
                                                                        timeout:deferEvent.timeout];
            } else if (deferEvent.type == MMPDeferEventTypeAllow) {
                MMPRxCL_LOG(@"[INFO] Disallowing deferred location updates");
                [self.locationManager disallowDeferredLocationUpdates];
            } else {
                NSLog(@"[WARN] unknown defer event, ignoring event.");
            }
        } else {
            NSLog(@"[WARN] defer event received but location manager has not been activated!");
        }
    }];
    
    return self;
}

- (instancetype)regionCommand:(RACSignal *)regionCommandSignal
{
    self.regionCommandSignal = regionCommandSignal;
    return self;
}

- (instancetype)headingFilter:(CLLocationDegrees)headingFilter
{
    _headingFilter = headingFilter;
    return self;
}

- (instancetype)headingOrientation:(CLDeviceOrientation)headingOrientation
{
    _headingOrientation = headingOrientation;
    return self;
}

- (instancetype)shouldDisplayHeadingCalibration:(BOOL(^)(CLLocationManager *))block
{
    self.shouldDisplayHeadingCalibrationBlock = [block copy];
    return self;
}

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 80000
- (instancetype)authorizeAlways
{
    _authorizationType = MMPLocationAuthorizationTypeAlways;
    return self;
}

- (instancetype)authorizeWhenInUse
{
    _authorizationType = MMPLocationAuthorizationTypeWhenInUse;
    return self;
}

- (void)_authorize:(CLLocationManager *)locationManager with:(MMPLocationAuthorizationType)authorizationType
{
    if (authorizationType == MMPLocationAuthorizationTypeAlways) {
        if ([locationManager respondsToSelector:@selector(requestAlwaysAuthorization)]) {
            [locationManager requestAlwaysAuthorization];
        }
    } else if (authorizationType == MMPLocationAuthorizationTypeWhenInUse) {
        if ([locationManager respondsToSelector:@selector(requestWhenInUseAuthorization)]) {
            [locationManager requestWhenInUseAuthorization];
        }
    }
}
#endif

#pragma mark - Signals implementation

- (RACSignal *)errors
{
    return _errorSubject;
}

- (RACSignal *)locationsWithUpdateType:(MMPLocationUpdateType)locationUpdateType
{
    @synchronized(self) {
        
        if (_updateType != MMPLocationUpdateTypeUnknown) {
            if (_updateType != locationUpdateType) {
                // cannot start service with different update type
                NSLog(@"[ERROR] location service already started with type: %d", (int)locationUpdateType);
                [_errorSubject sendNext:[NSError errorWithDomain:MMPLocationErrorDomain
                                                            code:MMPLocationErrorServiceAlreadyStarted
                                                        userInfo:@{@"locationUpdateType" : @(_updateType)}]];
                return nil;
            }
        }
        
        if (!_locationSignal) {
            
            _updateType = locationUpdateType;
            self.locationSubject = [RACSubject subject];
            self.locationEventSubject = [RACSubject subject];
            
            @weakify(self)
            
            RACMulticastConnection *conn = [[RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
                
                @strongify(self)
                
                if (!self.locationManager) {
                    self.locationManager = [CLLocationManager new];
                    self.locationManager.delegate = self;
                } else {
                    NSLog(@"[ERROR] reusing location manager");
                    [subscriber sendError:[NSError errorWithDomain:MMPLocationErrorDomain
                                                              code:MMPLocationErrorServiceAlreadyStarted
                                                          userInfo:nil]];
                    return nil;
                }
                
                self.locationManager.pausesLocationUpdatesAutomatically = self.pausesLocationUpdatesAutomatically;
                self.locationManager.distanceFilter = self.distanceFilter;
                self.locationManager.desiredAccuracy = self.desiredAccuracy;
                self.locationManager.activityType = self.activityType;
                
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 80000
                [self _authorize:self.locationManager with:self.authorizationType];
#endif
                
                if (locationUpdateType == MMPLocationUpdateTypeStandard) {
                    [self.locationManager startUpdatingLocation];
                } else if (locationUpdateType == MMPLocationUpdateTypeSignificantChange) {
                    [self.locationManager startMonitoringSignificantLocationChanges];
                } else {
                    NSLog(@"[WARN] Unknown location update type: %ld, not doing anything.", (long)locationUpdateType);
                }
                
                MMPRxCL_LOG(@"[INFO] Location manager started");
                
                [self.locationSubject
                      subscribeNext:^(id x) {
                          MMPRxCL_LOG(@"[INFO] location subject: sending location to subscribers");
                          [subscriber sendNext:x];
                      }
                      error:^(NSError *error) {
                          [subscriber sendError:error];
                      }
                      completed:^{
                          MMPRxCL_LOG(@"[INFO] location subject: sending completed to subscribers");
                          [subscriber sendCompleted];
                      }];
                
                return [RACDisposable disposableWithBlock:^{
                    
                    self.locationManager.delegate = nil;
                    
                    if (locationUpdateType == MMPLocationUpdateTypeStandard) {
                        [self.locationManager stopUpdatingLocation];
                    } else if (locationUpdateType == MMPLocationUpdateTypeSignificantChange) {
                        [self.locationManager stopMonitoringSignificantLocationChanges];
                    } else {
                        NSLog(@"[WARN] Unknown location update type: %ld, not doing anything.", (long)locationUpdateType);
                    }
                    
                    self.locationManager = nil;
                    
                    MMPRxCL_LOG(@"[INFO] Location manager stopped");
                }];
                
            }] publish];
            
            [conn connect];
            self.locationSignal = conn.signal;
            
            self.authorizationStatusSubject = [RACSubject subject];
            self.errorSubject = [RACSubject subject];
        }
    }
    return _locationSignal;
}

- (RACSignal *)locationWithUpdateType:(MMPLocationUpdateType)locationUpdateType
{
    RACSubject *onceSubject = [RACSubject subject];
    RACSignal *onceSignal =
        self.timeout > 0 ?
        [onceSubject timeout:self.timeout onScheduler:[RACScheduler scheduler]] :
        onceSubject;
    
    RACSignal *signal = [[self stop:onceSignal] locationsWithUpdateType:locationUpdateType];
    
    return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        [signal
         subscribeNext:^(id x) {
             [subscriber sendNext:x];
             // complete the location service immediately after getting first next
             [onceSubject sendCompleted];
         }
         error:^(NSError *error) {
             [subscriber sendError:error];
         }
         completed:^{
             [subscriber sendCompleted];
         }];
        
        return nil;
    }];
    
}

- (RACSignal *)locations
{
    return [self locationsWithUpdateType:MMPLocationUpdateTypeStandard];
}

- (RACSignal *)location
{
    return [self locationWithUpdateType:MMPLocationUpdateTypeStandard];
}

- (RACSignal *)locationEvents
{
    return _locationEventSubject;
}

- (RACSignal *)significantLocationChanges
{
    return [[self authorizeAlways] locationsWithUpdateType:MMPLocationUpdateTypeSignificantChange];
}

- (RACSignal *)significantLocationChange
{
    return [[self authorizeAlways] locationWithUpdateType:MMPLocationUpdateTypeSignificantChange];
}

- (RACSignal *)headingUpdates
{
    @synchronized(self) {
        if (!_headingSignal) {
            
            self.headingSubject = [RACSubject subject];
            
            @weakify(self)
            
            RACMulticastConnection *conn = [[RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
                
                @strongify(self)
                
                if (!self.locationManager) {
                    self.locationManager = [CLLocationManager new];
                    self.locationManager.delegate = self;
                } else {
                    NSLog(@"[ERROR] reusing location manager");
                    [subscriber sendError:[NSError errorWithDomain:MMPLocationErrorDomain
                                                              code:MMPLocationErrorServiceAlreadyStarted
                                                          userInfo:nil]];
                    return nil;
                }
                
                self.locationManager.headingFilter = self.headingFilter;
                self.locationManager.headingOrientation = self.headingOrientation;
                
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 80000
                [self _authorize:self.locationManager with:self.authorizationType];
#endif
                
                [self.locationManager startUpdatingHeading];
                
                MMPRxCL_LOG(@"[INFO] Location manager started heading update");
                
                [self.headingSubject
                      subscribeNext:^(id x) {
                          MMPRxCL_LOG(@"[INFO] heading subject: sending heading to subscribers");
                          [subscriber sendNext:x];
                      }
                      error:^(NSError *error) {
                          [subscriber sendError:error];
                      }
                      completed:^{
                          MMPRxCL_LOG(@"[INFO] heading subject: sending completed to subscribers");
                          [subscriber sendCompleted];
                      }];
                
                return [RACDisposable disposableWithBlock:^{
                    
                    self.locationManager.delegate = nil;
                    [self.locationManager stopUpdatingHeading];
                    self.locationManager = nil;
                    
                    MMPRxCL_LOG(@"[INFO] Location manager stopped");
                }];
            }] publish];
            
            [conn connect];
            self.headingSignal = conn.signal;
            self.authorizationStatusSubject = [RACSubject subject];
            self.errorSubject = [RACSubject subject];
        }
    }
    return _headingSignal;
}

- (RACSignal *)regionStates
{
    return [[self headingUpdates] filter:^BOOL(MMPRegionEvent *event) {
        return event.type == MMPRegionEventTypeRegionStateDetermined;
    }];
}

- (RACSignal *)regionEvents
{
    @synchronized(self) {
        if (!_regionEventSignal) {
            
            self.headingSubject = [RACSubject subject];
            
            @weakify(self)
            
            RACMulticastConnection *conn = [[RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
                
                @strongify(self)
                
                if (!self.locationManager) {
                    self.locationManager = [CLLocationManager new];
                    self.locationManager.delegate = self;
                } else {
                    NSLog(@"[ERROR] reusing location manager");
                    [subscriber sendError:[NSError errorWithDomain:MMPLocationErrorDomain
                                                              code:MMPLocationErrorServiceAlreadyStarted
                                                          userInfo:nil]];
                    return nil;
                }
                
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 80000
                [self _authorize:self.locationManager with:self.authorizationType];
#endif
                
                [self.regionCommandSignal
                      subscribeNext:^(MMPRegionCommandEvent *ev) {
                          if (ev.type == MMPRegionCommandEventTypeStartMonitoring) {
                              [self.locationManager startMonitoringForRegion:ev.region];
                              MMPRxCL_LOG(@"[INFO] Location manager started monitoring region: %@", ev.region.identifier);
                          } else if (ev.type == MMPRegionCommandEventTypeStopMonitoring) {
                              [self.locationManager stopMonitoringForRegion:ev.region];
                              MMPRxCL_LOG(@"[INFO] Location manager stopped monitoring region: %@", ev.region.identifier);
                          } else if (ev.type == MMPRegionCommandEventTypeStartRanging) {
                              [self.locationManager startRangingBeaconsInRegion:(CLBeaconRegion *)ev.region];
                              MMPRxCL_LOG(@"[INFO] Location manager started ranging beacon region: %@", ev.region.identifier);
                          } else if (ev.type == MMPRegionCommandEventTypeStopRanging) {
                              [self.locationManager startRangingBeaconsInRegion:(CLBeaconRegion *)ev.region];
                              MMPRxCL_LOG(@"[INFO] Location manager started ranging beacon region: %@", ev.region.identifier);
                          } else if (ev.type == MMPRegionCommandEventTypeRequestState) {
                              [self.locationManager requestStateForRegion:ev.region];
                              MMPRxCL_LOG(@"[INFO] Location manager requesting state for region: %@", ev.region.identifier);
                          }
                      }];
                
                [self.regionEventSubject
                      subscribeNext:^(id x) {
                          MMPRxCL_LOG(@"[INFO] region event subject: sending region event to subscribers");
                          [subscriber sendNext:x];
                      }
                      error:^(NSError *error) {
                          [subscriber sendError:error];
                      }
                      completed:^{
                          MMPRxCL_LOG(@"[INFO] region event subject: sending completed to subscribers");
                          [subscriber sendCompleted];
                      }];
                
                return [RACDisposable disposableWithBlock:^{
                    
                    self.locationManager.delegate = nil;
                    self.locationManager = nil;
                    
                    MMPRxCL_LOG(@"[INFO] region event: location manager stopped");
                }];
            }] publish];
            
            [conn connect];
            self.regionEventSignal = conn.signal;
            self.authorizationStatusSubject = [RACSubject subject];
            self.errorSubject = [RACSubject subject];
        }
    }
    return _regionEventSignal;
}

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 80000

- (RACSignal *)visits
{
    @synchronized(self) {
        if (!_visitSignal) {
            
            self.visitSubject = [RACSubject subject];
            
            @weakify(self)
            
            RACMulticastConnection *conn = [[RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
                
                @strongify(self)
                
                if (!self.locationManager) {
                    self.locationManager = [CLLocationManager new];
                    self.locationManager.delegate = self;
                } else {
                    NSLog(@"[ERROR] reusing location manager");
                    [subscriber sendError:[NSError errorWithDomain:MMPLocationErrorDomain
                                                              code:MMPLocationErrorServiceAlreadyStarted
                                                          userInfo:nil]];
                    return nil;
                }
                
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 80000
                [self _authorize:self.locationManager with:self.authorizationType];
#endif
                
                [self.locationManager startMonitoringVisits];
                
                MMPRxCL_LOG(@"[INFO] Location manager started monitoring visits");
                
                [self.visitSubject
                      subscribeNext:^(id x) {
                          MMPRxCL_LOG(@"[INFO] visit subject: sending heading to subscribers");
                          [subscriber sendNext:x];
                      }
                      error:^(NSError *error) {
                          [subscriber sendError:error];
                      }
                      completed:^{
                          MMPRxCL_LOG(@"[INFO] visit subject: sending completed to subscribers");
                          [subscriber sendCompleted];
                      }];
                
                return [RACDisposable disposableWithBlock:^{
                    
                    self.locationManager.delegate = nil;
                    [self.locationManager stopMonitoringVisits];
                    self.locationManager = nil;
                    
                    MMPRxCL_LOG(@"[INFO] Location manager stopped");
                }];
            }] publish];
            
            [conn connect];
            self.headingSignal = conn.signal;
            self.authorizationStatusSubject = [RACSubject subject];
            self.errorSubject = [RACSubject subject];
        }
    }
    return _headingSignal;
}

- (RACSignal *)requestAuthorization
{
    if (!self.locationManager) {
        self.locationManager = [CLLocationManager new];
        self.locationManager.delegate = self;
        self.authorizationStatusSubject = [RACSubject subject];
        self.errorSubject = [RACSubject subject];
    }
    [self _authorize:self.locationManager with:self.authorizationType];
    return [self authorizationStatus];
}

#endif

- (RACSignal *)authorizationStatus
{
    return _authorizationStatusSubject;
}

#pragma mark - CLLocationManagerDelegate implementation

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
    MMPRxCL_LOG(@"[INFO] delegate: didUpdateLocations: (%f, %f, %f)", _lastKnownLocation.coordinate.latitude, _lastKnownLocation.coordinate.longitude, _lastKnownLocation.horizontalAccuracy)
    
    // send to default subject
    [_locationSubject sendNext:[newLocation copy]];
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    MMPRxCL_LOG(@"[INFO] delegate: didFailWithError: %@", error)
    [_errorSubject sendNext:error];
}

- (void)locationManager:(CLLocationManager *)manager didFinishDeferredUpdatesWithError:(NSError *)error
{
    MMPRxCL_LOG(@"[INFO] delegate: didFinishDeferredUpdatesWithError: %@", error)
    [_errorSubject sendNext:error];
}

- (void)locationManagerDidPauseLocationUpdates:(CLLocationManager *)manager
{
    MMPRxCL_LOG(@"[INFO] delegate: locationManagerDidPauseLocationUpdates")
    [_locationEventSubject sendNext:@(MMPLocationEventTypePaused)];
}

- (void)locationManagerDidResumeLocationUpdates:(CLLocationManager *)manager
{
    MMPRxCL_LOG(@"[INFO] delegate: locationManagerDidResumeLocationUpdates")
    [_locationEventSubject sendNext:@(MMPLocationEventTypeResumed)];
}

- (void)locationManager:(CLLocationManager *)manager didUpdateHeading:(CLHeading *)newHeading
{
    MMPRxCL_LOG(@"[INFO] delegate: didUpdateHeading")
    [_headingSubject sendNext:[newHeading copy]];
}

- (BOOL)locationManagerShouldDisplayHeadingCalibration:(CLLocationManager *)manager
{
    if (self.shouldDisplayHeadingCalibrationBlock) {
        return self.shouldDisplayHeadingCalibrationBlock(manager);
    }
    return NO;
}

- (void)locationManager:(CLLocationManager *)manager didEnterRegion:(CLRegion *)region
{
    [_regionEventSubject sendNext:[[MMPRegionEvent alloc] initWithType:MMPRegionEventTypeRegionEnter
                                                             forRegion:[region copy]]];
}

- (void)locationManager:(CLLocationManager *)manager didExitRegion:(CLRegion *)region
{
    [_regionEventSubject sendNext:[[MMPRegionEvent alloc] initWithType:MMPRegionEventTypeRegionExit
                                                             forRegion:[region copy]]];
}

- (void)locationManager:(CLLocationManager *)manager didDetermineState:(CLRegionState)state forRegion:(CLRegion *)region
{
    [_regionEventSubject sendNext:[[MMPRegionEvent alloc] initWithType:MMPRegionEventTypeRegionStateDetermined
                                                                 state:state
                                                             forRegion:[region copy]]];
}

- (void)locationManager:(CLLocationManager *)manager monitoringDidFailForRegion:(CLRegion *)region withError:(NSError *)error
{
    [_regionEventSubject sendNext:[[MMPRegionEvent alloc] initWithType:MMPRegionEventTypeRegionFailedMonitoring
                                                                 error:error
                                                             forRegion:[region copy]]];
}

- (void)locationManager:(CLLocationManager *)manager didStartMonitoringForRegion:(CLRegion *)region
{
    [_regionEventSubject sendNext:[[MMPRegionEvent alloc] initWithType:MMPRegionEventTypeRegionStartMonitoring
                                                             forRegion:[region copy]]];
}

- (void)locationManager:(CLLocationManager *)manager
        didRangeBeacons:(NSArray *)beacons
               inRegion:(CLBeaconRegion *)region
{
    [_regionEventSubject sendNext:[[MMPRegionEvent alloc] initWithType:MMPRegionEventTypeBeaconRanged
                                                               beacons:[beacons copy]
                                                             forRegion:[region copy]]];
}

- (void)locationManager:(CLLocationManager *)manager rangingBeaconsDidFailForRegion:(CLBeaconRegion *)region
              withError:(NSError *)error
{
    [_regionEventSubject sendNext:[[MMPRegionEvent alloc] initWithType:MMPRegionEventTypeBeaconFailedRanging
                                                                 error:error
                                                             forRegion:[region copy]]];
}

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 80000

- (void)locationManager:(CLLocationManager *)manager didVisit:(CLVisit *)visit
{
    [_visitSubject sendNext:[visit copy]];
}

#endif

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    [_authorizationStatusSubject sendNext:@(status)];
}

@end