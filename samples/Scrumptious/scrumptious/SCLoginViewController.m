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

#import "SCAppDelegate.h"
#import "SCViewController.h"

@implementation SCLoginViewController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Facebook SDK * pro-tip *
        // We wire up the FBLoginView using the interface builder
        // but we could have also explicitly wired its delegate here.
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    self.navigationController.navigationBarHidden = YES;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (self.shouldSkipLogIn) {
        [self performSelector:@selector(transitionToMainViewController) withObject:nil afterDelay:.5];
    }
}

- (void)setShouldSkipLogIn:(BOOL)skip {
    [[NSUserDefaults standardUserDefaults] setBool:skip forKey:@"ScrumptiousSkipLogIn"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (BOOL)shouldSkipLogIn {
    return [[NSUserDefaults standardUserDefaults] boolForKey:@"ScrumptiousSkipLogIn"];
}

- (void)viewWillDisappear:(BOOL)animated {
    self.navigationController.navigationBarHidden = NO;
}

- (void)viewDidUnload {
    [self setFBLoginView:nil];
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)transitionToMainViewController {
    // this pop is a noop in some cases, and in others makes sure we don't try
    // to push the same controller twice
    [self.navigationController popToRootViewControllerAnimated:NO];

    // Upon login, transition to the main UI by pushing it onto the navigation stack.
    SCAppDelegate *appDelegate = (SCAppDelegate *)[UIApplication sharedApplication].delegate;
    [self.navigationController pushViewController:appDelegate.mainViewController animated:YES];
}

#pragma mark - FBLoginView delegate

- (void)loginViewShowingLoggedInUser:(FBLoginView *)loginView {
    // if you become logged in, no longer flag to skip log in
    self.shouldSkipLogIn = NO;
    [self transitionToMainViewController];
}

- (void)loginView:(FBLoginView *)loginView
      handleError:(NSError *)error {
    NSString *alertMessage, *alertTitle;

    // Facebook SDK * error handling *
    // Error handling is an important part of providing a good user experience.
    // Since this sample uses the FBLoginView, this delegate will respond to
    // login failures, or other failures that have closed the session (such
    // as a token becoming invalid). Please see the [- postOpenGraphAction:]
    // and [- requestPermissionAndPost] on `SCViewController` for further
    // error handling on other operations.
    FBErrorCategory errorCategory = [FBErrorUtility errorCategoryForError:error];
    if ([FBErrorUtility shouldNotifyUserForError:error]) {
        // If the SDK has a message for the user, surface it. This conveniently
        // handles cases like password change or iOS6 app slider state.
        alertTitle = @"Something Went Wrong";
        alertMessage = [FBErrorUtility userMessageForError:error];
    } else if (errorCategory == FBErrorCategoryAuthenticationReopenSession) {
        // It is important to handle session closures as mentioned. You can inspect
        // the error for more context but this sample generically notifies the user.
        alertTitle = @"Session Error";
        alertMessage = @"Your current session is no longer valid. Please log in again.";
    } else if (errorCategory == FBErrorCategoryUserCancelled) {
        // The user has cancelled a login. You can inspect the error
        // for more context. For this sample, we will simply ignore it.
        NSLog(@"user cancelled login");
    } else {
        // For simplicity, this sample treats other errors blindly, but you should
        // refer to https://developers.facebook.com/docs/technical-guides/iossdk/errors/ for more information.
        alertTitle  = @"Unknown Error";
        alertMessage = @"Error. Please try again later.";
        NSLog(@"Unexpected error:%@", error);
    }

    if (alertMessage) {
        [[[UIAlertView alloc] initWithTitle:alertTitle
                                    message:alertMessage
                                   delegate:nil
                          cancelButtonTitle:@"OK"
                          otherButtonTitles:nil] show];
    }
}

- (void)loginViewShowingLoggedOutUser:(FBLoginView *)loginView {
    // Facebook SDK * login flow *
    // It is important to always handle session closure because it can happen
    // externally; for example, if the current session's access token becomes
    // invalid. For this sample, we simply pop back to the landing page.
    SCAppDelegate *appDelegate = (SCAppDelegate *)[UIApplication sharedApplication].delegate;
    if (appDelegate.isNavigatingAwayFromLogin) {
        // The delay is for the edge case where a session is immediately closed after
        // logging in and our navigation controller is still animating a push.
        [self performSelector:@selector(logOut) withObject:nil afterDelay:.5];
    } else {
        [self logOut];
    }
}

- (void)logOut {
    // on log out we reset the main view controller
    SCAppDelegate *appDelegate = (SCAppDelegate *)[UIApplication sharedApplication].delegate;
    [appDelegate resetMainViewController];
    [self.navigationController popToRootViewControllerAnimated:YES];
}

- (IBAction)clickSkipLogIn:(id)sender {
    self.shouldSkipLogIn = YES;
    [self transitionToMainViewController];
}
@end
