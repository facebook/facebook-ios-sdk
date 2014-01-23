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

@interface PPViewController : UIViewController

// FBSample logic
// The views and view controllers in the SDK are designed to fit into your application in
// a similar fashion to other framework and custom view classes; this is an example of a
// typical outlet for the FBPriflePictureView
@property (retain, nonatomic) IBOutlet FBProfilePictureView *profilePictureView;
@property (retain, nonatomic) IBOutlet UIView *profilePictureOuterView;

- (IBAction)showJasonProfile:(id)sender;
- (IBAction)showMichaelProfile:(id)sender;
- (IBAction)showVijayeProfile:(id)sender;
- (IBAction)showRandomProfile:(id)sender;
- (IBAction)showNoProfile:(id)sender;

- (IBAction)makePictureOriginal:(id)sender;
- (IBAction)makePictureSquare:(id)sender;

- (IBAction)makeViewSmall:(id)sender;
- (IBAction)makeViewLarge:(id)sender;

@end
