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

#import "HFViewController.h"

#import "HFAppDelegate.h"
#import <FBiOSSDK/FacebookSDK.h>

@interface HFViewController () <FBLoginViewDelegate>

@property (strong, nonatomic) IBOutlet FBProfilePictureView *profilePic;
@property (strong, nonatomic) IBOutlet UIButton *buttonPostStatus;
@property (strong, nonatomic) IBOutlet UIButton *buttonPostPhoto;
@property (strong, nonatomic) IBOutlet UIButton *buttonPickFriends;
@property (strong, nonatomic) IBOutlet UILabel *labelFirstName;
@property (strong, nonatomic) FBFriendPickerViewController *friendPickerController;
@property (strong, nonatomic) id<FBGraphUser> loggedInUser;

- (IBAction)postStatusUpdateClick:(UIButton *)sender;
- (IBAction)postPhotoClick:(UIButton *)sender;
- (IBAction)pickFriendsClick:(UIButton *)sender;

- (void)showAlert:(NSString *)message
           result:(id)result
            error:(NSError *)error;


@end

@implementation HFViewController

@synthesize buttonPostStatus = _buttonPostStatus;
@synthesize buttonPostPhoto = _buttonPostPhoto;
@synthesize buttonPickFriends = _buttonPickFriends;
@synthesize friendPickerController = _friendPickerController;
@synthesize labelFirstName = _labelFirstName;
@synthesize loggedInUser = _loggedInUser;
@synthesize profilePic = _profilePic;

- (void)viewDidLoad {    
    [super viewDidLoad];
    
    // Create Login View so that the app will be granted "status_update" permission.
    FBLoginView *loginview = 
        [[FBLoginView alloc] initWithPermissions:[NSArray arrayWithObject:@"status_update"]];
    
    loginview.frame = CGRectOffset(loginview.frame, 5, 5);
    loginview.delegate = self;
    
    [self.view addSubview:loginview];
}

- (void)viewDidUnload {
    self.buttonPickFriends = nil;
    self.buttonPostPhoto = nil;
    self.buttonPostStatus = nil;
    self.labelFirstName = nil;
    self.loggedInUser = nil;
    self.profilePic = nil;
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

- (void)loginViewShowingLoggedInUser:(FBLoginView *)loginView {
    // first get the buttons set for login mode
    self.buttonPostPhoto.enabled = YES;
    self.buttonPostStatus.enabled = YES;
    self.buttonPickFriends.enabled = YES;
}

- (void)loginViewFetchedUserInfo:(FBLoginView *)loginView
                            user:(id<FBGraphUser>)user {
    // here we use helper properties of FBGraphUser to dot-through to first_name and
    // id properties of the json response from the server; alternatively we could use
    // NSDictionary methods such as objectForKey to get values from the my json object
    self.labelFirstName.text = [NSString stringWithFormat:@"Hello %@!", user.first_name];
    // setting the userID property of the FBProfilePictureView instance
    // causes the control to fetch and display the profile picture for the user
    self.profilePic.userID = user.id;
    self.loggedInUser = user;
}
 
- (void)loginViewShowingLoggedOutUser:(FBLoginView *)loginView {
    self.buttonPostPhoto.enabled = NO;
    self.buttonPostStatus.enabled = NO;
    self.buttonPickFriends.enabled = NO;
    
    self.profilePic.userID = nil;            
    self.labelFirstName.text = nil;
}

// Post Status Update button handler
- (IBAction)postStatusUpdateClick:(UIButton *)sender {
    
    // Post a status update to the user's feedm via the Graph API, and display an alert view 
    // with the results or an error.

    NSString *message = [NSString stringWithFormat:@"Updating %@'s status at %@", 
                         self.loggedInUser.first_name, [NSDate date]];
    NSDictionary *params = [NSDictionary dictionaryWithObject:message forKey:@"message"];
    
    // use the "startWith" helper static on FBRequest to both create and start a request, with
    // a specified completion handler.
    [FBRequest startWithGraphPath:@"me/feed"
                     parameters:params
                     HTTPMethod:@"POST"
              completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
                  
                  [self showAlert:message result:result error:error];
                  self.buttonPostStatus.enabled = YES;
              }];
        
    self.buttonPostStatus.enabled = NO;       
}

// Post Photo button handler
- (IBAction)postPhotoClick:(UIButton *)sender {
    
    // Just use the icon image from the application itself.  A real app would have a more 
    // useful way to get an image.
    UIImage *img = [UIImage imageNamed:@"Icon-72@2x.png"];
    
    // Build the request for uploading the photo
    FBRequest *photoUploadRequest = [FBRequest requestForUploadPhoto:img];
    
    // Then fire it off.
    [photoUploadRequest startWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {        
        [self showAlert:@"Photo Post" result:result error:error];
        self.buttonPostPhoto.enabled = YES;
    }];
    
    self.buttonPostPhoto.enabled = NO;
}

// Pick Friends button handler
- (IBAction)pickFriendsClick:(UIButton *)sender {
    // Create friend picker, and get data loaded into it.
    FBFriendPickerViewController *friendPicker = [[FBFriendPickerViewController alloc] init];
    self.friendPickerController = friendPicker;
    
    [friendPicker loadData];
    
    // Create navigation controller related UI for the friend picker.
    friendPicker.navigationItem.title = @"Pick Friends";
    
    friendPicker.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] 
                                                      initWithTitle:@"Done" 
                                                      style:UIBarButtonItemStyleBordered 
                                                      target:self 
                                                      action:@selector(friendPickerDoneButtonWasPressed:)];
    friendPicker.navigationItem.hidesBackButton = YES;
    
    // Make current.
    [self.navigationController pushViewController:friendPicker animated:YES];
}


// Handler for when friend picker is dismissed
- (void)friendPickerDoneButtonWasPressed:(id)sender {

    [self.navigationController popViewControllerAnimated:YES];

    NSString *message;
    
    if (self.friendPickerController.selection.count == 0) {
        message = @"<No Friends Selected>";
    } else {
    
        NSMutableString *text = [[NSMutableString alloc] init];
        
        // we pick up the users from the selection, and create a string that we use to update the text view
        // at the bottom of the display; note that self.selection is a property inherited from our base class
        for (id<FBGraphUser> user in self.friendPickerController.selection) {
            if ([text length]) {
                [text appendString:@", "];
            }
            [text appendString:user.name];
        }
        message = text;
    }
    
    [[[UIAlertView alloc] initWithTitle:@"You Picked:" 
                                message:message 
                               delegate:nil 
                      cancelButtonTitle:@"OK" 
                      otherButtonTitles:nil] 
     show];
}

// UIAlertView helper for post buttons
- (void)showAlert:(NSString *)message
           result:(id)result
            error:(NSError *)error {

    NSString *alertMsg;
    NSString *alertTitle;
    if (error) {
        alertMsg = error.localizedDescription;
        alertTitle = @"Error";
    } else {
        NSDictionary *resultDict = (NSDictionary *)result;
        alertMsg = [NSString stringWithFormat:@"Successfully posted '%@'.\nPost ID: %@", 
                    message, [resultDict valueForKey:@"id"]];
        alertTitle = @"Success";
    }

    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:alertTitle
                                                        message:alertMsg
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
    [alertView show];
}

@end
