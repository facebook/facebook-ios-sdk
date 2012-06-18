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

#import "FPAppDelegate.h"
#import "FPViewController.h"

// FBSample logic
// We need to handle some of the UX events related to friend selection, and so we declare
// that we implement the FBFriendPickerDelegate here; the delegate lets us filter the view
// as well as handle selection events
@interface FPViewController () <FBFriendPickerDelegate>

@property (strong, nonatomic) IBOutlet UITextView *selectedFriendsView;
@property (strong, nonatomic) IBOutlet UISegmentedControl *sortBySegmentedControl;
@property (strong, nonatomic) IBOutlet UISegmentedControl *displayBySegmentedControl;

- (void)sessionChanged;
- (IBAction)sortBySegmentedControlValueChanged:(id)sender;
- (IBAction)displayBySegmentedControlValueChanged:(id)sender;

@end

@implementation FPViewController

@synthesize selectedFriendsView = _friendResultText;
@synthesize sortBySegmentedControl = _sortBySegmentedControl;
@synthesize displayBySegmentedControl = _displayBySegmentedControl;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // FBSample logic
    // We are inheriting FBFriendPickerViewController, and so in order to handle events such 
    // as selection change, we set our base class' delegate property to self
    self.delegate = self;
    
    self.sortBySegmentedControl.selectedSegmentIndex = 0;
    self.sortOrdering = FBFriendSortByFirstName;
    self.displayBySegmentedControl.selectedSegmentIndex = 0;
    self.displayOrdering = FBFriendDisplayByFirstName;
    
    
    // FBSample logic
    // We call our session-related workhorse here to update the state of the view and session
    // in order to reflect current login state. In the case of viewDidLoad, this should result
    // in the session being opened
    [self sessionChanged];
}

// FBSample logic
// This method is responsible for keeping UX and session state in sync
- (void)sessionChanged {
    // get the app delegate
    FPAppDelegate *appDelegate = [UIApplication sharedApplication].delegate;
    // if the session is open, then load the data for our view controller
    if (appDelegate.session.isOpen) {
        // setting the session property on our base class in order to 
        // enable fetching data by the base view controller
        self.session = appDelegate.session;
        
        // the view controllers in the SDK have a loadData method, which is used to update
        // the view to reflect changes to properties and other setting which may require
        // a refetch from the server
        [self loadData];
    } else {
        // if the session is closed, then we open it here, and establish a handler for state changes
        [appDelegate.session openWithCompletionHandler:^(FBSession *session,
                                                         FBSessionState state,
                                                         NSError *error) {
            switch (state) {
                case FBSessionStateOpen:
                    [self sessionChanged];
                    break;
                case FBSessionStateClosedLoginFailed:
                {
                    UIAlertView *alertView =
                    [[UIAlertView alloc] initWithTitle:@"Error"
                                               message:error.localizedDescription
                                              delegate:nil
                                     cancelButtonTitle:@"OK"
                                     otherButtonTitles:nil];
                    [alertView show];
                }
                    break;
                default:
                    break;
            }
        }];
    }
}

// FBSample logic
// In the following methods, we make changes to the base view controller state, and so we need to call
// load data in order to refetch from the server
- (IBAction)sortBySegmentedControlValueChanged:(id)sender {
    self.sortOrdering = ([sender selectedSegmentIndex] == 0) ? FBFriendSortByFirstName : FBFriendSortByLastName;
    [self loadData]; // refetch from the server
}

- (IBAction)displayBySegmentedControlValueChanged:(id)sender {
    // another property that when changes requires a refetch from the server
    // Note: the reason that setting the properties doesn't implicitly refetch is that we wanted to leave
    // network I/O in the hands of the application within reason. For example, suppose that two or three properties
    // were being set -- it would be ideal for the application to wait until all three are set before issueing a 
    // loadData call which will result in a network round-trip
    self.displayOrdering = ([sender selectedSegmentIndex] == 0) ? FBFriendDisplayByFirstName : FBFriendDisplayByLastName;
    [self loadData];
}

#pragma mark - FBFriendPickerDelegate implementation

// FBSample logic
// A delegate method for the view controller, which is called when the selection changes
- (void)friendPickerViewControllerSelectionDidChange:(FBFriendPickerViewController *)friendPicker {
    NSMutableString *text = [[NSMutableString alloc] init];

    // we pick up the users from the selection, and create a string that we use to update the text view
    // at the bottom of the display; note that self.selection is a property inherited from our base class
    for (id<FBGraphUser> user in self.selection) {
        if ([text length]) {
            [text appendString:@", "];
        }
        [text appendString:user.name];
    }

    self.selectedFriendsView.text = text;
}

@end
