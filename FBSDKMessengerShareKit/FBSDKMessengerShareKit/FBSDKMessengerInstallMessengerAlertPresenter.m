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

#import "FBSDKMessengerInstallMessengerAlertPresenter.h"

static NSString *const kMessengerAppStoreLink = @"itms-apps://itunes.apple.com/app/id454638411";

@interface FBSDKMessengerInstallMessengerAlertPresenter () <UIAlertViewDelegate>
@end

@implementation FBSDKMessengerInstallMessengerAlertPresenter

+ (instancetype)sharedInstance
{
  static FBSDKMessengerInstallMessengerAlertPresenter *sharedInstance = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    sharedInstance = [[self alloc] init];
  });
  return sharedInstance;
}

#pragma mark - Public

- (void)presentInstallMessengerAlert
{
  UIAlertView * alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Get Messenger", @"Alert title telling a user they need to install Messenger")
                                                   message:NSLocalizedString(@"You are using an older version of Messenger that does not support this feature.", @"Message when an old version of messenger is installed")
                                                  delegate:self
                                         cancelButtonTitle:NSLocalizedString(@"Not Now", @"Button label when user doesn't want to install Messenger")
                                         otherButtonTitles:NSLocalizedString(@"Install", @"Button label to install Messenger"), nil];
  [alert show];
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
  if (buttonIndex == alertView.firstOtherButtonIndex) {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:kMessengerAppStoreLink]];
  }
}

@end
