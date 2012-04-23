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

@property (strong, nonatomic) IBOutlet UITextField *friendFilter;
@property (strong, nonatomic) IBOutlet UIView *friendPicker;
@property (strong, nonatomic) IBOutlet UITextView *friendResults;
@property (strong, nonatomic) IBOutlet FBFriendPickerViewController *friendPickerController;
@property (strong, nonatomic) IBOutlet UIButton *logoutButton;

- (void)sessionChanged;
- (IBAction)logoutClicked;
- (IBAction)filterChanged:(id)sender;

@end

@implementation FPViewController

@synthesize friendFilter = _friendFilterTe;
@synthesize friendPicker = _friendPicker;
@synthesize friendPickerController = _friendPickerController;
@synthesize friendResults = _friendResultText;
@synthesize logoutButton = _logoutButton;

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.friendPickerController.delegate = self;
    [self sessionChanged];
}

- (void)sessionChanged
{
    FPAppDelegate *appDelegate = [UIApplication sharedApplication].delegate;
    if (appDelegate.session.isValid) {
        self.friendPickerController.session = appDelegate.session;
        [self.friendPickerController start];
    } else {
        [appDelegate.session loginWithCompletionHandler:
         ^(FBSession *session, FBSessionState state, NSError *error) {
             switch (state) {
                 case FBSessionStateLoggedIn:
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
                         [self logoutClicked];
                     }
                     break;
                 default:
                     break;
             }
         }];
    }
}

- (IBAction)logoutClicked
{
    FPAppDelegate *appDelegate = [UIApplication sharedApplication].delegate;
    [appDelegate logoutAndGetNewSession];
    [self sessionChanged];
}

- (IBAction)filterChanged:(id)sender
{
    [self.friendPickerController updateView];
}

#pragma mark - FBFriendPickerDelegate implementation

- (void)friendPickerViewControllerSelectionDidChange:
(FBFriendPickerViewController *)friendPicker
{
    if ([self.friendFilter isFirstResponder]) {
        [self.friendFilter resignFirstResponder];
    }

    NSMutableString *text = [[NSMutableString alloc] init];

    for (id<FBGraphUser> user in self.friendPickerController.selection) {
        if ([text length]) {
            [text appendString:@", "];
        }
        [text appendString:user.name];
    }

    self.friendResults.text = text;
}

- (BOOL)friendPickerViewController:(FBFriendPickerViewController *)friendPicker
                 shouldIncludeUser:(id <FBGraphUser>)user
{
    if ([self.friendFilter.text length]) {
        NSRange range = [user.name rangeOfString:self.friendFilter.text
                                           options:NSCaseInsensitiveSearch];
        return (range.location != NSNotFound);
    } else {
        return YES;
    }
}

@end
