//
//  MMPRegionsViewController.m
//  SimpleReactiveCoreLocation
//
//  Created by Purbo Mohamad on 11/3/14.
//  Copyright (c) 2014 Purbo. All rights reserved.
//

#import "MMPRegionsViewController.h"
#import <MMPReactiveCoreLocation/MMPReactiveCoreLocation.h>

@interface MMPRegionsViewController ()

@property (nonatomic, strong) RACSubject *regionMonitoringDoneSubject;

@end

@implementation MMPRegionsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (IBAction)regionMonitoringButtonTouchUpInside:(id)sender {
    
    if (!_regionMonitoringDoneSubject) {
        
        self.regionMonitoringDoneSubject = [RACSubject subject];
        
        MMPLocationManager *service = [MMPLocationManager new];
        
        CLRegion *region = [[CLCircularRegion alloc] initWithCenter:CLLocationCoordinate2DMake(40.733604, -73.992110)
                                                             radius:100.0
                                                         identifier:@"Test-Region"];
        
        [[[[service stop:_regionMonitoringDoneSubject]
                    region:region]
                    regionEvents]
                    subscribeNext:^(MMPRegionEvent *regionEvent) {
                        NSLog(@"[INFO] received event: %ld for region: %@", regionEvent.type, regionEvent.region.identifier);
                    }
                    completed:^{
                        self.regionMonitoringDoneSubject = nil;
                    }];
        
        [[service errors] subscribeNext:^(NSError *error) {
            NSLog(@"[ERROR] Location service error: %@", error);
        }];
        
        [_regionMonitoringButton setTitle:@"Stop location signal" forState:UIControlStateNormal];
        
    } else {
        
        [_regionMonitoringDoneSubject sendCompleted];
        [_regionMonitoringButton setTitle:@"Start location signal" forState:UIControlStateNormal];
        
    }
    
}

@end
