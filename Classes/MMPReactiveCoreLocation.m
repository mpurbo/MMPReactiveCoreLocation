//
//  MMPReactiveCoreLocation.m
//  Pods
//
//  Created by Purbo Mohamad on 2/10/15.
//
//

#import "MMPReactiveCoreLocation.h"
#import <ReactiveCocoa/RACEXTScope.h>

#ifdef DEBUG
#   define MMPRxCL_LOG(fmt, ...) NSLog((@"%s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__);
#else
#   define MMPRxCL_LOG(...)
#endif

typedef NS_ENUM(NSInteger, MMPLocationServiceType) {
    MMPLocationServiceTypeUnknown = 0,
    MMPLocationServiceTypeAuthOnly,
    MMPLocationServiceTypeLocation,
    MMPLocationServiceTypeSignificantChange,
    MMPLocationServiceTypeRegionMonitoring
};

@interface MMPLocationManagerSettings : NSObject

@property(assign, nonatomic) MMPLocationServiceType locationServiceType;

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 80000
@property(assign, nonatomic) MMPLocationAuthorizationType authorizationType;
#endif

@property(assign, nonatomic) BOOL pausesLocationUpdatesAutomatically;
@property(assign, nonatomic) CLLocationDistance distanceFilter;
@property(assign, nonatomic) CLLocationAccuracy desiredAccuracy;
@property(assign, nonatomic) CLActivityType activityType;
@property(strong, nonatomic) NSMutableArray *regions;

@end

@implementation MMPLocationManagerSettings

@end

@interface MMPLocationManagerResource : NSObject<MMPResource, CLLocationManagerDelegate>

@property (nonatomic, strong) MMPLocationManagerSettings *settings;
@property (nonatomic, strong) CLLocationManager *manager;
@property (nonatomic, strong) RACSignal *signal;

- (id)initWithSettings:(MMPLocationManagerSettings *)settings;
- (void)stop;

@end

@implementation MMPLocationManagerResource

- (id)initWithSettings:(MMPLocationManagerSettings *)settings {
    self = [super init];
    if (self) {
        self.manager = [CLLocationManager new];
        _manager.delegate = self;
        self.settings = settings;
        self.signal = nil;
    }
    return self;
}

- (void)stop {
    if (_settings.locationServiceType == MMPLocationServiceTypeLocation) {
        [_manager stopUpdatingLocation];
        MMPRxCL_LOG(@"[INFO] Location manager stopped updating location");
    } else if (_settings.locationServiceType == MMPLocationServiceTypeSignificantChange) {
        [_manager stopMonitoringSignificantLocationChanges];
        MMPRxCL_LOG(@"[INFO] Location manager stopped monitoring significant location change");
    } else if (_settings.locationServiceType == MMPLocationServiceTypeRegionMonitoring) {
        for (CLRegion *region in _settings.regions) {
            [_manager stopMonitoringForRegion:region];
        }
    }
}

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 80000
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

- (void)_startManager {
    
    if (_settings.locationServiceType == MMPLocationServiceTypeLocation ||
        _settings.locationServiceType == MMPLocationServiceTypeSignificantChange) {
        
        _manager.pausesLocationUpdatesAutomatically = _settings.pausesLocationUpdatesAutomatically;
        _manager.distanceFilter = _settings.distanceFilter;
        _manager.desiredAccuracy = _settings.desiredAccuracy;
        _manager.activityType = _settings.activityType;
    }
    
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 80000
    [self _authorize:_manager with:_settings.authorizationType];
#endif
    
    if (_settings.locationServiceType == MMPLocationServiceTypeLocation) {
        [_manager startUpdatingLocation];
        MMPRxCL_LOG(@"[INFO] Location manager started updating location")
    } else if (_settings.locationServiceType == MMPLocationServiceTypeSignificantChange) {
        [_manager startMonitoringSignificantLocationChanges];
        MMPRxCL_LOG(@"[INFO] Location manager started monitoring significant location change")
    } else if (_settings.locationServiceType == MMPLocationServiceTypeRegionMonitoring) {
        for (CLRegion *region in _settings.regions) {
            [_manager startMonitoringForRegion:region];
        }
        MMPRxCL_LOG(@"[INFO] Location manager started monitoring regions")
    } else {
        NSLog(@"[WARN] Unknown location update type: %ld, not starting anything.", (long)_settings.locationServiceType);
    }
    
}

- (RACSignal *)locations {
    @synchronized(self) {
        if (_signal)
            return _signal;
        
        self.signal = [[self rac_signalForSelector:@selector(locationManager:didUpdateLocations:)
                                      fromProtocol:@protocol(CLLocationManagerDelegate)]
                             reduceEach:^id(id _, NSArray *locations) {
                                 return [locations lastObject];
                             }];
        [self _startManager];
        return _signal;
    }
}

- (RACSignal *)regionEvents {
    @synchronized(self) {
        if (_signal)
            return _signal;
        
        self.signal = [RACSignal merge:@[
                                         [[self rac_signalForSelector:@selector(locationManager:didEnterRegion:)
                                                         fromProtocol:@protocol(CLLocationManagerDelegate)]
                                                reduceEach:^id(id _, CLRegion *region) {
                                                    return [[MMPRegionEvent alloc] initWithType:MMPRegionEventTypeRegionEnter
                                                                                      forRegion:[region copy]];
                                                }],
                                         [[self rac_signalForSelector:@selector(locationManager:didExitRegion:)
                                                         fromProtocol:@protocol(CLLocationManagerDelegate)]
                                                reduceEach:^id(id _, CLRegion *region) {
                                                    return [[MMPRegionEvent alloc] initWithType:MMPRegionEventTypeRegionExit
                                                                                      forRegion:[region copy]];
                                                }],
                                         [[self rac_signalForSelector:@selector(locationManager:didDetermineState:forRegion:)
                                                         fromProtocol:@protocol(CLLocationManagerDelegate)]
                                                reduceEach:^id(id _, id state, CLRegion *region) {
                                                    return [[MMPRegionEvent alloc] initWithType:MMPRegionEventTypeRegionStateDetermined
                                                                                          state:[state integerValue]
                                                                                      forRegion:[region copy]];
                                                }],
                                         [[self rac_signalForSelector:@selector(locationManager:monitoringDidFailForRegion:withError:)
                                                         fromProtocol:@protocol(CLLocationManagerDelegate)]
                                                reduceEach:^id(id _, CLRegion *region, NSError *error) {
                                                    return [[MMPRegionEvent alloc] initWithType:MMPRegionEventTypeRegionFailedMonitoring
                                                                                          error:error
                                                                                      forRegion:[region copy]];
                                                }],
                                         [[self rac_signalForSelector:@selector(locationManager:didStartMonitoringForRegion:)
                                                         fromProtocol:@protocol(CLLocationManagerDelegate)]
                                                reduceEach:^id(id _, CLRegion *region) {
                                                    return [[MMPRegionEvent alloc] initWithType:MMPRegionEventTypeRegionStartMonitoring
                                                                                      forRegion:[region copy]];
                                                }],
                                         [[self rac_signalForSelector:@selector(locationManager:didRangeBeacons:inRegion:)
                                                         fromProtocol:@protocol(CLLocationManagerDelegate)]
                                                reduceEach:^id(id _, NSArray *beacons, CLBeaconRegion *region) {
                                                    return [[MMPRegionEvent alloc] initWithType:MMPRegionEventTypeBeaconRanged
                                                                                        beacons:[beacons copy]
                                                                                      forRegion:[region copy]];
                                                }],
                                         [[self rac_signalForSelector:@selector(locationManager:rangingBeaconsDidFailForRegion:withError:)
                                                         fromProtocol:@protocol(CLLocationManagerDelegate)]
                                                reduceEach:^id(id _, CLBeaconRegion *region, NSError *error) {
                                                    return [[MMPRegionEvent alloc] initWithType:MMPRegionEventTypeBeaconFailedRanging
                                                                                          error:error
                                                                                      forRegion:[region copy]];
                                                }]
                                         ]];
        
        [self _startManager];
        return _signal;
    }
}

- (RACSignal *)regionStates {
    return [[self rac_signalForSelector:@selector(locationManager:didDetermineState:forRegion:)
                           fromProtocol:@protocol(CLLocationManagerDelegate)]
                  reduceEach:^id(id _, id state, CLRegion *region) {
                      return [[MMPRegionEvent alloc] initWithType:MMPRegionEventTypeRegionStateDetermined
                                                            state:[state integerValue]
                                                        forRegion:[region copy]];
                  }];
}

- (RACSignal *)errors {
    return [[[[self rac_signalForSelector:@selector(locationManager:didFailWithError:)
                             fromProtocol:@protocol(CLLocationManagerDelegate)]
                    reduceEach:^id(id _, NSError *error){
                        return error;
                    }]
                    filter:^BOOL(NSError *error) {
                        return error.code != kCLErrorLocationUnknown;
                    }]
                    flattenMap:^RACStream *(NSError *error) {
                        return [RACSignal error:error];
                    }];
}

- (RACSignal *)authorizationStatus {
    return [[self rac_signalForSelector:@selector(locationManager:didChangeAuthorizationStatus:)
                           fromProtocol:@protocol(CLLocationManagerDelegate)]
                  reduceEach:^id(id _, id statusNumber){
                      return statusNumber;
                  }];
}

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 80000
- (RACSignal *)authorize {
    [self _authorize:_manager with:_settings.authorizationType];
    return [self authorizationStatus];
}
#endif

@end

@interface MMPReactiveCoreLocation()

@property (nonatomic, strong) MMPLocationManagerSettings *settings;
@property (nonatomic, assign) BOOL finalized; // updated within @synchonized, so no need to make it atomic here

@end

@implementation MMPReactiveCoreLocation

- (id)init {
    if (self = [super init]) {
        [self defaultSettings];
        self.finalized = NO;
    }
    return self;
}

#pragma mark - MMPResourceLifecycleHelper implementation

- (NSString *)key {
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 80000
    if (_settings.locationServiceType == MMPLocationServiceTypeAuthOnly) {
        return [NSString stringWithFormat:@"rfauth~%ld", _settings.authorizationType];
    } else {
#endif
        return [NSString stringWithFormat:@"%ld~%d~%.5f~%.5f~%ld",
                _settings.locationServiceType,
                _settings.pausesLocationUpdatesAutomatically,
                _settings.distanceFilter,
                _settings.desiredAccuracy,
                _settings.activityType];
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 80000
    }
#endif
}

- (id<MMPResource>)createResource {
    return [[MMPLocationManagerResource alloc] initWithSettings:_settings];
}

- (void)releaseResource:(id<MMPResource>)resource {
    [(MMPLocationManagerResource *)resource stop];
}

#pragma mark - MMPReactiveCoreLocation: settings implementation

+ (instancetype)service {
    return [MMPReactiveCoreLocation new];
}

- (void)defaultSettings {
    self.settings = [MMPLocationManagerSettings new];
    
    _settings.locationServiceType = MMPLocationServiceTypeUnknown;
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 80000
    _settings.authorizationType = MMPLocationAuthorizationTypeWhenInUse;
#endif
    
    _settings.pausesLocationUpdatesAutomatically = YES;
    _settings.distanceFilter = kCLDistanceFilterNone;
    _settings.desiredAccuracy = kCLLocationAccuracyBest;
    _settings.activityType = CLActivityTypeOther;
    _settings.regions = [NSMutableArray array];
}

- (instancetype)pauseLocationUpdatesAutomatically {
    _settings.pausesLocationUpdatesAutomatically = YES;
    return self;
}

- (instancetype)pauseLocationUpdatesManually {
    _settings.pausesLocationUpdatesAutomatically = NO;
    return self;
}

- (instancetype)distanceFilter:(CLLocationDistance)distanceFilter {
    _settings.distanceFilter = distanceFilter;
    return self;
}

- (instancetype)desiredAccuracy:(CLLocationAccuracy)desiredAccuracy {
    _settings.desiredAccuracy = desiredAccuracy;
    return self;
}

- (instancetype)activityType:(CLActivityType)activityType {
    _settings.activityType = activityType;
    return self;
}

- (instancetype)region:(CLRegion *)region {
    [_settings.regions addObject:region];
    return self;
}

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 80000
- (instancetype)authorizeAlways {
    _settings.authorizationType = MMPLocationAuthorizationTypeAlways;
    return self;
}

- (instancetype)authorizeWhenInUse {
    _settings.authorizationType = MMPLocationAuthorizationTypeWhenInUse;
    return self;
}
#endif

#pragma mark - MMPReactiveCoreLocation: internal methods

/**
 *  Internal shared function for creating single location signal that will
 *  automatically stop manager on disposal (after receiving 1 event)
 *
 *  @return Signal with 1 location event
 */
- (RACSignal *)_location {
    MMPLocationManagerResource *resource = (MMPLocationManagerResource *)[[MMPResourceTracker instance] getResourceWithHelper:self];
    return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        [[[resource locations]
                    take:1]
                    subscribeNext:^(id x) {
                        [subscriber sendNext:x];
                    }
                    completed:^{
                        [subscriber sendCompleted];
                    }];
        return [RACDisposable disposableWithBlock:^{
            [self stop];
        }];
    }];
}

/**
 *  Internal shared function for finalizing the builder. Called by all terminal
 *  functions.
 */
- (RACSignal *)_terminal:(RACSignal * (^)(void))signalBlock {
    @synchronized(self) {
        if (!self.finalized) {
            self.finalized = YES;
            return signalBlock();
        }
    }
    // TODO: probably should send error to errors signal
    NSLog(@"[ERROR] The builder has been finalized, one of the terminal functions has been called.");
    return nil;
}

- (void)_prepareSignificantChange {
    _settings.locationServiceType = MMPLocationServiceTypeSignificantChange;
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 80000
    // significant location changes requires "Always"
    if (_settings.authorizationType != MMPLocationAuthorizationTypeAlways) {
        MMPRxCL_LOG(@"[INFO] Significant location changes requires \"Always\" authorization, forcing \"Always\" authorization type.")
        _settings.authorizationType = MMPLocationAuthorizationTypeAlways;
    }
#endif
}

#pragma mark - MMPReactiveCoreLocation: signals implementation

- (RACSignal *)locations {
    return [self _terminal:^RACSignal *{
        _settings.locationServiceType = MMPLocationServiceTypeLocation;
        MMPLocationManagerResource *resource = (MMPLocationManagerResource *)[[MMPResourceTracker instance] getResourceWithHelper:self];
        return [resource locations];
    }];
}

- (RACSignal *)location {
    return [self _terminal:^RACSignal *{
        _settings.locationServiceType = MMPLocationServiceTypeLocation;
        return [self _location];
    }];
}

- (RACSignal *)significantLocationChanges {
    return [self _terminal:^RACSignal *{
        [self _prepareSignificantChange];
        MMPLocationManagerResource *resource = (MMPLocationManagerResource *)[[MMPResourceTracker instance] getResourceWithHelper:self];
        return [resource locations];
    }];
}

- (RACSignal *)significantLocationChange {
    return [self _terminal:^RACSignal *{
        [self _prepareSignificantChange];
        return [self _location];
    }];
}

- (RACSignal *)regionStates {
    MMPLocationManagerResource *resource = (MMPLocationManagerResource *)[[MMPResourceTracker instance] getResourceWithHelper:self];
    return [resource regionStates];
}

- (RACSignal *)regionEvents {
    
    if (![_settings.regions count]) {
        // TODO: probably should send error to errors signal
        NSLog(@"[ERROR] no region specified.");
        return nil;
    }
    
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 80000
    if (_settings.authorizationType != MMPLocationAuthorizationTypeAlways) {
        MMPRxCL_LOG(@"[INFO] Significant location changes requires \"Always\" authorization, forcing \"Always\" authorization type.")
        _settings.authorizationType = MMPLocationAuthorizationTypeAlways;
    }
#endif
    
    return [self _terminal:^RACSignal *{
        _settings.locationServiceType = MMPLocationServiceTypeRegionMonitoring;
        MMPLocationManagerResource *resource = (MMPLocationManagerResource *)[[MMPResourceTracker instance] getResourceWithHelper:self];
        return [resource regionEvents];
    }];
}

- (RACSignal *)errors {
    MMPLocationManagerResource *resource = (MMPLocationManagerResource *)[[MMPResourceTracker instance] getResourceWithHelper:self];
    return [resource errors];
}

- (RACSignal *)authorizationStatus {
    MMPLocationManagerResource *resource = (MMPLocationManagerResource *)[[MMPResourceTracker instance] getResourceWithHelper:self];
    return [resource authorizationStatus];
}

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 80000
- (RACSignal *)authorize {
    return [self _terminal:^RACSignal *{
        _settings.locationServiceType = MMPLocationServiceTypeAuthOnly;
        MMPLocationManagerResource *resource = (MMPLocationManagerResource *)[[MMPResourceTracker instance] getResourceWithHelper:self];
        return [resource authorize];
    }];
}
#endif

- (void)stop {
    NSUInteger refCount = [[MMPResourceTracker instance] releaseResourceWithHelper:self];
    MMPRxCL_LOG(@"[INFO] Location manager resource released, currently have %lu references", refCount)
}

@end
