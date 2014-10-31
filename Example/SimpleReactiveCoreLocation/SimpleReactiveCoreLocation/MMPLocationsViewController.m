//
//  MMPLocationsViewController.m
//  SimpleReactiveCoreLocation
//
//  Created by Purbo Mohamad on 10/6/14.
//  Copyright (c) 2014 Purbo. All rights reserved.
//

#import "MMPLocationsViewController.h"
#import <ReactiveCocoa/RACEXTScope.h>
#import <MMPReactiveCoreLocation/MMPReactiveCoreLocation.h>
#import <CoreLocation/CoreLocation.h>

@interface MMPLocationsViewController ()

@property (nonatomic, strong) MMPLocationManager *locationManagerForAuth;

@property (nonatomic, strong) RACSubject *doneSubject;
@property (nonatomic, strong) RACSubject *significantDoneSubject;

@end

@implementation MMPLocationsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)locationButtonTouchUpInside:(id)sender {
    
    if (!_doneSubject) {
        
        self.doneSubject = [RACSubject subject];
        
        MMPLocationManager *service = [MMPLocationManager new];
        
        @weakify(self)
        
        [[[[service stop:_doneSubject]
                    locations]
                    subscribeOn:[RACScheduler mainThreadScheduler]]
                    subscribeNext:^(CLLocation *location) {
                        
                        @strongify(self)
                        
                        NSString *locString = [NSString stringWithFormat:@"(%f, %f, %f)",
                                               location.coordinate.latitude,
                                               location.coordinate.longitude,
                                               location.horizontalAccuracy];
                        NSLog(@"[INFO] received location: %@", locString);
                        self.locationLabel.text = locString;
                        
                    }
                    completed:^{
                        
                        @strongify(self)
                        self.doneSubject = nil;
                        
                    }];
        
        [[service authorizationStatus] subscribeNext:^(NSNumber *statusNumber) {
            CLAuthorizationStatus status = [statusNumber intValue];
            switch (status) {
                case kCLAuthorizationStatusNotDetermined:
                    NSLog(@"[INFO] Status changed: kCLAuthorizationStatusNotDetermined");
                    break;
                case kCLAuthorizationStatusRestricted:
                    NSLog(@"[INFO] Status changed: kCLAuthorizationStatusRestricted");
                    break;
                case kCLAuthorizationStatusDenied:
                    NSLog(@"[INFO] Status changed: kCLAuthorizationStatusDenied");
                    break;
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 80000
                case kCLAuthorizationStatusAuthorizedAlways:
                    NSLog(@"[INFO] Status changed: kCLAuthorizationStatusAuthorizedAlways");
                    break;
                case kCLAuthorizationStatusAuthorizedWhenInUse:
                    NSLog(@"[INFO] Status changed: kCLAuthorizationStatusAuthorizedWhenInUse");
                    break;
#else
                case kCLAuthorizationStatusAuthorized:
                    NSLog(@"[INFO] Status changed: kCLAuthorizationStatusAuthorized");
                    break;
#endif
                default:
                    break;
            }
        }];
        
        [[service errors] subscribeNext:^(NSError *error) {
            NSLog(@"[ERROR] Location service error: %@", error);
        }];
        
        [_locationButton setTitle:@"Stop location signal" forState:UIControlStateNormal];
        
    } else {
        
        [_doneSubject sendCompleted];
        [_locationButton setTitle:@"Start location signal" forState:UIControlStateNormal];
    }
}

- (IBAction)singleLocationButtonTouchUpInside:(id)sender {
    
    MMPLocationManager *service = [MMPLocationManager new];
    
    @weakify(self)
    
    [[[service location]
               subscribeOn:[RACScheduler mainThreadScheduler]]
               subscribeNext:^(CLLocation *location) {
                   
                   @strongify(self)
                   
                   NSString *locString = [NSString stringWithFormat:@"(%f, %f, %f)",
                                          location.coordinate.latitude,
                                          location.coordinate.longitude,
                                          location.horizontalAccuracy];
                   NSLog(@"[INFO] received single location: %@", locString);
                   self.singleLocationLabel.text = locString;
                   
               }];
    
}

- (IBAction)significantLocationButtonTouchUpInside:(id)sender {
    
    if (!_significantDoneSubject) {
        
        self.significantDoneSubject = [RACSubject subject];
        
        MMPLocationManager *service = [MMPLocationManager new];
        
        @weakify(self)
        
        [[[[service stop:_significantDoneSubject]
                    significantLocationChanges]
                    subscribeOn:[RACScheduler mainThreadScheduler]]
                    subscribeNext:^(CLLocation *location) {
                        
                        @strongify(self)
                        
                        NSString *locString = [NSString stringWithFormat:@"(%f, %f, %f)",
                                               location.coordinate.latitude,
                                               location.coordinate.longitude,
                                               location.horizontalAccuracy];
                        NSLog(@"[INFO] received significant change location: %@", locString);
                        self.significantLocationLabel.text = locString;
                        
                    }
                    completed:^{
                        
                        @strongify(self)
                        self.significantDoneSubject = nil;
                        
                    }];
        
        [[service authorizationStatus] subscribeNext:^(NSNumber *statusNumber) {
            CLAuthorizationStatus status = [statusNumber intValue];
            switch (status) {
                case kCLAuthorizationStatusNotDetermined:
                    NSLog(@"[INFO] Status changed: kCLAuthorizationStatusNotDetermined");
                    break;
                case kCLAuthorizationStatusRestricted:
                    NSLog(@"[INFO] Status changed: kCLAuthorizationStatusRestricted");
                    break;
                case kCLAuthorizationStatusDenied:
                    NSLog(@"[INFO] Status changed: kCLAuthorizationStatusDenied");
                    break;
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 80000
                case kCLAuthorizationStatusAuthorizedAlways:
                    NSLog(@"[INFO] Status changed: kCLAuthorizationStatusAuthorizedAlways");
                    break;
                case kCLAuthorizationStatusAuthorizedWhenInUse:
                    NSLog(@"[INFO] Status changed: kCLAuthorizationStatusAuthorizedWhenInUse");
                    break;
#else
                case kCLAuthorizationStatusAuthorized:
                    NSLog(@"[INFO] Status changed: kCLAuthorizationStatusAuthorized");
                    break;
#endif
                default:
                    break;
            }
        }];
        
        [[service errors] subscribeNext:^(NSError *error) {
            NSLog(@"[ERROR] Location service error: %@", error);
        }];
        
        [_significantLocationButton setTitle:@"Stop significant location change signal" forState:UIControlStateNormal];
        
    } else {
        
        [_significantDoneSubject sendCompleted];
        [_significantLocationButton setTitle:@"Start significant location change signal" forState:UIControlStateNormal];
    }
    
}

- (IBAction)requestForAuthTouchUpInside:(id)sender {
    
    @weakify(self)
    
    self.locationManagerForAuth = [MMPLocationManager new];
    
    [[[self.locationManagerForAuth
       authorizeAlways]
       requestAuthorization]
       subscribeNext:^(NSNumber *statusNumber) {
           @strongify(self)
           
           CLAuthorizationStatus status = [statusNumber intValue];
           switch (status) {
               case kCLAuthorizationStatusNotDetermined:
                   self.authorizationStatusLabel.text = @"Status: kCLAuthorizationStatusNotDetermined";
                   break;
               case kCLAuthorizationStatusRestricted:
                   self.authorizationStatusLabel.text = @"Status: kCLAuthorizationStatusRestricted";
                   break;
               case kCLAuthorizationStatusDenied:
                   self.authorizationStatusLabel.text = @"Status: kCLAuthorizationStatusDenied";
                   break;
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 80000
               case kCLAuthorizationStatusAuthorizedAlways:
                   self.authorizationStatusLabel.text = @"Status: kCLAuthorizationStatusAuthorizedAlways";
                   break;
               case kCLAuthorizationStatusAuthorizedWhenInUse:
                   self.authorizationStatusLabel.text = @"Status: kCLAuthorizationStatusAuthorizedWhenInUse";
                   break;
#else
               case kCLAuthorizationStatusAuthorized:
                   self.authorizationStatusLabel.text = @"Status: kCLAuthorizationStatusAuthorized";
                   break;
#endif
               default:
                   break;
           }
       }];
}

@end
