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
@property (nonatomic, assign) BOOL finalized; // updated within @synchonized, so no need to make it atomic here

@end

@implementation MMPLocationServiceBuilder

- (id)init {
    if (self = [super init]) {
        [self defaultSettings];
        self.finalized = NO;
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

#pragma mark - MMPLocationServiceBuilder: settings implementation

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

#pragma mark - MMPLocationServiceBuilder: internal methods

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
    NSLog(@"[ERROR] The builder has been finalized, one of the terminal functions has been called.");
    return nil;
}

#pragma mark - MMPLocationServiceBuilder: signals implementation

- (RACSignal *)locations {
    return [self _terminal:^RACSignal *{
        _settings.updateType = MMPLocationUpdateTypeStandard;
        MMPLocationManagerResource *resource = (MMPLocationManagerResource *)[[MMPResourceTracker instance] getResourceWithHelper:self];
        return [resource locations];
    }];
}

- (RACSignal *)location {
    return [self _terminal:^RACSignal *{
        _settings.updateType = MMPLocationUpdateTypeStandard;
        return [self _location];
    }];
}

- (RACSignal *)significantLocationChanges {
    return [self _terminal:^RACSignal *{
        _settings.updateType = MMPLocationUpdateTypeSignificantChange;
        MMPLocationManagerResource *resource = (MMPLocationManagerResource *)[[MMPResourceTracker instance] getResourceWithHelper:self];
        return [resource locations];
    }];
}

- (RACSignal *)significantLocationChange {
    return [self _terminal:^RACSignal *{
        _settings.updateType = MMPLocationUpdateTypeSignificantChange;
        return [self _location];
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

- (void)stop {
    NSUInteger refCount = [[MMPResourceTracker instance] releaseResourceWithHelper:self];
    MMPRxCL_LOG(@"[INFO] Location manager resource released, currently have %lu references", refCount)
}

@end
