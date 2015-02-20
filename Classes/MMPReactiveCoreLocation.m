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

NSString * const MMPLocationErrorDomain = @"MMPLocationErrorDomain";

typedef NS_ENUM(NSInteger, MMPLocationServiceType) {
    MMPLocationServiceTypeUnknown = 0,
    MMPLocationServiceTypeAuthOnly,
    MMPLocationServiceTypeLocation,
    MMPLocationServiceTypeSignificantChange,
    MMPLocationServiceTypeRegionMonitoring,
    MMPLocationServiceTypeBeaconRanging,
    MMPLocationServiceTypeHeadingUpdate,
    MMPLocationServiceTypeVisitMonitoring
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

@property(assign, nonatomic) CLLocationDegrees headingFilter;
@property(assign, nonatomic) CLDeviceOrientation headingOrientation;
@property(copy) BOOL(^shouldDisplayHeadingCalibrationBlock)(CLLocationManager *);

@property(assign, nonatomic) NSTimeInterval locationAgeLimit;
@property(assign, nonatomic) NSTimeInterval timeout;

@end

@implementation MMPLocationManagerSettings

@end

@interface MMPLocationManagerResource : NSObject<MMPResource, CLLocationManagerDelegate>

@property (nonatomic, strong) MMPLocationManagerSettings *settings;
@property (nonatomic, strong) CLLocationManager *manager;
@property (nonatomic, strong) RACSignal *signal;

// required delegates methods per API doc:
// https://developer.apple.com/library/prerelease/ios/documentation/CoreLocation/Reference/CLLocationManagerDelegate_Protocol/index.html
// (safer to implement even if nobody subscribes)
@property (nonatomic, strong) RACSignal *locationUpdatePausesSignal;
@property (nonatomic, strong) RACSignal *locationUpdateResumesSignal;
@property (nonatomic, strong) RACSignal *regionStateDeterminationsSignal;

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
    switch (_settings.locationServiceType) {
        case MMPLocationServiceTypeLocation:
            [_manager stopUpdatingLocation];
            MMPRxCL_LOG(@"[INFO] Location manager stopped updating location");
            break;
        case MMPLocationServiceTypeSignificantChange:
            [_manager stopMonitoringSignificantLocationChanges];
            MMPRxCL_LOG(@"[INFO] Location manager stopped monitoring significant location change");
            break;
        case MMPLocationServiceTypeRegionMonitoring:
            for (CLRegion *region in _settings.regions) {
                [_manager stopMonitoringForRegion:region];
            }
            MMPRxCL_LOG(@"[INFO] Location manager stopped monitoring regions")
            break;
        case MMPLocationServiceTypeBeaconRanging:
            for (CLBeaconRegion *region in _settings.regions) {
                [_manager stopRangingBeaconsInRegion:region];
            }
            MMPRxCL_LOG(@"[INFO] Location manager stopped ranging beacons")
            break;
        case MMPLocationServiceTypeHeadingUpdate:
            [_manager stopUpdatingHeading];
            MMPRxCL_LOG(@"[INFO] Location manager stopped updating heading")
            break;
        case MMPLocationServiceTypeVisitMonitoring:
            [_manager stopMonitoringVisits];
            MMPRxCL_LOG(@"[INFO] Location manager stopped monitoring visits")
            break;
        default:
            NSLog(@"[WARN] Unknown location update type: %ld, not starting anything.", (long)_settings.locationServiceType);
            break;
    }
    
}

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 80000
- (void)_authorize:(CLLocationManager *)locationManager with:(MMPLocationAuthorizationType)authorizationType {
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

- (CLLocationManager *)_setupManagerForLocation {
    _manager.pausesLocationUpdatesAutomatically = _settings.pausesLocationUpdatesAutomatically;
    _manager.distanceFilter = _settings.distanceFilter;
    _manager.desiredAccuracy = _settings.desiredAccuracy;
    _manager.activityType = _settings.activityType;
    return _manager;
}

- (CLLocationManager *)_setupManagerForHeadingUpdate {
    _manager.headingFilter = _settings.headingFilter;
    _manager.headingOrientation = _settings.headingOrientation;
    return _manager;
}

- (void)_createAllRequiredDelegateMethods {
    self.locationUpdatePausesSignal = [[self rac_signalForSelector:@selector(locationManagerDidPauseLocationUpdates:)
                                                      fromProtocol:@protocol(CLLocationManagerDelegate)]
                                             reduceEach:^id(id obj) {
                                                 return obj;
                                             }];
    
    self.locationUpdateResumesSignal = [[self rac_signalForSelector:@selector(locationManagerDidResumeLocationUpdates:)
                                                       fromProtocol:@protocol(CLLocationManagerDelegate)]
                                              reduceEach:^id(id obj) {
                                                  return obj;
                                              }];
    
    self.regionStateDeterminationsSignal = [[self rac_signalForSelector:@selector(locationManager:didDetermineState:forRegion:)
                                                           fromProtocol:@protocol(CLLocationManagerDelegate)]
                                                  reduceEach:^id(id _, id state, CLRegion *region) {
                                                      return [[MMPRegionEvent alloc] initWithType:MMPRegionEventTypeRegionStateDetermined
                                                                                            state:[state integerValue]
                                                                                        forRegion:[region copy]];
                                                  }];
}

- (void)_startManager {
    
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 80000
    [self _authorize:_manager with:_settings.authorizationType];
#endif
    
    switch (_settings.locationServiceType) {
        case MMPLocationServiceTypeLocation:
            [[self _setupManagerForLocation] startUpdatingLocation];
            MMPRxCL_LOG(@"[INFO] Location manager started updating location")
            break;
        case MMPLocationServiceTypeSignificantChange:
            [[self _setupManagerForLocation] startMonitoringSignificantLocationChanges];
            MMPRxCL_LOG(@"[INFO] Location manager started monitoring significant location change")
            break;
        case MMPLocationServiceTypeRegionMonitoring:
            for (CLRegion *region in _settings.regions) {
                [_manager startMonitoringForRegion:region];
            }
            MMPRxCL_LOG(@"[INFO] Location manager started monitoring regions")
            break;
        case MMPLocationServiceTypeBeaconRanging:
            for (CLBeaconRegion *region in _settings.regions) {
                [_manager startRangingBeaconsInRegion:region];
            }
            MMPRxCL_LOG(@"[INFO] Location manager started ranging beacons")
            break;
        case MMPLocationServiceTypeHeadingUpdate:
            [[self _setupManagerForHeadingUpdate] startUpdatingHeading];
            MMPRxCL_LOG(@"[INFO] Location manager started updating heading")
            break;
        case MMPLocationServiceTypeVisitMonitoring:
            [_manager startMonitoringVisits];
            MMPRxCL_LOG(@"[INFO] Location manager started monitoring visits")
            break;
        default:
            NSLog(@"[WARN] Unknown location update type: %ld, not starting anything.", (long)_settings.locationServiceType);
            break;
    }

}

- (RACSignal *)_prepSignal:(RACSignal* (^)(void))createSignalBlock {
    @synchronized(self) {
        if (_signal)
            return _signal;
        
        [self _createAllRequiredDelegateMethods];
        self.signal = createSignalBlock();
        [self _startManager];
        return _signal;
    }
}

- (RACSignal *)locations {
    return [self _prepSignal:^RACSignal *{
        RACSignal *ret = [[self rac_signalForSelector:@selector(locationManager:didUpdateLocations:)
                                         fromProtocol:@protocol(CLLocationManagerDelegate)]
                                reduceEach:^id(id _, NSArray *locations) {
                                    return [[locations lastObject] copy];
                                }];
        if (_settings.locationAgeLimit > 0) {
            return [ret filter:^BOOL(CLLocation *location) {
                NSTimeInterval locationAge = -[location.timestamp timeIntervalSinceNow];
                return (locationAge <= _settings.locationAgeLimit);
            }];
        } else {
            return ret;
        }
    }];
}

- (RACSignal *)regionEvents {
    return [self _prepSignal:^RACSignal *{
        return [RACSignal merge:@[
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
                                  _regionStateDeterminationsSignal
                                  ]];
    }];
}

- (RACSignal *)beaconRanges {
    return [self _prepSignal:^RACSignal *{
        return [RACSignal merge:@[
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
    }];
}

- (RACSignal *)headingUpdates {
    return [self _prepSignal:^RACSignal *{
        return [[self rac_signalForSelector:@selector(locationManager:didUpdateHeading:)
                               fromProtocol:@protocol(CLLocationManagerDelegate)]
                      reduceEach:^id(id _, id state, CLHeading *newHeading) {
                          return [newHeading copy];
                      }];
    }];
}

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 80000
- (RACSignal *)visits {
    return [self _prepSignal:^RACSignal *{
        return [[self rac_signalForSelector:@selector(locationManager:didVisit:)
                               fromProtocol:@protocol(CLLocationManagerDelegate)]
                      reduceEach:^id(id _, id state, CLVisit *visit) {
                          return [visit copy];
                      }];
    }];
}
#endif

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

#pragma mark - CLLocationManagerDelegate implementation

- (BOOL)locationManagerShouldDisplayHeadingCalibration:(CLLocationManager *)manager {
    if (_settings.shouldDisplayHeadingCalibrationBlock) {
        return _settings.shouldDisplayHeadingCalibrationBlock(manager);
    }
    return NO;
}

@end

@interface MMPReactiveCoreLocation()

@property (nonatomic, strong) MMPLocationManagerSettings *settings;
@property (nonatomic, strong) NSString *cachedKey;
@property (nonatomic, assign) BOOL finalized; // updated within @synchonized, so no need to make it atomic here
@property (nonatomic, strong) RACSubject *stopSubject;

@end

@implementation MMPReactiveCoreLocation

- (id)init {
    if (self = [super init]) {
        [self defaultSettings];
        self.finalized = NO;
        self.cachedKey = nil;
        self.stopSubject = [RACSubject subject];
    }
    return self;
}

#pragma mark - MMPResourceLifecycleHelper implementation

- (NSString *)key {
    @synchronized(self) {
        if (!_cachedKey) {
            switch (_settings.locationServiceType) {
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 80000
                case MMPLocationServiceTypeAuthOnly:
                    self.cachedKey = [NSString stringWithFormat:@"rfauth~%ld", (long)_settings.authorizationType];
                    break;
#endif
                case MMPLocationServiceTypeLocation:
                case MMPLocationServiceTypeSignificantChange:
                    self.cachedKey = [NSString stringWithFormat:@"loc~%ld~%d~%.5f~%.5f~%ld",
                            (long)_settings.locationServiceType,
                            _settings.pausesLocationUpdatesAutomatically,
                            _settings.distanceFilter,
                            _settings.desiredAccuracy,
                            (long)_settings.activityType];
                    break;
                case MMPLocationServiceTypeRegionMonitoring:
                    self.cachedKey = [NSString stringWithFormat:@"regmon~%@", [[NSUUID UUID] UUIDString]];
                    break;
                case MMPLocationServiceTypeHeadingUpdate:
                    if (_settings.shouldDisplayHeadingCalibrationBlock) {
                        // block is defined, generate unique ID
                        self.cachedKey = [NSString stringWithFormat:@"hdup~%@", [[NSUUID UUID] UUIDString]];
                    } else {
                        self.cachedKey = [NSString stringWithFormat:@"hdup~%.5f~%d",
                                _settings.headingFilter,
                                (int)_settings.headingOrientation];
                    }
                    break;
                case MMPLocationServiceTypeVisitMonitoring:
                    self.cachedKey = @"vismon";
                    break;
                default:
                    // shouldn't happen
                    NSLog(@"[ERROR] Unexpected location service type: %ld", (long)_settings.locationServiceType);
                    break;
            }
        }
    }
    return _cachedKey;
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
    
    _settings.headingFilter = 1;
    _settings.headingOrientation = CLDeviceOrientationUnknown;
    _settings.shouldDisplayHeadingCalibrationBlock = nil;
    
    _settings.locationAgeLimit = MMP_LOCATION_AGE_LIMIT_DEFAULT;
    _settings.timeout = MMP_LOCATION_TIMEOUT_DEFAULT;
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

- (instancetype)beaconRegion:(CLBeaconRegion *)region {
    [_settings.regions addObject:region];
    return self;
}

- (instancetype)headingFilter:(CLLocationDegrees)headingFilter {
    _settings.headingFilter = headingFilter;
    return self;
}

- (instancetype)headingOrientation:(CLDeviceOrientation)headingOrientation {
    _settings.headingOrientation = headingOrientation;
    return self;
}

- (instancetype)shouldDisplayHeadingCalibration:(BOOL(^)(CLLocationManager *))block {
    _settings.shouldDisplayHeadingCalibrationBlock = [block copy];
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

- (instancetype)locationAgeLimit:(NSTimeInterval)locationAgeLimit {
    _settings.locationAgeLimit = locationAgeLimit;
    return self;
}

- (instancetype)timeout:(NSTimeInterval)timeout {
    _settings.timeout = timeout;
    return self;
}

#pragma mark - MMPReactiveCoreLocation: internal methods

/**
 *  Internal shared function for creating single location signal that will
 *  automatically stop manager on disposal (after receiving 1 event)
 *
 *  @return Signal with 1 location event
 */
- (RACSignal *)_location {
    MMPLocationManagerResource *resource = (MMPLocationManagerResource *)[[MMPResourceTracker instance] retainResourceWithHelper:self];
    return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        RACSignal *s =
            (_settings.timeout > 0) ?
                [[[resource locations] take:1] timeout:_settings.timeout onScheduler:[RACScheduler scheduler]] :
                [[resource locations] take:1];
        [s
         subscribeNext:^(id x) {
             [subscriber sendNext:x];
         }
         error:^(NSError *error) {
             [subscriber sendError:error];
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
    return [[self _terminal:^RACSignal *{
        _settings.locationServiceType = MMPLocationServiceTypeLocation;
        MMPLocationManagerResource *resource = (MMPLocationManagerResource *)[[MMPResourceTracker instance] retainResourceWithHelper:self];
        return [resource locations];
    }] takeUntil:_stopSubject];
}

- (RACSignal *)location {
    return [self _terminal:^RACSignal *{
        _settings.locationServiceType = MMPLocationServiceTypeLocation;
        return [self _location];
    }];
}

- (RACSignal *)significantLocationChanges {
    return [[self _terminal:^RACSignal *{
        [self _prepareSignificantChange];
        MMPLocationManagerResource *resource = (MMPLocationManagerResource *)[[MMPResourceTracker instance] retainResourceWithHelper:self];
        return [resource locations];
    }] takeUntil:_stopSubject];
}

- (RACSignal *)significantLocationChange {
    return [self _terminal:^RACSignal *{
        [self _prepareSignificantChange];
        return [self _location];
    }];
}

- (RACSignal *)locationUpdatePauses {
    MMPLocationManagerResource *resource = (MMPLocationManagerResource *)[[MMPResourceTracker instance] getResourceWithHelper:self];
    return resource.locationUpdatePausesSignal;
}

- (RACSignal *)locationUpdateResumes {
    MMPLocationManagerResource *resource = (MMPLocationManagerResource *)[[MMPResourceTracker instance] getResourceWithHelper:self];
    return resource.locationUpdateResumesSignal;
}

- (RACSignal *)regionStates {
    MMPLocationManagerResource *resource = (MMPLocationManagerResource *)[[MMPResourceTracker instance] getResourceWithHelper:self];
    return resource.regionStateDeterminationsSignal;
}

- (RACSignal *)statesForRegion:(CLRegion *)region {
    MMPLocationManagerResource *resource = (MMPLocationManagerResource *)[[MMPResourceTracker instance] getResourceWithHelper:self];
    [resource.manager requestStateForRegion:region];
    return [[self regionStates] filter:^BOOL(MMPRegionEvent *regionEvent) {
        // only returns states for the specified region
        return [regionEvent.region.identifier isEqualToString:region.identifier];
    }];
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
        MMPLocationManagerResource *resource = (MMPLocationManagerResource *)[[MMPResourceTracker instance] retainResourceWithHelper:self];
        return [[resource regionEvents] takeUntil:_stopSubject];
    }];
}

- (RACSignal *)beaconRanges {
    if (![_settings.regions count]) {
        // TODO: probably should send error to errors signal
        NSLog(@"[ERROR] no region specified.");
        return nil;
    }
    
    return [self _terminal:^RACSignal *{
        _settings.locationServiceType = MMPLocationServiceTypeBeaconRanging;
        MMPLocationManagerResource *resource = (MMPLocationManagerResource *)[[MMPResourceTracker instance] retainResourceWithHelper:self];
        return [[resource beaconRanges] takeUntil:_stopSubject];
    }];
}

- (RACSignal *)headingUpdates {
    return [self _terminal:^RACSignal *{
        _settings.locationServiceType = MMPLocationServiceTypeHeadingUpdate;
        MMPLocationManagerResource *resource = (MMPLocationManagerResource *)[[MMPResourceTracker instance] retainResourceWithHelper:self];
        return [[resource headingUpdates] takeUntil:_stopSubject];
    }];
}

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 80000
- (RACSignal *)visits {
    
    if (_settings.authorizationType != MMPLocationAuthorizationTypeAlways) {
        MMPRxCL_LOG(@"[INFO] Significant location changes requires \"Always\" authorization, forcing \"Always\" authorization type.")
        _settings.authorizationType = MMPLocationAuthorizationTypeAlways;
    }
    
    return [self _terminal:^RACSignal *{
        _settings.locationServiceType = MMPLocationServiceTypeVisitMonitoring;
        MMPLocationManagerResource *resource = (MMPLocationManagerResource *)[[MMPResourceTracker instance] retainResourceWithHelper:self];
        return [[resource visits] takeUntil:_stopSubject];
    }];
}
#endif

- (RACSignal *)errors {
    MMPLocationManagerResource *resource = (MMPLocationManagerResource *)[[MMPResourceTracker instance] getResourceWithHelper:self];
    return [[resource errors] takeUntil:_stopSubject];
}

- (RACSignal *)authorizationStatus {
    MMPLocationManagerResource *resource = (MMPLocationManagerResource *)[[MMPResourceTracker instance] getResourceWithHelper:self];
    return [[resource authorizationStatus] takeUntil:_stopSubject];
}

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 80000
- (RACSignal *)authorize {
    return [self _terminal:^RACSignal *{
        _settings.locationServiceType = MMPLocationServiceTypeAuthOnly;
        MMPLocationManagerResource *resource = (MMPLocationManagerResource *)[[MMPResourceTracker instance] retainResourceWithHelper:self];
        return [[resource authorize] takeUntil:_stopSubject];
    }];
}
#endif

- (void)stop {
    NSUInteger refCount = [[MMPResourceTracker instance] releaseResourceWithHelper:self];
    [self.stopSubject sendCompleted];
    MMPRxCL_LOG(@"[INFO] Location manager resource released, currently have %lu references", refCount)
}

- (CLLocationManager *)locationManager {
    MMPLocationManagerResource *resource = (MMPLocationManagerResource *)[[MMPResourceTracker instance] getResourceWithHelper:self];
    return resource.manager;
}

@end
