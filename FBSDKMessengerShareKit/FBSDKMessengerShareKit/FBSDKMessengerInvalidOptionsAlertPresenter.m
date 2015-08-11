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

#import "FBSDKMessengerInvalidOptionsAlertPresenter.h"

@implementation FBSDKMessengerInvalidOptionsAlertPresenter

+ (instancetype)sharedInstance
{
  static FBSDKMessengerInvalidOptionsAlertPresenter *sharedInstance = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    sharedInstance = [[self alloc] init];
  });
  return sharedInstance;
}

#pragma mark - Public

- (void)presentInvalidOptionsAlert
{
  UIAlertView * alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Invalid Options", @"Alert title telling the developers that they provided invalid options.")
                                                   message:NSLocalizedString(@"You need to provide valid options", @"Message when invalid options are provided.")
                                                  delegate:self
                                         cancelButtonTitle:NSLocalizedString(@"OK", @"Button label when the developers have acknowledged the error.")
                                         otherButtonTitles:nil, nil];
  [alert show];

}

@end
