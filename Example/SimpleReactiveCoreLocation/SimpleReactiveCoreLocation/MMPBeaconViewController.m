//
//  MMPBeaconViewController.m
//  SimpleReactiveCoreLocation
//
//  Created by Purbo Mohamad on 6/20/14.
//  Copyright (c) 2014 Purbo. All rights reserved.
//

#import "MMPBeaconViewController.h"
#import <ReactiveCocoa/RACEXTScope.h>
#import <MMPReactiveCoreLocation/MMPReactiveCoreLocation.h>

@interface MMPBeaconViewController ()

@property (nonatomic, strong) RACSubject *doneMonitoring;
@property (nonatomic, strong) RACSubject *doneRanging;

@end

@implementation MMPBeaconViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [self cleanupSignals];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (void)cleanupSignals
{
    if (self.doneRanging) {
        [_doneRanging sendCompleted];
        self.doneRanging = nil;
    }
    
    if (self.doneMonitoring) {
        [_doneMonitoring sendCompleted];
        self.doneMonitoring = nil;
    }
}

- (IBAction)buttonMonitoringTouchUpInside:(id)sender
{
    if (self.doneMonitoring) {
        [_doneMonitoring sendCompleted];
        [_buttonMonitoring setTitle:@"Start Monitoring Beacon" forState:UIControlStateNormal];
    } else {
        self.doneMonitoring = [[RACSubject alloc] init];
        [_buttonMonitoring setTitle:@"Stop Monitoring Beacon" forState:UIControlStateNormal];
        
        @weakify(self)
        
        [[[[MMPReactiveCoreLocation instance] beaconMonitorWithProximityUUID:[[NSUUID alloc] initWithUUIDString:@"A77A1B68-49A7-4DBF-914C-760D07FBB87B"]
                                                                  identifier:@"com.appcoda.testregion"]
                                              takeUntil:_doneMonitoring]
                                              subscribeNext:^(MMPRCLBeaconEvent *event) {
                                                  
                                                  @strongify(self)
                                                  
                                                  if (event.eventType == MMPRCLBeaconEventTypeRegionStateUpdated) {
                                                      if (event.regionState == CLRegionStateInside) {
                                                          // entering a region
                                                          NSLog(@"Entering beacon region: %@, now ranging...", event.region.identifier);
                                                          
                                                          CLBeaconRegion *beaconRegion = (CLBeaconRegion *)event.region;
                                                          
                                                          // start ranging
                                                          self.doneRanging = [[RACSubject alloc] init];
                                                          [[[[MMPReactiveCoreLocation instance] beaconRangeWithProximityUUID:beaconRegion.proximityUUID
                                                                                                                identifier:beaconRegion.identifier]
                                                                                                takeUntil:_doneRanging]
                                                                                                subscribeNext:^(MMPRCLBeaconEvent *rangingEvent) {
                                                                                                    NSLog(@"There are %ld beacons ranged", [rangingEvent.rangedBeacons count]);
                                                                                                    for (CLBeacon *beacon in rangingEvent.rangedBeacons) {
                                                                                                        NSString *proximity = @"Unknown";
                                                                                                        if (beacon.proximity == CLProximityFar) {
                                                                                                            proximity = @"Far";
                                                                                                        } else if (beacon.proximity == CLProximityNear) {
                                                                                                            proximity = @"Near";
                                                                                                        } else if (beacon.proximity == CLProximityImmediate) {
                                                                                                            proximity = @"Immediate";
                                                                                                        }
                                                                                                        NSLog(@"Beacon UUID: %@, proximity: %@", beacon.proximityUUID, proximity);
                                                                                                    }
                                                                                                }
                                                                                                error:^(NSError *error) {
                                                                                                    NSLog(@"Beacon ranging error: %@", error);
                                                                                                    [self cleanupSignals];
                                                                                                }
                                                                                                completed:^{
                                                                                                    NSLog(@"Beacon ranging subscription completed.");
                                                                                                    [self cleanupSignals];
                                                                                                }];
                                                          
                                                      } else if (event.regionState == CLRegionStateOutside) {
                                                          // leaving a region
                                                          NSLog(@"Leaving beacon region: %@", event.region.identifier);
                                                          // stop ranging
                                                          if (self.doneRanging) {
                                                              [_doneRanging sendCompleted];
                                                              self.doneRanging = nil;
                                                          }
                                                      }
                                                  }
                                              }
                                              error:^(NSError *error) {
                                                  NSLog(@"Beacon monitoring error: %@", error);
                                                  [self cleanupSignals];
                                              }
                                              completed:^{
                                                  NSLog(@"Beacon monitoring subscription completed.");
                                                  [self cleanupSignals];
                                              }];
    }
}

@end
