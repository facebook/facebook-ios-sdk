//
//  BOGFirstViewController.h
//  BooleanOGSample
//
//  Created by Jason Clark on 4/19/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface BOGFirstViewController : UIViewController

@property (weak, nonatomic) IBOutlet UIPickerView *leftPicker;
@property (weak, nonatomic) IBOutlet UIPickerView *rightPicker;
@property (weak, nonatomic) IBOutlet UITextView *resultTextView;

- (IBAction)pressedAnd:(id)sender;
- (IBAction)pressedOr:(id)sender;

@end
