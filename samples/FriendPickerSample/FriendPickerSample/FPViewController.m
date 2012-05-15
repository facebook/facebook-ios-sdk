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

- (void)sessionChanged;

@end

@implementation FPViewController

@synthesize selectedFriendsView = _friendResultText;

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self sessionChanged];
}

- (void)sessionChanged
{
    FPAppDelegate *appDelegate = [UIApplication sharedApplication].delegate;
    if (appDelegate.session.isValid) {
        self.session = appDelegate.session;
        [self loadData];
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
                     }
                     break;
                 default:
                     break;
             }
         }];
    }
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
