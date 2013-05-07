/*
 * Copyright 2010-present Facebook.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 * 
 *    http://www.apache.org/licenses/LICENSE-2.0
 
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#import <UIKit/UIKit.h>

@interface RPSGameViewController : UIViewController

@property (unsafe_unretained, nonatomic) IBOutlet UILabel  *rockLabel;
@property (unsafe_unretained, nonatomic) IBOutlet UILabel  *paperLabel;
@property (unsafe_unretained, nonatomic) IBOutlet UILabel  *scissorsLabel;

@property (unsafe_unretained, nonatomic) IBOutlet UILabel  *shootLabel;

@property (unsafe_unretained, nonatomic) IBOutlet UIImageView *playerHand;
@property (unsafe_unretained, nonatomic) IBOutlet UIImageView *computerHand;

@property (unsafe_unretained, nonatomic) IBOutlet UIButton *rockButton;
@property (unsafe_unretained, nonatomic) IBOutlet UIButton *paperButton;
@property (unsafe_unretained, nonatomic) IBOutlet UIButton *scissorsButton;

@property (unsafe_unretained, nonatomic) IBOutlet UIButton *againButton;
@property (unsafe_unretained, nonatomic) IBOutlet UIButton *facebookButton;

@property (unsafe_unretained, nonatomic) IBOutlet UILabel  *resultLabel;
@property (unsafe_unretained, nonatomic) IBOutlet UILabel  *scoreLabel;

- (IBAction)clickRPSButton:(id)sender;
- (IBAction)clickAgainButton:(id)sender;
- (IBAction)clickFacebookButton:(id)sender;

@end
