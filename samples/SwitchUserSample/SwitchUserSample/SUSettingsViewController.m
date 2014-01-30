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

#import "SUSettingsViewController.h"

#import <FacebookSDK/FacebookSDK.h>

#import "SUAppDelegate.h"
#import "SUProfileTableViewCell.h"

@interface SUSettingsViewController ()

@property (strong, nonatomic) IBOutlet UITableView *usersTableView;
// FBSample logic
// The app fetches https://graph.facebook.com/me for a user account immedately after successful login;
// the request object is cached in this property in order to have a means for canceling and identifying
// the network request while it is in flight
@property (strong, nonatomic) FBRequest *pendingRequest;
@property (nonatomic) NSInteger pendingLoginForSlot;

- (NSInteger)userSlotFromIndexPath:(NSIndexPath *)indexPath;
- (void)loginSlot:(NSInteger)slot;
- (NSIndexPath *)indexPathFromUserSlot:(NSInteger)slot;

@end

@implementation SUSettingsViewController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.title = NSLocalizedString(@"Settings", @"Settings");
        self.tabBarItem.image = [UIImage imageNamed:@"second"];
        self.pendingLoginForSlot = -1;
    }
    return self;
}

- (void)viewDidUnload {
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
    self.usersTableView.delegate = nil;
    self.usersTableView.dataSource = nil;
    self.usersTableView = nil;
}

- (void)loginDefaultUser {
    SUAppDelegate *appDelegate = (SUAppDelegate *)[[UIApplication sharedApplication]delegate];
    SUUserManager *userManager = appDelegate.userManager;

    if (![userManager isSlotEmpty:0]) {
        [self loginSlot:0];
    }
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
    } else {
        return YES;
    }
}

- (void)updateCell:(SUProfileTableViewCell *)cell
           forSlot:(NSInteger)slot {
    SUAppDelegate *appDelegate = (SUAppDelegate *)[[UIApplication sharedApplication]delegate];
    SUUserManager *userManager = appDelegate.userManager;

    NSString *userID = [userManager getUserIDInSlot:slot];

    cell.accessoryType = UITableViewCellAccessoryNone;
    if (userID == nil) {
        cell.userName = @"Empty slot";
        cell.userID = nil;
    } else {
        if (slot == self.pendingLoginForSlot) {
            cell.userName = @"Logging in...";
        } else {
            cell.userName = [userManager getUserNameInSlot:slot];
        }
        cell.userID = userID;
        if (slot == [userManager currentUserSlot]) {
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
        }
    }
}

- (void)updateCellForSlot:(NSInteger)slot {
    SUProfileTableViewCell *cell = (SUProfileTableViewCell *)[self.usersTableView cellForRowAtIndexPath:
                                                              [self indexPathFromUserSlot:slot]];
    [self updateCell:cell forSlot:slot];
}

- (void)updateForSessionChangeForSlot:(NSInteger)slot {
    SUAppDelegate *appDelegate = (SUAppDelegate *)[[UIApplication sharedApplication]delegate];
    SUUserManager *userManager = appDelegate.userManager;

    // FBSample logic
    // Get the current session from the userManager
    FBSession *session = userManager.currentSession;

    if (session.isOpen) {
        // fetch profile info such as name, id, etc. for the open session
        FBRequest *me = [[FBRequest alloc] initWithSession:session
                                                 graphPath:@"me"];

        self.pendingRequest= me;

        [me startWithCompletionHandler:^(FBRequestConnection *connection,
                                         NSDictionary<FBGraphUser> *result,
                                         NSError *error) {
            // because we have a cached copy of the connection, we can check
            // to see if this is the connection we care about; a prematurely
            // cancelled connection will short-circuit here
            if (me != self.pendingRequest) {
                return;
            }

            self.pendingRequest = nil;
            self.pendingLoginForSlot = -1;

            // we interpret an error in the initial fetch as a reason to
            // fail the user switch, and leave the application without an
            // active user (similar to initial state)
            if (error) {
                NSLog(@"Couldn't switch user: %@", error.localizedDescription);
                [userManager switchToNoActiveUser];
                return;
            }
            [userManager updateUser:result inSlot:slot];
            [self updateCellForSlot:slot];
        }];
    } else {
        // in the closed case, we check to see if we picked up a cached token that we
        // expect to be valid and ready for use; if so then we open the session on the spot
        if (session.state == FBSessionStateCreatedTokenLoaded) {
            // even though we had a cached token, we need to login to make the session usable
            [session openWithCompletionHandler:^(FBSession *innerSession,
                                                 FBSessionState status,
                                                 NSError *error) {
                [self updateForSessionChangeForSlot:slot];
            }];
        }
    }
}

- (void)loginSlot:(NSInteger)slot {
    SUAppDelegate *appDelegate = (SUAppDelegate *)[[UIApplication sharedApplication]delegate];
    SUUserManager *userManager = appDelegate.userManager;

    if (slot < 0 || slot >= userManager.maximumUserSlots) {
        return;
    }

    NSInteger currentUserSlot = userManager.currentUserSlot;

    // If we can't log in as new user, we don't want to still be logged in as previous user,
    // particularly if it might not be obvious to the user that the login failed.
    [userManager switchToNoActiveUser];
    self.pendingLoginForSlot = slot;

    if (slot != currentUserSlot) {
        // Update the previously active user's cell
        if (currentUserSlot >= 0 && currentUserSlot < [userManager maximumUserSlots]) {
            [self updateCellForSlot:currentUserSlot];
        }
    }

    // FBSample logic
    // We assume that the primary user is going to log on via Facebook Login, while guest users will
    // specify their name via the login dialog (Fallback Facebook Login.) The decision of when to try
    // Facebook Login vs. Fallback (force entering of credentials) will be specific to the needs of
    // an app; this app bases the decision on whether the user logs on the "primary user" or a "guest user"
    FBSessionLoginBehavior behavior = (slot == 0) ?
    FBSessionLoginBehaviorWithFallbackToWebView :
    FBSessionLoginBehaviorForcingWebView;

    FBSession *session = [userManager switchToUserInSlot:slot];
    [self updateCellForSlot:slot];

    // we pass the correct behavior here to indicate the login workflow to use (Facebook Login, fallback, etc.)
    [session openWithBehavior:behavior
            completionHandler:^(FBSession *innerSession,
                                FBSessionState status,
                                NSError *error) {
                // this handler is called back whether the login succeeds or fails; in the
                // success case it will also be called back upon each state transition between
                // session-open and session-close
                if (error) {
                    [userManager switchToNoActiveUser];
                }
                [self updateForSessionChangeForSlot:slot];
            }];
}

- (NSInteger)userSlotFromIndexPath:(NSIndexPath *)indexPath {
    // This relies on the fact that there's only one user in the first section.
    return indexPath.section + indexPath.row;
}

- (NSIndexPath *)indexPathFromUserSlot:(NSInteger)slot {
    // See comment in userSlotFromIndexPath:
    return [NSIndexPath indexPathForRow:(slot == 0) ? 0 : (slot - 1)
                              inSection:(slot == 0) ? 0 : 1];
}

#pragma mark UITableViewDataSource methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    SUAppDelegate *appDelegate = (SUAppDelegate *)[[UIApplication sharedApplication]delegate];
    SUUserManager *userManager = appDelegate.userManager;

    switch (section) {
        case 0:
            return 1;
        default:
            return [userManager maximumUserSlots] - 1;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";

    SUProfileTableViewCell *cell = (SUProfileTableViewCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[SUProfileTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }

    SUAppDelegate *appDelegate = (SUAppDelegate *)[[UIApplication sharedApplication]delegate];
    SUUserManager *userManager = appDelegate.userManager;
    NSInteger slot = [self userSlotFromIndexPath:indexPath];
    if (slot >= 0 && slot < [userManager maximumUserSlots]) {
        [self updateCell:cell forSlot:slot];
    }

    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    switch (section) {
        case 0:
            return @"Primary User:";
        default:
            return @"Guest Users:";
    }
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    SUAppDelegate *appDelegate = (SUAppDelegate *)[[UIApplication sharedApplication]delegate];
    SUUserManager *userManager = [appDelegate userManager];
    return [userManager getUserIDInSlot:[self userSlotFromIndexPath:indexPath]] != nil;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    SUAppDelegate *appDelegate = (SUAppDelegate *)[[UIApplication sharedApplication]delegate];
    SUUserManager *userManager = [appDelegate userManager];
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        NSInteger slot = [self userSlotFromIndexPath:indexPath];
        [userManager updateUser:nil inSlot:slot];
        [self updateCellForSlot:slot];
    }
}

#pragma mark -
#pragma mark UITableViewDelegate methods

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    SUProfileTableViewCell *cell = (SUProfileTableViewCell *)[self tableView:tableView
                                                       cellForRowAtIndexPath:indexPath];
    return cell.desiredHeight;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    SUAppDelegate *appDelegate = (SUAppDelegate *)[[UIApplication sharedApplication]delegate];
    SUUserManager *userManager = [appDelegate userManager];

    NSInteger currentUserSlot = userManager.currentUserSlot;
    NSInteger slot = [self userSlotFromIndexPath:indexPath];

    if (slot == currentUserSlot) {
        [userManager switchToNoActiveUser];
        [self updateCellForSlot:slot];
    } else {
        [self loginSlot:slot];
    }

    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    return;
}

- (NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath {
    return @"Forget";
}

@end
