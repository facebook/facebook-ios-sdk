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

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.sortBySegmentedControl.selectedSegmentIndex = 0;
    self.sortOrdering = FBFriendSortByFirstName;
    self.displayBySegmentedControl.selectedSegmentIndex = 0;
    self.displayOrdering = FBFriendDisplayByFirstName;
    
    [self sessionChanged];
}

- (void)sessionChanged
{
    FPAppDelegate *appDelegate = [UIApplication sharedApplication].delegate;
    if (appDelegate.session.isOpen) {
        self.session = appDelegate.session;
        [self loadData];
    } else {
        [appDelegate.session openWithCompletionHandler:
         ^(FBSession *session, FBSessionState state, NSError *error) {
             switch (state) {
                 case FBSessionStateOpen:
                     if (!error) {
                         [self sessionChanged];
                     } else {
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

- (IBAction)sortBySegmentedControlValueChanged:(id)sender 
{
    self.sortOrdering = ([sender selectedSegmentIndex] == 0) ? FBFriendSortByFirstName : FBFriendSortByLastName;
    [self loadData];
}

- (IBAction)displayBySegmentedControlValueChanged:(id)sender 
{
    self.displayOrdering = ([sender selectedSegmentIndex] == 0) ? FBFriendDisplayByFirstName : FBFriendDisplayByLastName;
    [self loadData];
}

#pragma mark - FBFriendPickerDelegate implementation

- (void)friendPickerViewControllerSelectionDidChange:
(FBFriendPickerViewController *)friendPicker
{
    NSMutableString *text = [[NSMutableString alloc] init];

    for (id<FBGraphUser> user in self.selection) {
        if ([text length]) {
            [text appendString:@", "];
        }
        [text appendString:user.name];
    }

    self.selectedFriendsView.text = text;
}

@end
