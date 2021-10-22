/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <UIKit/UIKit.h>

@interface RPSGameViewController : UIViewController

@property (nonatomic, unsafe_unretained) IBOutlet UILabel *rockLabel;
@property (nonatomic, unsafe_unretained) IBOutlet UILabel *paperLabel;
@property (nonatomic, unsafe_unretained) IBOutlet UILabel *scissorsLabel;

@property (nonatomic, unsafe_unretained) IBOutlet UILabel *shootLabel;

@property (nonatomic, unsafe_unretained) IBOutlet UIImageView *playerHand;
@property (nonatomic, unsafe_unretained) IBOutlet UIImageView *computerHand;

@property (nonatomic, unsafe_unretained) IBOutlet UIButton *rockButton;
@property (nonatomic, unsafe_unretained) IBOutlet UIButton *paperButton;
@property (nonatomic, unsafe_unretained) IBOutlet UIButton *scissorsButton;

@property (nonatomic, unsafe_unretained) IBOutlet UIButton *againButton;
@property (nonatomic, unsafe_unretained) IBOutlet UIButton *facebookButton;

@property (nonatomic, unsafe_unretained) IBOutlet UILabel *resultLabel;
@property (nonatomic, unsafe_unretained) IBOutlet UILabel *scoreLabel;

- (IBAction)clickRPSButton:(id)sender;
- (IBAction)clickAgainButton:(id)sender;
- (IBAction)clickFacebookButton:(id)sender;

@end
