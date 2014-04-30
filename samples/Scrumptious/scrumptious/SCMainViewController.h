/*
 * Copyright 2010-present Facebook.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#import <UIKit/UIKit.h>

#import <FacebookSDK/FacebookSDK.h>

#import "SCProfilePictureButton.h"

@interface SCMainViewController : UIViewController

@property (nonatomic, strong) IBOutlet UIButton *friendsButton;
@property (nonatomic, strong) IBOutlet UILabel *friendsLabel;
@property (nonatomic, strong) IBOutlet UIButton *mealButton;
@property (nonatomic, strong) IBOutlet UILabel *mealLabel;
@property (nonatomic, strong) IBOutlet UIButton *locationButton;
@property (nonatomic, strong) IBOutlet UILabel *locationLabel;
@property (nonatomic, strong) IBOutlet UIButton *photoButton;
@property (nonatomic, strong) IBOutlet UIImageView *photoView;
@property (nonatomic, strong) IBOutlet SCProfilePictureButton *profilePictureButton;
@property (nonatomic, strong) IBOutlet UIButton *shareButton;

- (IBAction)pickMeal:(id)sender;
- (IBAction)share:(id)sender;
- (IBAction)showMain:(UIStoryboardSegue *)segue;

@end
