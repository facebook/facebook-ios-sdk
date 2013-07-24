/*
 * Copyright 2010-present Facebook.
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

#import "RPSFriendsViewController.h"
#import "RPSAppDelegate.h"
#import "OGProtocols.h"

@interface RPSFriendsViewController () <FBFriendPickerDelegate, UIAlertViewDelegate>

@property (readwrite, nonatomic, copy) NSString *fbidSelection;
@property (readwrite, nonatomic, retain) FBFrictionlessRecipientCache *friendCache;

- (void)updateActivityForID:(NSString *)fbid;

@end

@implementation RPSFriendsViewController

@synthesize activityTextView = _activityTextView;
@synthesize friendCache = _friendCache;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.title = NSLocalizedString(@"Rock w/Friends", @"Rock w/Friends");
        self.fieldsForRequest = [NSSet setWithObject:@"installed"];
        self.allowsMultipleSelection = NO;
        self.delegate = self;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.doneButton = nil;
}

- (void)refreshView {
    [self loadData];
    
    // we use frictionless requests, so let's get a cache and request the
    // current list of frictionless friends before enabling the invite button
    if (!self.friendCache) {
        self.friendCache = [[FBFrictionlessRecipientCache alloc] init];
        [self.friendCache prefetchAndCacheForSession:nil
                                   completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
                                       
                                       self.inviteButton.enabled = YES;
                                   }];
    } else  {
        // if we already have a primed cache, let's just run with it
        self.inviteButton.enabled = YES;
    }
}

#pragma mark - View lifecycle

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (FBSession.activeSession.isOpen) {
        [self refreshView];
    } else {
        self.inviteButton.enabled = NO;
        self.friendCache = nil;
        
        // display the message that we have
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Log In with Facebook"
                                                        message:@"When you Log In with Facebook, you can view "
                                                                @"friends' activity within Rock Paper Scissors, and "
                                                                @"invite friends to play.\n\n"
                                                                @"What would you like to do?"
                                                       delegate:self
                                              cancelButtonTitle:@"Do Nothing"
                                              otherButtonTitles:@"Log In", nil];
        [alert show];
    }
}

- (void)viewDidUnload {
    self.activityTextView = nil;

    [self setInviteButton:nil];
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
    } else {
        return YES;
    }
}

#pragma mark - FBFriendPickerDelegate implementation

// FBSample logic
// The following two methods implement the FBFriendPickerDelegate protocol. This shows an example of two
// interesting SDK features: 1) filtering support in the friend picker, 2) the "installed" field field when
// fetching me/friends. Filtering lets you choose whether or not to display each friend, based on application
// determined criteria; the installed field is present (and true) if the friend is also a user of the calling
// application.

- (void)friendPickerViewControllerSelectionDidChange:(FBFriendPickerViewController *)friendPicker {
    self.activityTextView.text = @"";
    if (friendPicker.selection.count) {
        [self updateActivityForID:[[friendPicker.selection objectAtIndex:0] id]];
    } else {
        self.fbidSelection = nil;
    }
}

- (BOOL)friendPickerViewController:(FBFriendPickerViewController *)friendPicker
                 shouldIncludeUser:(id <FBGraphUser>)user {
    return [[user objectForKey:@"installed"] boolValue];     
}

#pragma mark - private methods

// FBSample logic
// This is the workhorse method of this view. It updates the textView with the activity of a given user. It 
// accomplishes this by fetching the "throw" actions for the selected user.
- (void)updateActivityForID:(NSString *)fbid {
    
    // keep track of the selction
    self.fbidSelection = fbid;

    // create a request for the "throw" activity
    FBRequest *playActivity = [FBRequest requestForGraphPath:[NSString stringWithFormat:@"%@/fb_sample_rps:throw", fbid]];
    [playActivity.parameters setObject:@"U" forKey:@"date_format"];
    
    // this block is the one that does the real handling work for the requests
    void (^handleBlock)(id) = ^(id<RPSGraphActionList> result) {
        if (result) {
            for (id<RPSGraphPublishedThrowAction> entry in result.data) {
                // we  translate the date into something useful for sorting and displaying
                entry.publish_date = [NSDate dateWithTimeIntervalSince1970:entry.publish_time.intValue];
            }
        }

        // sort the array by date
        NSMutableArray *activity = [NSMutableArray arrayWithArray:result.data];
        [activity sortUsingComparator:^NSComparisonResult(id<RPSGraphPublishedThrowAction> obj1,
                                                          id<RPSGraphPublishedThrowAction> obj2) {
            if (obj1.publish_date && obj2.publish_date) {
                return [obj2.publish_date compare:obj1.publish_date];
            }
            return NSOrderedSame;
        }];
            
        NSMutableString *output = [NSMutableString string];
        for (id<RPSGraphPublishedThrowAction> entry in activity) {
            NSDateComponents *c = [[NSCalendar currentCalendar]
                                   components:NSDayCalendarUnit | NSMonthCalendarUnit | NSYearCalendarUnit
                                   fromDate:entry.publish_date];
            [output appendFormat:@"%02d/%02d/%02d - %@ %@ %@\n",
             c.month,
             c.day,
             c.year,
             entry.data.gesture.title,
             @"vs",
             entry.data.opposing_gesture.title];
        }
        self.activityTextView.text = output;
    };
    
    // this is an example of a batch request using FBRequestConnection; we accomplish this by adding
    // two request objects to the connection, and then calling start; note that each request handles its
    // own response, despite the fact that the SDK is serializing them into a single request to the server
    FBRequestConnection *connection = [[FBRequestConnection alloc] init];
    [connection addRequest:playActivity
         completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
             handleBlock(result);
         }];
    // start the actual request
    [connection start];    
}

- (IBAction)clickInviteFriends:(id)sender {
    // if there is a selected user, seed the dialog with that user
    NSDictionary *parameters = self.fbidSelection ? @{@"to":self.fbidSelection} : nil;
    [FBWebDialogs presentRequestsDialogModallyWithSession:nil
                                                  message:@"Please come play RPS with me!"
                                                    title:@"Invite a Friend"
                                               parameters:parameters
                                                  handler:^(FBWebDialogResult result, NSURL *resultURL, NSError *error) {
                                                      if (result == FBWebDialogResultDialogCompleted) {
                                                          NSLog(@"Web dialog complete: %@", resultURL);
                                                      } else {
                                                          NSLog(@"Web dialog not complete, error: %@", error.description);
                                                      }
                                                  }
                                              friendCache:self.friendCache];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    switch (buttonIndex) {
        case 0: // do nothing
            [self.navigationController popToRootViewControllerAnimated:YES];
            break;
        case 1: { // log in
            // we will update the view *once* upon successful login
            __block RPSFriendsViewController *me = self;
            [FBSession openActiveSessionWithReadPermissions:nil
                                               allowLoginUI:YES
                                          completionHandler:^(FBSession *session, FBSessionState status, NSError *error) {
                                              if (me) {
                                                  if (session.isOpen) {
                                                      [me refreshView];
                                                  } else {
                                                      [me.navigationController popToRootViewControllerAnimated:YES];
                                                  }
                                                  me = nil;
                                              }
                                          }];
            
            break;
        }
    }
}

@end
