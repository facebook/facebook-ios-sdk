// Copyright (c) 2014-present, Facebook, Inc. All rights reserved.
//
// You are hereby granted a non-exclusive, worldwide, royalty-free license to use,
// copy, modify, and distribute this software in source code or binary form for use
// in connection with the web services and APIs provided by Facebook.
//
// As with any software that integrates with the Facebook platform, your use of
// this software is subject to the Facebook Developer Principles and Policies
// [http://developers.facebook.com/policy/]. This copyright notice shall be
// included in all copies or substantial portions of the software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
// FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
// COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
// IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
// CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

#import <UIKit/UIKit.h>

#import <FBSDKShareKit/FBSDKShareKit.h>

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
@property (weak, nonatomic) IBOutlet FBSDKShareButton *fbShareButton;
@property (weak, nonatomic) IBOutlet FBSDKSendButton *fbSendButton;
@property (strong, nonatomic) IBOutlet UILabel *photoViewPlaceholderLabel;

- (IBAction)pickMeal:(id)sender;
- (IBAction)share:(id)sender;
- (IBAction)showMain:(UIStoryboardSegue *)segue;

@end
