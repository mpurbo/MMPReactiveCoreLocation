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
@property (nonatomic, strong) RACSubject *doneSignalAuto1;
@property (nonatomic, strong) RACSubject *doneSignalAuto2;

@end

@implementation MMPViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)viewWillDisappear:(BOOL)animated
{
    if (_doneSignal) {
        // complete the doneSignal so the subscriber may cleanup and stop the global location signal
        [_doneSignal sendCompleted];
    }
    
    [super viewWillDisappear:animated];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)cleanupGlobalLocationSignal
{
    self.doneSignal = nil;
    [[MMPReactiveCoreLocation instance] stop];
    [_buttonGlobal setTitle:@"Start global location manager" forState:UIControlStateNormal];
}

- (IBAction)buttonGlobalTouchUpInside:(id)sender
{
    if (!_doneSignal) {
        
        self.doneSignal = [RACSubject subject];
        
        @weakify(self)
        
        [[[[MMPReactiveCoreLocation instance]
            locationSignal] // subscribe to default global location signal
            takeUntil:_doneSignal] // until doneSignal is completed
            subscribeNext:^(CLLocation *location) {
                @strongify(self)
                self.labelGlobal.text = [NSString stringWithFormat:@"(%f, %f, %f)", location.coordinate.latitude, location.coordinate.longitude, location.horizontalAccuracy];
                NSLog(@"Next global location updated: (%f, %f, %f)", location.coordinate.latitude, location.coordinate.longitude, location.horizontalAccuracy);
            }
            error:^(NSError *error) {
                @strongify(self)
                NSLog(@"Ouch! Global signal error: %@, cleaning up...", error);
                [self cleanupGlobalLocationSignal];
            }
            completed:^{
                @strongify(self)
                NSLog(@"Global signal completed, cleaning up...");
                [self cleanupGlobalLocationSignal];
            }];
        
        // start the global location signal
        [[MMPReactiveCoreLocation instance] start];
        
        [_buttonGlobal setTitle:@"Stop global location manager" forState:UIControlStateNormal];
        
    } else {
        // complete the doneSignal so the subscriber may cleanup and stop the global location signal
        [_doneSignal sendCompleted];
    }
}

- (IBAction)buttonSingleTouchUpInside:(id)sender
{
    @weakify(self)
    
    // one time location with accuracy <= 100 m, timeout 15 sec
    [[[MMPReactiveCoreLocation instance]
       singleLocationSignalWithAccuracy:100.0 timeout:15.0]
       subscribeNext:^(CLLocation *location) {
           @strongify(self)
           self.labelSingle.text = [NSString stringWithFormat:@"(%f, %f, %f)", location.coordinate.latitude, location.coordinate.longitude, location.horizontalAccuracy];
           NSLog(@"One-time location updated: (%f, %f, %f)", location.coordinate.latitude, location.coordinate.longitude, location.horizontalAccuracy);
       }
       error:^(NSError *error) {
           NSLog(@"Ouch! One-time signal error: %@", error);
       }];
}

- (void)cleanupAutoLocationSignal1
{
    self.doneSignalAuto1 = nil;
    [_buttonAuto1 setTitle:@"Start location signal 1" forState:UIControlStateNormal];
}

- (IBAction)buttonAuto1TouchUpInside:(id)sender
{
    if (!_doneSignalAuto1) {
        
        self.doneSignalAuto1 = [RACSubject subject];
        
        @weakify(self)
        
        [[[[MMPReactiveCoreLocation instance]
            autoLocationSignalWithLocationUpdateType:MMPRCLLocationUpdateTypeStandard]
            takeUntil:_doneSignalAuto1]
            subscribeNext:^(CLLocation *location) {
                @strongify(self)
                self.labelAuto1.text = [NSString stringWithFormat:@"(%f, %f, %f)", location.coordinate.latitude, location.coordinate.longitude, location.horizontalAccuracy];
                NSLog(@"Auto signal 1 location updated: (%f, %f, %f)", location.coordinate.latitude, location.coordinate.longitude, location.horizontalAccuracy);
            }
            error:^(NSError *error) {
                @strongify(self)
                NSLog(@"Ouch! Auto signal 1 error: %@", error);
                [self cleanupAutoLocationSignal1];
            }
            completed:^{
                @strongify(self)
                NSLog(@"Auto signal 1 completed");
                [self cleanupAutoLocationSignal1];
            }];
        
        [_buttonAuto1 setTitle:@"Stop location signal 1" forState:UIControlStateNormal];
        
    } else {
        [_doneSignalAuto1 sendCompleted];
    }
}

- (void)cleanupAutoLocationSignal2
{
    self.doneSignalAuto2 = nil;
    [_buttonAuto2 setTitle:@"Start location signal 2" forState:UIControlStateNormal];
}


- (IBAction)buttonAuto2TouchUpInside:(id)sender
{
    if (!_doneSignalAuto2) {
        
        self.doneSignalAuto2 = [RACSubject subject];
        
        @weakify(self)
        
        [[[[MMPReactiveCoreLocation instance]
            autoLocationSignalWithAccuracy:100.0 locationUpdateType:MMPRCLLocationUpdateTypeSignificantChange]
            takeUntil:_doneSignalAuto2]
            subscribeNext:^(CLLocation *location) {
                @strongify(self)
                self.labelAuto2.text = [NSString stringWithFormat:@"(%f, %f, %f)", location.coordinate.latitude, location.coordinate.longitude, location.horizontalAccuracy];
                NSLog(@"Auto signal 2 location updated: (%f, %f, %f)", location.coordinate.latitude, location.coordinate.longitude, location.horizontalAccuracy);
            }
            error:^(NSError *error) {
                @strongify(self)
                NSLog(@"Ouch! Auto signal 2 error: %@", error);
                [self cleanupAutoLocationSignal2];
            }
            completed:^{
                @strongify(self)
                NSLog(@"Auto signal 2 completed");
                [self cleanupAutoLocationSignal2];
            }];
        
        [_buttonAuto2 setTitle:@"Stop location signal 2" forState:UIControlStateNormal];
        
    } else {
        [_doneSignalAuto2 sendCompleted];
    }
}

@end
