//
//  MMPViewController.h
//  SimpleReactiveCoreLocation
//
//  Created by Purbo Mohamad on 4/26/14.
//  Copyright (c) 2014 Purbo. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MMPViewController : UIViewController

@property (strong, nonatomic) IBOutlet UILabel *labelGlobal;
@property (strong, nonatomic) IBOutlet UILabel *labelSingle;
@property (strong, nonatomic) IBOutlet UILabel *labelAuto1;
@property (strong, nonatomic) IBOutlet UILabel *labelAuto2;

@property (strong, nonatomic) IBOutlet UIButton *buttonGlobal;
@property (strong, nonatomic) IBOutlet UIButton *buttonSingle;
@property (strong, nonatomic) IBOutlet UIButton *buttonAuto1;
@property (strong, nonatomic) IBOutlet UIButton *buttonAuto2;

- (IBAction)buttonGlobalTouchUpInside:(id)sender;
- (IBAction)buttonSingleTouchUpInside:(id)sender;
- (IBAction)buttonAuto1TouchUpInside:(id)sender;
- (IBAction)buttonAuto2TouchUpInside:(id)sender;

@end
