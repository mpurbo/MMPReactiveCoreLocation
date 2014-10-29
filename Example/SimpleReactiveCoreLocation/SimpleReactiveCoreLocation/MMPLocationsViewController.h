//
//  MMPLocationsViewController.h
//  SimpleReactiveCoreLocation
//
//  Created by Purbo Mohamad on 10/6/14.
//  Copyright (c) 2014 Purbo. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MMPLocationsViewController : UIViewController

@property (strong, nonatomic) IBOutlet UILabel *locationLabel;
@property (strong, nonatomic) IBOutlet UIButton *locationButton;
@property (strong, nonatomic) IBOutlet UILabel *singleLocationLabel;
@property (strong, nonatomic) IBOutlet UILabel *significantLocationLabel;
@property (strong, nonatomic) IBOutlet UIButton *significantLocationButton;

- (IBAction)locationButtonTouchUpInside:(id)sender;
- (IBAction)singleLocationButtonTouchUpInside:(id)sender;
- (IBAction)significantLocationButtonTouchUpInside:(id)sender;

@end
