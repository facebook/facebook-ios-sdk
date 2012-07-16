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
#import <FacebookSDK/FacebookSDK.h>

@interface HFViewController () <FBMyDataDelegate>

@property (strong, nonatomic) IBOutlet FBProfilePictureView *profilePic;
@property (strong, nonatomic) UIBarButtonItem *buttonLoginLogout;
@property (strong, nonatomic) IBOutlet UIButton *buttonPostStatus;
@property (strong, nonatomic) IBOutlet UIButton *buttonPostPhoto;
@property (strong, nonatomic) IBOutlet UIButton *buttonPickFriends;
@property (strong, nonatomic) IBOutlet UILabel *labelFirstName;
@property (strong, nonatomic) FBFriendPickerViewController *friendPickerController;
@property (strong, nonatomic) FBMyData *myData;
@property (strong, nonatomic) NSArray *lastFriendsSelection;

- (IBAction)postStatusUpdateClick:(UIButton *)sender;
- (IBAction)postPhotoClick:(UIButton *)sender;
- (IBAction)pickFriendsClick:(UIButton *)sender;

- (void)showAlert:(NSString *)message
           result:(id)result
            error:(NSError *)error;


@end

@implementation HFViewController

@synthesize buttonLoginLogout = _buttonLoginLogout;
@synthesize buttonPostStatus = _buttonPostStatus;
@synthesize buttonPostPhoto = _buttonPostPhoto;
@synthesize buttonPickFriends = _buttonPickFriends;
@synthesize friendPickerController = _friendPickerController;
@synthesize labelFirstName = _labelFirstName;
@synthesize profilePic = _profilePic;
@synthesize myData = _myData;
@synthesize lastFriendsSelection = _lastFriendsSelection;

- (void)viewDidLoad {    
    [super viewDidLoad];
    
    // setup nav login/logout button
    self.buttonLoginLogout = [[UIBarButtonItem alloc] initWithTitle:@"Log In" 
                                                              style:UIBarButtonItemStyleBordered 
                                                             target:self 
                                                             action:@selector(performLoginLogout:)];
    self.navigationItem.rightBarButtonItem = self.buttonLoginLogout;
    
    // create FBMyData object to handle our simple Facebook interactions
    self.myData = [[FBMyData alloc] init];
    self.myData.delegate = self;
}

- (void)viewDidUnload {
    self.buttonPickFriends = nil;
    self.buttonPostPhoto = nil;
    self.buttonPostStatus = nil;
    self.labelFirstName = nil;
    self.profilePic = nil;
    self.myData = nil;
    self.lastFriendsSelection = nil;
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

// FBSample logic
// Handler for login/logout button click, logs sessions in or out
- (void)performLoginLogout:(id)sender {
    
    // this button's job is to flip-flop the session from valid to invalid
    if (FBSession.activeSession.isOpen) {
        [self.myData handleLogoutPressed];
    } else {
        [self.myData handleLoginPressed];
    } 
}

- (void)myDataHasLoggedInUser:(FBMyData *)myData {
    // first get the buttons set for login mode
    self.buttonPostPhoto.enabled = YES;
    self.buttonPostStatus.enabled = YES;
    self.buttonPickFriends.enabled = YES;
    self.buttonLoginLogout.title = @"Log Out";
}

- (void)myDataFetched:(FBMyData *)myData
             property:(FBMyDataProperty)property {
    if (property == FBMyDataPropertyMe) {
        // here we use helper properties of FBGraphUser to dot-through to first_name and
        // id properties of the json response from the server; alternatively we could use
        // NSDictionary methods such as objectForKey to get values from the my json object
        self.labelFirstName.text = [NSString stringWithFormat:@"Hi %@!", self.myData.me.first_name];
        // setting the userID property of the FBProfilePictureView instance
        // causes the control to fetch and display the profile picture for the user
        self.profilePic.profileID = self.myData.me.id;
    }
}
 
- (void)myDataHasLoggedOutUser:(FBMyData *)myData {
    self.buttonPostPhoto.enabled = NO;
    self.buttonPostStatus.enabled = NO;
    self.buttonPickFriends.enabled = NO;
    self.buttonLoginLogout.title = @"Log In";
    
    self.profilePic.profileID = nil;            
    self.labelFirstName.text = nil;
}

// Post Status Update button handler
- (IBAction)postStatusUpdateClick:(UIButton *)sender {

    // Post a status update to the user's feed using the FBMyData helper method
    
    NSString *message = [NSString stringWithFormat:@"Updating %@'s status at %@", 
                         self.myData.me.first_name, [NSDate date]];

    [self.myData postStatusUpdate:message
                            place:self.lastFriendsSelection ? @"141887372509674" : nil // nil if no friends to tag
                             tags:self.lastFriendsSelection                            // nil unless the user has selected friends 
                completionHandler:^(FBMyData *myData, id result, NSError *error) {
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
    
    // and fire it off using the postPhoto helper of FBMyData
    [self.myData postPhoto:img
                      name:@"My Photo!"
         completionHandler:^(FBMyData *myData, id result, NSError *error) {
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
        self.lastFriendsSelection = nil;
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
        
        // if the user ever selects friends, we remember them in order to use them
        // for tags in the status post
        self.lastFriendsSelection = self.friendPickerController.selection;
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
