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

#import "SCLoginViewController.h"

#import <FBSDKCoreKit/FBSDKCoreKit.h>

#import "SCSettings.h"

@implementation SCLoginViewController
{
    BOOL _viewDidAppear;
    BOOL _viewIsVisible;
}

#pragma mark - Object lifecycle

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
        // We wire up the FBSDKLoginButton using the interface builder
        // but we could have also explicitly wired its delegate here.
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - View Management

- (void)viewDidLoad
{
    [super viewDidLoad];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(observeProfileChange:) name:FBSDKProfileDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(observeTokenChange:) name:FBSDKAccessTokenDidChangeNotification object:nil];
    self.loginButton.readPermissions = @[@"public_profile", @"user_friends"];

    // If there's already a cached token, read the profile information.
    if ([FBSDKAccessToken currentAccessToken]) {
        [self observeProfileChange:nil];
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    SCSettings *settings = [SCSettings defaultSettings];
    if (_viewDidAppear) {
        _viewIsVisible = YES;

        // reset
        settings.shouldSkipLogin = NO;
    } else {
        if (settings.shouldSkipLogin || [FBSDKAccessToken currentAccessToken]) {
            [self performSegueWithIdentifier:@"showMain" sender:nil];
        } else {
            _viewIsVisible = YES;
        }
        _viewDidAppear = YES;
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];

    [SCSettings defaultSettings].shouldSkipLogin = YES;
    _viewIsVisible = NO;
}

#pragma mark - Actions

- (IBAction)showLogin:(UIStoryboardSegue *)segue
{
    // This method exists in order to create an unwind segue to this controller.
}

#pragma mark - FBSDKLoginButtonDelegate

- (void)loginButton:(FBSDKLoginButton *)loginButton didCompleteWithResult:(FBSDKLoginManagerLoginResult *)result error:(NSError *)error {
    if (error) {
        NSLog(@"Unexpected login error: %@", error);
        NSString *alertMessage = error.userInfo[FBSDKErrorLocalizedDescriptionKey] ?: @"There was a problem logging in. Please try again later.";
        NSString *alertTitle = error.userInfo[FBSDKErrorLocalizedTitleKey] ?: @"Oops";
        [[[UIAlertView alloc] initWithTitle:alertTitle
                                    message:alertMessage
                                   delegate:nil
                          cancelButtonTitle:@"OK"
                          otherButtonTitles:nil] show];
    } else {
        if (_viewIsVisible) {
            [self performSegueWithIdentifier:@"showMain" sender:self];
        }
    }
}

- (void)loginButtonDidLogOut:(FBSDKLoginButton *)loginButton {
    if (_viewIsVisible) {
        [self performSegueWithIdentifier:@"continue" sender:self];
    }
}

#pragma mark - Observations

- (void)observeProfileChange:(NSNotification *)notfication {
    if ([FBSDKProfile currentProfile]) {
        NSString *title = [NSString stringWithFormat:@"continue as %@", [FBSDKProfile currentProfile].name];
        [self.continueButton setTitle:title forState:UIControlStateNormal];
    }
}

- (void)observeTokenChange:(NSNotification *)notfication {
    if (![FBSDKAccessToken currentAccessToken]) {
        [self.continueButton setTitle:@"continue as a guest" forState:UIControlStateNormal];
    } else {
        [self observeProfileChange:nil];
    }
}

@end
