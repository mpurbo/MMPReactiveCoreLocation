//
//  MMPBeaconViewController.h
//  SimpleReactiveCoreLocation
//
//  Created by Purbo Mohamad on 6/20/14.
//  Copyright (c) 2014 Purbo. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MMPBeaconViewController : UIViewController

@property (strong, nonatomic) IBOutlet UILabel *labelMonitoring;
@property (strong, nonatomic) IBOutlet UILabel *labelRanging;
@property (strong, nonatomic) IBOutlet UIButton *buttonMonitoring;

- (IBAction)buttonMonitoringTouchUpInside:(id)sender;

@end
