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

#import "BOGSecondViewController.h"
#import "BOGAppDelegate.h"
#import "OGProtocols.h"

@interface BOGSecondViewController () <FBFriendPickerDelegate>

- (void)updateActivityForID:(NSString *)fbid;

@end

@implementation BOGSecondViewController

@synthesize activityTextView = _activityTextView;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.title = NSLocalizedString(@"Rock w/Friends", @"Rock w/Friends");
        self.tabBarItem.image = [UIImage imageNamed:@"first"];
        self.fieldsForRequest = [NSSet setWithObject:@"installed"];
        self.allowsMultipleSelection = NO;
        self.delegate = self;
    }
    return self;
}

#pragma mark - View lifecycle

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if (FBSession.activeSession.isOpen) {
        [self loadData];
        self.inviteButton.enabled = YES;
    } else {
        self.inviteButton.enabled = NO;
        
        // display the message that we have
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Social Features Disabled"
                                                        message:@"There is no open session with Facebook. Use the Facebook Settings "
                                                                @"tab to log in and use the social features of the application."
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
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
    if (friendPicker.selection.count) {
        self.activityTextView.text = @"";
        [self updateActivityForID:[[friendPicker.selection objectAtIndex:0] id]];
    }
}

- (BOOL)friendPickerViewController:(FBFriendPickerViewController *)friendPicker
                 shouldIncludeUser:(id <FBGraphUser>)user {
    return [[user objectForKey:@"installed"] boolValue];     
}

#pragma mark - private methods

// FBSample logic
// This is the workhorse method of this view. It updates the textView with the activity of a given user. It 
// accomplishes this by fetching the "or" and "and" actions for the selected user.
- (void)updateActivityForID:(NSString *)fbid {
    
    // create a request for the "or" activity
    FBRequest *orActivity = [FBRequest requestForGraphPath:[NSString stringWithFormat:@"%@/fb_sample_boolean_og:or", fbid]];
    [orActivity.parameters setObject:@"U" forKey:@"date_format"];
    
    // create a request for the "and" activity
    FBRequest *andActivity = [FBRequest requestForGraphPath:[NSString stringWithFormat:@"%@/fb_sample_boolean_og:and", fbid]];
    [andActivity.parameters setObject:@"U" forKey:@"date_format"];
    
    // because we have two requests in one batch, we will use this array to gather the aggrigated acticity
    NSMutableArray *activity = [NSMutableArray array];
    
    __block int numCalls = 2;
    // this block is the one that does the real handling work for the requests
    void (^handleBatch)(NSString*,id) = ^(NSString* verb, id<BOGGraphBooleanActionList> result) {

        // If we have gotten all the results we expect, display them.
        BOOL shouldDisplay = (--numCalls == 0);
        
        // if we have results here, then we loop through each entry, and add it to our activity array
        if (result) {
            for (id<BOGGraphPublishedBooleanAction> entry in result.data) {
                // we also translate the date into something useful for sorting and displaying
                entry.publish_date = [NSDate dateWithTimeIntervalSince1970:entry.publish_time.intValue];
                // and we remember the verb that we just fetched for (e.g. "and", "or")
                entry.verb = verb;
                [activity addObject:entry];
            }
        }
        
        if (shouldDisplay) {
            
            // sort the array by date
            [activity sortUsingComparator:^NSComparisonResult(id<BOGGraphPublishedBooleanAction> obj1, 
                                                              id<BOGGraphPublishedBooleanAction> obj2) {
                if (obj1.publish_date && obj2.publish_date) {
                    return [obj2.publish_date compare:obj1.publish_date];
                }
                return NSOrderedSame;
            }];
            
            // build the string that we display in the textView, with one line per activity that we recieved
            NSMutableString *output = [NSMutableString stringWithCapacity:activity.count];
            for (id<BOGGraphPublishedBooleanAction> entry in activity) {
                NSDateComponents *c = [[NSCalendar currentCalendar]
                                       components:NSDayCalendarUnit | NSMonthCalendarUnit | NSYearCalendarUnit
                                       fromDate:entry.publish_date];
                [output appendFormat:@"%02d/%02d/%02d - %@ %@ %@ = %@\n", 
                 c.month,
                 c.day,
                 c.year,
                 entry.data.truthvalue.title,
                 entry.verb,                 
                 entry.data.anothertruthvalue.title,                 
                 entry.data.result.boolValue ? @"True" : @"False"];
            }
            self.activityTextView.text = output;
        }
    };
    
    // this is an example of a batch request using FBRequestConnection; we accomplish this by adding
    // two request objects to the connection, and then calling start; note that each request handles its
    // own response, despite the fact that the SDK is serializing them into a single request to the server
    FBRequestConnection *connection = [[FBRequestConnection alloc] init];
    [connection addRequest:orActivity
         completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
             handleBatch(@"OR", result);
         }];
    [connection addRequest:andActivity
         completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
             handleBatch(@"AND", result);
         }];
    
    // start the actual request
    [connection start];    
}

- (IBAction)clickInviteFriends:(id)sender {
    [FBWebDialogs presentRequestsDialogModallyWithSession:nil
                                                  message:@"Please come rock the logic with me!"
                                                    title:@"Invite a Friend"
                                               parameters:nil
                                                  handler:nil];
}

@end
