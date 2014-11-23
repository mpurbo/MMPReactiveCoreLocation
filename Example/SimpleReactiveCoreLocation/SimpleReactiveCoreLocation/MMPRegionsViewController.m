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

@property (nonatomic, strong) RACSubject *regionCommandSubject;

@end

@implementation MMPRegionsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
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

- (IBAction)regionMonitoringButtonTouchUpInside:(id)sender {

    
    
    /*
    if (!_regionMonitoringDoneSubject) {
        
        self.regionMonitoringDoneSubject = [RACSubject subject];
        
        MMPLocationManager *service = [MMPLocationManager new];
        
        [[[[[service regionCommand:<#(RACSignal *)#>] stop:_regionMonitoringDoneSubject]
           regionEvents]
          subscribeOn:[RACScheduler mainThreadScheduler]]
         subscribeNext:^(CLLocation *location) {
             
//             NSString *locString = [NSString stringWithFormat:@"(%f, %f, %f)",
//                                    location.coordinate.latitude,
//                                    location.coordinate.longitude,
//                                    location.horizontalAccuracy];
//             NSLog(@"[INFO] received location: %@", locString);
//             self.regionMonitoringStatusLabel.text = locString;
             
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
    */
    
    /*
     City Bicycle Ride
     
    37.330431, -122.030091
    
    37.3303, -122.0301
    37.3305, -122.03008
    */

    
}
@end
