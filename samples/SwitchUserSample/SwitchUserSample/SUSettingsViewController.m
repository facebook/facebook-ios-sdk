/*
 * Copyright 2012 Facebook
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#import "SUSettingsViewController.h"
#import "SUAppDelegate.h"
#import "SUProfileTableViewCell.h"
#import <FBiOSSDK/FBProfilePictureView.h>

@interface SUSettingsViewController ()

@property (weak, nonatomic) IBOutlet UITableView *usersTableView;
@property (strong, nonatomic) FBRequestConnection *requestConnection;
@property (nonatomic) int pendingLoginForSlot;

- (int)userSlotFromIndexPath:(NSIndexPath*)indexPath;
- (void)loginSlot:(int)slot;
- (NSIndexPath*)indexPathFromUserSlot:(int)slot;

@end

@implementation SUSettingsViewController

@synthesize usersTableView;
@synthesize requestConnection = _requestConnection;
@synthesize pendingLoginForSlot = _pendingLoginForSlot;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.title = NSLocalizedString(@"Settings", @"Settings");
        self.tabBarItem.image = [UIImage imageNamed:@"second"];
        self.pendingLoginForSlot = -1;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)viewDidUnload
{
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

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
    } else {
        return YES;
    }
}

- (void)updateCell:(SUProfileTableViewCell*)cell forSlot:(int)slot {
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

- (void)updateCellForSlot:(int)slot {    
    SUProfileTableViewCell *cell = (SUProfileTableViewCell *)[self.usersTableView cellForRowAtIndexPath:
                                                              [self indexPathFromUserSlot:slot]];
    [self updateCell:cell forSlot:slot];
}

- (void)updateForSessionChangeForSlot:(int)slot {
    SUAppDelegate *appDelegate = (SUAppDelegate *)[[UIApplication sharedApplication]delegate];
    SUUserManager *userManager = appDelegate.userManager;
    FBSession *session = userManager.currentSession;
    
    if (session.isValid) {       
        FBRequest *me = [FBRequest requestForMeWithSession:session];
        FBRequestConnection *requestConnection = [[FBRequestConnection alloc] init];

        [requestConnection addRequest:me completionHandler:^(FBRequestConnection *connection, 
                                                             NSDictionary<FBGraphUser> *result,
                                                             NSError *error) {
            if (connection != self.requestConnection) {
                return;
            }

            self.requestConnection = nil;
            self.pendingLoginForSlot = -1;

            if (error) {
                NSLog(@"Couldn't switch user: %@", error.localizedDescription);
                [userManager switchToNoActiveUser];
                return;
            }
            [userManager updateUser:result inSlot:slot];
            [self updateCellForSlot:slot];
        }];
        
        [self.requestConnection cancel];
        self.requestConnection = requestConnection;
        
        [requestConnection start];
    } else {
        if (session.status == FBSessionStateLoadedValidToken) {
            // even though we had a cached token, we need to login to make the session usable
            [session loginWithCompletionHandler:^(FBSession *session, 
                                                  FBSessionState status, 
                                                  NSError *error) {
                [self updateForSessionChangeForSlot:slot];
            }];
        }
    }
}

- (void)loginSlot:(int)slot {
    SUAppDelegate *appDelegate = (SUAppDelegate *)[[UIApplication sharedApplication]delegate];
    SUUserManager *userManager = appDelegate.userManager;
    
    if (slot < 0 || slot >= userManager.maximumUserSlots) {
        return;
    }

    int currentUserSlot = userManager.currentUserSlot;

    // If we can't log in as new user, we don't want to still be logged in as previous user,
    //  particularly if it might not be obvious to the user that the login failed.
    [userManager switchToNoActiveUser];
    self.pendingLoginForSlot = slot;

    if (slot != currentUserSlot) {
        // Update the previously active user's cell
        if (currentUserSlot >= 0 && currentUserSlot < [userManager maximumUserSlots]) {
            [self updateCellForSlot:currentUserSlot];
        }
    }
    
    // We assume that the primary user is going to log on via SSO, while guest users will
    //  specify their name via the login dialog. The decision of when to try SSO vs.
    //  force entering of credentials will be specific to the needs of an app.
    FBSessionLoginBehavior behavior = (slot == 0) ?
        FBSessionLoginBehaviorSSOWithFallback :
        FBSessionLoginBehaviorSuppressSSO;

    FBSession *session = [userManager switchToUserInSlot:slot];
    [self updateCellForSlot:slot];

    [session loginWithBehavior:behavior
             completionHandler:^(FBSession *session,
                                 FBSessionState status,
                                 NSError *error) {
        if (error) {
            [userManager switchToNoActiveUser];
        }
        [self updateForSessionChangeForSlot:slot];
    }];
}

- (int)userSlotFromIndexPath:(NSIndexPath*)indexPath {
    // This relies on the fact that there's only one user in the first section.
    return indexPath.section + indexPath.row;
}

- (NSIndexPath*)indexPathFromUserSlot:(int)slot {
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
    
    SUProfileTableViewCell *cell = (SUProfileTableViewCell*)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[SUProfileTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }

    SUAppDelegate *appDelegate = (SUAppDelegate *)[[UIApplication sharedApplication]delegate];
    SUUserManager *userManager = appDelegate.userManager;
    int slot = [self userSlotFromIndexPath:indexPath];
    if (slot >= 0 && slot < [userManager maximumUserSlots] ) {
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
        int slot = [self userSlotFromIndexPath:indexPath];
        [userManager updateUser:nil inSlot:slot];
        [self updateCellForSlot:slot];
    }
}

#pragma mark -
#pragma mark UITableViewDelegate methods

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    SUProfileTableViewCell *cell = (SUProfileTableViewCell*)[self tableView:tableView
                                                      cellForRowAtIndexPath:indexPath];
    return cell.desiredHeight;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    SUAppDelegate *appDelegate = (SUAppDelegate *)[[UIApplication sharedApplication]delegate];
    SUUserManager *userManager = [appDelegate userManager];
    
    int currentUserSlot = userManager.currentUserSlot;
    int slot = [self userSlotFromIndexPath:indexPath];

    if (slot == currentUserSlot) {
        [userManager switchToNoActiveUser];
        [self updateCellForSlot:slot];
    } else {
        [self loginSlot:slot];
    }

    [tableView deselectRowAtIndexPath:indexPath animated:YES];    
    return;
}

- (NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath 
{
    return @"Forget";
}

#pragma mark -

@end
