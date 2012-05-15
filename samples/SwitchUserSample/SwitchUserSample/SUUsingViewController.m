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

#import "SUUsingViewController.h"
#import "SUAppDelegate.h"
#import <FBiOSSDK/FacebookSDK.h>

@interface SUUsingViewController ()

//@property (strong, nonatomic) IBOutlet UITableView *usersTableView;

@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *birthdayLabel;
@property (weak, nonatomic) IBOutlet FBProfilePictureView *picView;
@property (strong, nonatomic) FBRequestConnection *requestConnection;

@end

@implementation SUUsingViewController

@synthesize nameLabel;
@synthesize birthdayLabel;
@synthesize picView;
@synthesize requestConnection = _requestConnection;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.title = NSLocalizedString(@"Using", @"Using");
        self.tabBarItem.image = [UIImage imageNamed:@"first"];
    }
    return self;
}

- (void)updateControls {
    SUAppDelegate *appDelegate = (SUAppDelegate *)[[UIApplication sharedApplication]delegate];
    SUUserManager *userManager = appDelegate.userManager;
    
    if (userManager.currentUserSlot != -1 &&
        userManager.currentSession.isValid) {
        // There could be a delay while we retrieve user profile. Hide controls until data is there.
        self.nameLabel.hidden = YES;
        self.picView.hidden = YES;
        self.birthdayLabel.hidden = YES;

        FBRequest *me = [FBRequest requestForMeWithSession:userManager.currentSession];
        FBRequestConnection *requestConnection = [[FBRequestConnection alloc] init];
        [requestConnection addRequest:me completionHandler:^(FBRequestConnection *connection, 
                                                             NSDictionary<FBGraphUser> *user,
                                                             NSError *error) {
            if (connection != self.requestConnection) {
                return;
            }
            self.requestConnection = nil;

            if (error) {
                NSLog(@"Couldn't get info : %@", error.localizedDescription);
                return;
            }

            self.nameLabel.text = [NSString stringWithFormat:@"Hello, %@!", user.first_name];
            self.picView.userID = user.id;
            if (user.birthday.length > 0) {
                self.birthdayLabel.text = [NSString stringWithFormat:@"Your birthday is: %@", user.birthday];            
            } else {
                self.birthdayLabel.text = @"Your birthday isn't set.";
            }

            self.nameLabel.hidden = NO;
            self.picView.hidden = NO;
            self.birthdayLabel.hidden = NO;
        }];

        [self.requestConnection cancel];
        self.requestConnection = requestConnection;

        [requestConnection start];        
    } else {
        self.nameLabel.text = @"No active user. Go to Settings tab to log in!";
        self.nameLabel.hidden = NO;
        self.picView.hidden = YES;
        self.birthdayLabel.hidden = YES;
    }
}

- (void)userDidChange:(NSNotification*)notification {
    [self updateControls];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self updateControls];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.picView.pictureSize = FBProfilePictureSizeLarge;
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(userDidChange:)
                                                 name:@"SUUserManagerUserChanged" object:nil];

    [self updateControls];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
    self.nameLabel = nil;
    self.birthdayLabel = nil;
    self.picView = nil;

    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:@"SUUserManagerUserChanged" object:nil];

}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
    } else {
        return YES;
    }
}

@end
