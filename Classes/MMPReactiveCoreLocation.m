//
//  MMPReactiveCoreLocation.m
//  Pods
//
//  Created by Purbo Mohamad on 2/10/15.
//
//

#import "MMPReactiveCoreLocation.h"

#ifdef DEBUG
#   define MMPRxCL_LOG(fmt, ...) NSLog((@"%s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__);
#else
#   define MMPRxCL_LOG(...)
#endif

@interface MMPLocationManagerSettings : NSObject

@property(assign, nonatomic) MMPLocationUpdateType updateType;
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 80000
@property(assign, nonatomic) MMPLocationAuthorizationType authorizationType;
#endif

@property(assign, nonatomic) BOOL pausesLocationUpdatesAutomatically;
@property(assign, nonatomic) CLLocationDistance distanceFilter;
@property(assign, nonatomic) CLLocationAccuracy desiredAccuracy;
@property(assign, nonatomic) CLActivityType activityType;

@end

@implementation MMPLocationManagerSettings

@end

@interface MMPLocationManagerResource : NSObject<MMPResource, CLLocationManagerDelegate>

@property (nonatomic, strong) MMPLocationManagerSettings *settings;
@property (nonatomic, strong) CLLocationManager *manager;
@property (nonatomic, strong) RACSignal *signal;

- (id)initWithSettings:(MMPLocationManagerSettings *)settings;
- (void)stop;

- (RACSignal *)locations;

- (RACSignal *)errors;
- (RACSignal *)authorizationStatus;

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
    // TODO: stop service according to the type of signal requested originally
    [_manager stopUpdatingLocation];
    MMPRxCL_LOG(@"[INFO] Location manager stopped");
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
    
    _manager.pausesLocationUpdatesAutomatically = _settings.pausesLocationUpdatesAutomatically;
    _manager.distanceFilter = _settings.distanceFilter;
    _manager.desiredAccuracy = _settings.desiredAccuracy;
    _manager.activityType = _settings.activityType;
    
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 80000
    [self _authorize:_manager with:_settings.authorizationType];
#endif
    
    if (_settings.updateType == MMPLocationUpdateTypeStandard) {
        [_manager startUpdatingLocation];
        MMPRxCL_LOG(@"[INFO] Location manager started updating location")
    } else if (_settings.updateType == MMPLocationUpdateTypeSignificantChange) {
        [_manager startMonitoringSignificantLocationChanges];
        MMPRxCL_LOG(@"[INFO] Location manager started monitoring significant location change")
    } else {
        NSLog(@"[WARN] Unknown location update type: %ld, not starting anything.", (long)_settings.updateType);
    }
    
}

- (RACSignal *)_locations {
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

- (RACSignal *)locations {
    return [self _locations];
}

- (RACSignal *)significantLocationChanges {
    return [self _locations];
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

@end

@interface MMPLocationServiceBuilder()

@property (nonatomic, strong) MMPLocationManagerSettings *settings;

@end

@implementation MMPLocationServiceBuilder

- (id)init {
    if (self = [super init]) {
        [self defaultSettings];
    }
    return self;
}

#pragma mark - MMPResourceLifecycleHelper implementation

- (NSString *)key {
    return [NSString stringWithFormat:@"%ld~%d~%.5f~%.5f~%ld",
            _settings.updateType,
            _settings.pausesLocationUpdatesAutomatically,
            _settings.distanceFilter,
            _settings.desiredAccuracy,
            _settings.activityType];
}

- (id<MMPResource>)createResource {
    return [[MMPLocationManagerResource alloc] initWithSettings:_settings];
}

- (void)releaseResource:(id<MMPResource>)resource {
    [(MMPLocationManagerResource *)resource stop];
}

#pragma mark - MMPLocationServiceBuilder implementation

+ (instancetype)create {
    return [MMPLocationServiceBuilder new];
}

- (void)defaultSettings {
    self.settings = [MMPLocationManagerSettings new];
    
    _settings.updateType = MMPLocationUpdateTypeUnknown;
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 80000
    _settings.authorizationType = MMPLocationAuthorizationTypeWhenInUse;
#endif
    
    _settings.pausesLocationUpdatesAutomatically = YES;
    _settings.distanceFilter = kCLDistanceFilterNone;
    _settings.desiredAccuracy = kCLLocationAccuracyBest;
    _settings.activityType = CLActivityTypeOther;
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

- (RACSignal *)locations {
    // TODO: should finalize the builder (call to another final method should cause an error)
    _settings.updateType = MMPLocationUpdateTypeStandard;
    MMPLocationManagerResource *resource = (MMPLocationManagerResource *)[[MMPResourceTracker instance] getResourceWithHelper:self];
    return [resource locations];
}

- (RACSignal *)significantLocationChanges {
    // TODO: should finalize the builder (call to another final method should cause an error)
    _settings.updateType = MMPLocationUpdateTypeSignificantChange;
    MMPLocationManagerResource *resource = (MMPLocationManagerResource *)[[MMPResourceTracker instance] getResourceWithHelper:self];
    return [resource significantLocationChanges];
}

- (RACSignal *)errors {
    MMPLocationManagerResource *resource = (MMPLocationManagerResource *)[[MMPResourceTracker instance] getResourceWithHelper:self];
    return [resource errors];
}

- (RACSignal *)authorizationStatus {
    MMPLocationManagerResource *resource = (MMPLocationManagerResource *)[[MMPResourceTracker instance] getResourceWithHelper:self];
    return [resource authorizationStatus];
}

- (void)stop {
    NSUInteger refCount = [[MMPResourceTracker instance] releaseResourceWithHelper:self];
    MMPRxCL_LOG(@"[INFO] Location manager resource released, currently have %lu references", refCount)
}

@end
/*
@implementation MMPReactiveCoreLocation

+ (instancetype)instance {
    static dispatch_once_t pred;
    static id shared = nil;
    dispatch_once(&pred, ^{
        shared = [[super alloc] initSingletonInstance];
    });
    return shared;
}

- (instancetype)initSingletonInstance {
    self = [super init];
    if (self) {
        
    }
    return self;
}

@end
*/