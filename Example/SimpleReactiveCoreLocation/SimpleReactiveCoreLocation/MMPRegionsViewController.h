//
//  MMPRegionsViewController.h
//  SimpleReactiveCoreLocation
//
//  Created by Purbo Mohamad on 11/3/14.
//  Copyright (c) 2014 Purbo. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MMPRegionsViewController : UIViewController

@property (strong, nonatomic) IBOutlet UILabel *regionMonitoringStatusLabel;
@property (strong, nonatomic) IBOutlet UIButton *regionMonitoringButton;

- (IBAction)regionMonitoringButtonTouchUpInside:(id)sender;

@end
