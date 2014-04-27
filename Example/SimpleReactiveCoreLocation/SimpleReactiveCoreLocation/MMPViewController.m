//
//  MMPViewController.m
//  SimpleReactiveCoreLocation
//
//  Created by Purbo Mohamad on 4/26/14.
//  Copyright (c) 2014 Purbo. All rights reserved.
//

#import "MMPViewController.h"
#import <ReactiveCocoa/RACEXTScope.h>
#import <MMPReactiveCoreLocation/MMPReactiveCoreLocation.h>

@interface MMPViewController ()

@property (nonatomic, strong) RACSubject *doneSignal;

@end

@implementation MMPViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.doneSignal = [RACSubject subject];
	
    MMPReactiveCoreLocation *rcl = [MMPReactiveCoreLocation instance];
    
    @weakify(self)
    [[rcl.locationSignal takeUntil:_doneSignal] subscribeNext:^(CLLocation *nextLocation) {
        @strongify(self)
        self.labelLatLon.text = [NSString stringWithFormat:@"(%f, %f, %f)", nextLocation.coordinate.latitude, nextLocation.coordinate.longitude, nextLocation.horizontalAccuracy];
        NSLog(@"next location updated: (%f, %f, %f)", nextLocation.coordinate.latitude, nextLocation.coordinate.longitude, nextLocation.horizontalAccuracy);
    }];
    
    [rcl start];
}

- (void)viewWillDisappear:(BOOL)animated
{
    // so that this controller won't receive any more location signals
    [self.doneSignal sendCompleted];
    
    [[MMPReactiveCoreLocation instance] stop];
    [super viewWillDisappear:animated];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
