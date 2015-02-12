//
//  MMPExperimentsViewController.m
//  SimpleReactiveCoreLocation
//
//  Created by Purbo Mohamad on 1/22/15.
//  Copyright (c) 2015 Purbo. All rights reserved.
//

#import "MMPExperimentsViewController.h"
#import <CoreLocation/CoreLocation.h>
#import <ReactiveCocoa/ReactiveCocoa.h>

/*
@interface MMPLocationManagerTrack : NSObject<CLLocationManagerDelegate>

@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, assign) NSUInteger subscribers;

@end

@implementation MMPLocationManagerTrack

@end

@interface MMPLocationManagerTracker : NSObject

@property (nonatomic, strong) NSMutableDictionary *cache;
@property (nonatomic, strong) id queue;

@end

@implementation MMPLocationManagerTracker

- (id)init {
    self = [super init];
    if (self) {
        self.cache = [NSMutableDictionary new];
        self.queue = dispatch_queue_create("com.mikeash.cachequeue", DISPATCH_QUEUE_CONCURRENT);
    }
    return self;
}

- (id)cacheObjectForKey: (id)key {
    __block id obj;
    dispatch_sync(_queue, ^{
        obj = [_cache objectForKey: key];
    });
    return obj;
}

- (void)setCacheObject: (id)obj forKey: (id)key {
    dispatch_barrier_async(_queue, ^{
        [_cache setObject: obj forKey: key];
    });
}

@end
*/

@interface MMPExperimentsViewController ()<CLLocationManagerDelegate>

@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, assign) BOOL started;

@end

@implementation MMPExperimentsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.started = NO;
    self.locationManager = [CLLocationManager new];
    _locationManager.delegate = self;
    [_locationManager requestWhenInUseAuthorization];
    
    [[self locations]
           subscribeNext:^(CLLocation *location) {
               NSLog(@"next location: %@", location);
           }
           error:^(NSError *error) {
               NSLog(@"error: %@", error);
           }
           completed:^{
               NSLog(@"completed");
           }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (RACSignal *)locations {
    return [[[self rac_signalForSelector:@selector(locationManager:didUpdateLocations:)
                           fromProtocol:@protocol(CLLocationManagerDelegate)]
                   reduceEach:^id(id _, id locations) {
                      return locations;
                   }]
                   setNameWithFormat:@"<%@:%p locations >", self.class, self];
}

- (IBAction)test:(id)sender {

    if (_started) {
        [self.locationManager stopUpdatingLocation];
        self.started = false;
    } else {
        [self.locationManager startUpdatingLocation];
        self.started = true;
    }
}

@end

