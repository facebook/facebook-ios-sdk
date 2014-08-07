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

#import "SCLoginViewController.h"

#import "SCErrorHandler.h"
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
        // Facebook SDK * pro-tip *
        // We wire up the FBLoginView using the interface builder
        // but we could have also explicitly wired its delegate here.
    }
    return self;
}

#pragma mark - View Management

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.loginView.readPermissions = @[@"public_profile", @"user_friends"];
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
        [FBSession openActiveSessionWithAllowLoginUI:NO];
        FBSession *session = [FBSession activeSession];
        if (settings.shouldSkipLogin || session.isOpen) {
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

#pragma mark - FBLoginViewDelegate

- (void)loginView:(FBLoginView *)loginView
      handleError:(NSError *)error {
    SCHandleError(error);
}

- (void)loginViewFetchedUserInfo:(FBLoginView *)loginView user:(id<FBGraphUser>)user
{
    NSString *title = [NSString stringWithFormat:@"continue as %@", [user name]];
    [self.continueButton setTitle:title forState:UIControlStateNormal];
}

- (void)loginViewShowingLoggedInUser:(FBLoginView *)loginView
{
    if (_viewIsVisible) {
        [self performSegueWithIdentifier:@"showMain" sender:loginView];
    }
}

- (void)loginViewShowingLoggedOutUser:(FBLoginView *)loginView
{
    if (_viewIsVisible) {
        [self performSegueWithIdentifier:@"continue" sender:loginView];
    }
    [self.continueButton setTitle:@"continue as a guest" forState:UIControlStateNormal];
}

@end
