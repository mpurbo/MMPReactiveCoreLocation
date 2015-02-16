//
//  MMPLocationsViewController.m
//  SimpleReactiveCoreLocation
//
//  Created by Purbo Mohamad on 10/6/14.
//  Copyright (c) 2014 Purbo. All rights reserved.
//

#import "MMPLocationsViewController.h"
#import <MMPReactiveCoreLocation/MMPReactiveCoreLocation.h>

@interface MMPLocationsViewController ()

@property (nonatomic, strong) MMPLocationManager *locationManagerForAuth;

@property (nonatomic, strong) MMPReactiveCoreLocation *locationService;
@property (nonatomic, strong) MMPReactiveCoreLocation *significantService;

@end

@implementation MMPLocationsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.locationService = nil;
    self.significantService = nil;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)locationButtonTouchUpInside:(id)sender {
    
    [[[MMPReactiveCoreLocation service] locations] subscribeNext:^(CLLocation *location) {
        NSLog(@"[INFO] received location: %@", location);
    }];
    
    if (!_locationService) {
        
        self.locationService = [MMPReactiveCoreLocation service];
        
        // subscribe to locations
        [[[_locationService locations]
                            subscribeOn:[RACScheduler mainThreadScheduler]]
                            subscribeNext:^(CLLocation *location) {
                                NSString *locString = [NSString stringWithFormat:@"(%f, %f, %f)",
                                                       location.coordinate.latitude,
                                                       location.coordinate.longitude,
                                                       location.horizontalAccuracy];
                                NSLog(@"[INFO] received location: %@", locString);
                                self.locationLabel.text = locString;
                            }];
        
        // subscribe to authorization status
        [[_locationService authorizationStatus]
                           subscribeNext:^(NSNumber *statusNumber) {
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
        
        // subscribe to errors
        [[_locationService errors]
                           subscribeNext:^(NSError *error) {
                               NSLog(@"[ERROR] Location service error: %@", error);
                           }];
        
        [_locationButton setTitle:@"Stop location signal" forState:UIControlStateNormal];
    } else {
        [_locationService stop];
        self.locationService = nil;
        [_locationButton setTitle:@"Start location signal" forState:UIControlStateNormal];
    }
    
}

- (IBAction)singleLocationButtonTouchUpInside:(id)sender {

    [[[[MMPReactiveCoreLocation service]
                                location]
                                subscribeOn:[RACScheduler mainThreadScheduler]]
                                subscribeNext:^(CLLocation *location) {
                                    NSString *locString = [NSString stringWithFormat:@"(%f, %f, %f)",
                                                           location.coordinate.latitude,
                                                           location.coordinate.longitude,
                                                           location.horizontalAccuracy];
                                    NSLog(@"[INFO] received single location: %@", locString);
                                    self.singleLocationLabel.text = locString;
                                }
                                completed:^{
                                    NSLog(@"[INFO] single location signal completed.");
                                }];
    
}

- (IBAction)significantLocationButtonTouchUpInside:(id)sender {
    
    if (!_significantService) {
        
        self.significantService = [MMPReactiveCoreLocation service];
        
        // subscribe to significant location changes
        [[[_significantService significantLocationChanges]
                               subscribeOn:[RACScheduler mainThreadScheduler]]
                               subscribeNext:^(CLLocation *location) {
                                   NSString *locString = [NSString stringWithFormat:@"(%f, %f, %f)",
                                                          location.coordinate.latitude,
                                                          location.coordinate.longitude,
                                                          location.horizontalAccuracy];
                                   NSLog(@"[INFO] received significant change location: %@", locString);
                                   self.significantLocationLabel.text = locString;
                               }];
        
        [_significantLocationButton setTitle:@"Stop significant location change signal" forState:UIControlStateNormal];
    } else {
        [_significantService stop];
        self.significantService = nil;
        [_significantLocationButton setTitle:@"Start significant location change signal" forState:UIControlStateNormal];
    }
    
}

- (IBAction)requestForAuthTouchUpInside:(id)sender {
    
    [[[[MMPReactiveCoreLocation service]
                                authorizeAlways]
                                authorize]
                                subscribeNext:^(NSNumber *statusNumber) {
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
