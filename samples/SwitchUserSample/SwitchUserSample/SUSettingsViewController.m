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
@end

@implementation SUSettingsViewController

@synthesize usersTableView;
@synthesize requestConnection = _requestConnection;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.title = NSLocalizedString(@"Settings", @"Settings");
        self.tabBarItem.image = [UIImage imageNamed:@"second"];
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
        cell.userName = [userManager getUserNameInSlot:slot];
        cell.userID = userID;
        if (slot == [userManager currentUserSlot]) {
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
        }
    }
}

- (void)updateCellForSlot:(int)slot {    
    SUProfileTableViewCell *cell = (SUProfileTableViewCell *)[self.usersTableView cellForRowAtIndexPath:
                                                              [NSIndexPath indexPathForRow:slot inSection:0]];
    [self updateCell:cell forSlot:slot];
}

- (void)updateForSessionChangeForSlot:(int)slot {
    SUAppDelegate *appDelegate = (SUAppDelegate *)[[UIApplication sharedApplication]delegate];
    SUUserManager *userManager = appDelegate.userManager;
    FBSession *session = userManager.currentSession;
    
    if (session.isValid) {       
        FBRequest *me = [FBRequest requestMeForSession:session];
        FBRequestConnection *requestConnection = [[FBRequestConnection alloc] init];
        [requestConnection addRequest:me completionHandler:^(FBRequestConnection *connection, 
                                                             NSDictionary<FBGraphPerson> *result, 
                                                             NSError *error) {
            if (connection != self.requestConnection) {
                return;
            }
            self.requestConnection = nil;
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
    
    FBSession *session = [userManager switchToUserInSlot:slot];
    [session loginWithBehavior:FBSessionLoginBehaviorSuppressSSO
             completionHandler:^(FBSession *session,
                                 FBSessionState status,
                                 NSError *error) {
        if (error) {
            [userManager switchToNoActiveUser];
        }
        [self updateForSessionChangeForSlot:slot];
    }];
}

// UITableViewDataSource methods

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    SUAppDelegate *appDelegate = (SUAppDelegate *)[[UIApplication sharedApplication]delegate];
    SUUserManager *userManager = appDelegate.userManager;
    return [userManager maximumUserSlots];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    
    SUProfileTableViewCell *cell = (SUProfileTableViewCell*)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[SUProfileTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }

    SUAppDelegate *appDelegate = (SUAppDelegate *)[[UIApplication sharedApplication]delegate];
    SUUserManager *userManager = appDelegate.userManager;
    int row = indexPath.row;
    if (row >= 0 && row < [userManager maximumUserSlots] ) {
        [self updateCell:cell forSlot:row];
    }
    
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return @"Active User:";
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    SUAppDelegate *appDelegate = (SUAppDelegate *)[[UIApplication sharedApplication]delegate];
    SUUserManager *userManager = [appDelegate userManager];
    return [userManager getUserIDInSlot:indexPath.row] != nil;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    SUAppDelegate *appDelegate = (SUAppDelegate *)[[UIApplication sharedApplication]delegate];
    SUUserManager *userManager = [appDelegate userManager];
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        [userManager updateUser:nil inSlot:indexPath.row];
        [self updateCellForSlot:indexPath.row];
    }
}

// UITableViewDelegate methods

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    SUProfileTableViewCell *cell = (SUProfileTableViewCell*)[self tableView:tableView
                                                      cellForRowAtIndexPath:indexPath];
    return cell.desiredHeight;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    SUAppDelegate *appDelegate = (SUAppDelegate *)[[UIApplication sharedApplication]delegate];
    SUUserManager *userManager = [appDelegate userManager];
    
    int currentUserSlot = userManager.currentUserSlot;
    
    [userManager switchToNoActiveUser];
    [self updateCellForSlot:indexPath.row];
    
    if (indexPath.row != currentUserSlot) {
        // TODO clean this up
        [self loginSlot:indexPath.row];
        // Update the previously active user's cell
        if (currentUserSlot >= 0 && currentUserSlot < [userManager maximumUserSlots]) {
            [self updateCellForSlot:currentUserSlot];
        }
        
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];    
    return;
}

- (NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath 
{
    return @"Forget";
}

@end
