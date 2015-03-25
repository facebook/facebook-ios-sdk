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

#import "SUActiveViewController.h"

#import <UIKit/UIKit.h>

#import <FBSDKCoreKit/FBSDKCoreKit.h>

@implementation SUActiveViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.profilePictureView.profileID = @"me";
    [self.subtitleLabel addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(_tapLink:)]];
    [self _updateContent:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(_updateContent:)
                                                 name:FBSDKProfileDidChangeNotification
                                               object:nil];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)_updateContent:(NSNotification *)notification
{
    if ([FBSDKAccessToken currentAccessToken]) {
        self.titleLabel.hidden = NO;
        self.titleLabel.text = [FBSDKProfile currentProfile].name;
        self.subtitleLabel.text = [FBSDKProfile currentProfile].linkURL.absoluteString;
    } else {
        self.titleLabel.hidden = YES;
        self.subtitleLabel.text = @"No active user. Go to Accounts tab to log in!";
    }
}

- (void)_tapLink:(UITapGestureRecognizer *)gesture
{
    if ([FBSDKAccessToken currentAccessToken]) {
        NSURL *url = [NSURL URLWithString:self.subtitleLabel.text];
        [[UIApplication sharedApplication] openURL:url];
    }
}

@end
