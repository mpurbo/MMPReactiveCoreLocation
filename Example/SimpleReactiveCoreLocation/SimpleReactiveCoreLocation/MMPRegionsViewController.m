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

@property (nonatomic, strong) MMPReactiveCoreLocation *service;

@end

@implementation MMPRegionsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (IBAction)regionMonitoringButtonTouchUpInside:(id)sender {
    
    if (!_service) {
        
        self.service = [MMPReactiveCoreLocation service];
        
        // somewhere in Tokyo
        [[[_service region:[[CLCircularRegion alloc] initWithCenter:CLLocationCoordinate2DMake(35.702069, 139.775327)
                                                             radius:100.0
                                                         identifier:@"Test-Region"]]
                    regionEvents]
                    subscribeNext:^(MMPRegionEvent *regionEvent) {
                        NSLog(@"[INFO] received event: %ld for region: %@", regionEvent.type, regionEvent.region.identifier);
                    }];
        
        [_regionMonitoringButton setTitle:@"Stop monitoring region" forState:UIControlStateNormal];
    } else {
        [_service stop];
        self.service = nil;
        [_regionMonitoringButton setTitle:@"Start monitoring region" forState:UIControlStateNormal];
    }
    
}

@end
