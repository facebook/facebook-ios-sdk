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

#import "MPViewController.h"

#import "MPAppDelegate.h"
#import <FBiOSSDK/FacebookSDK.h>

@interface MPViewController ()

@property (strong, nonatomic) IBOutlet FBProfilePictureView *profilePic;
@property (strong, nonatomic) UIBarButtonItem *buttonLoginLogout;
@property (strong, nonatomic) IBOutlet UIButton *buttonPostStatus;
@property (strong, nonatomic) IBOutlet UIButton *buttonPostPhoto;
@property (strong, nonatomic) IBOutlet UIButton *buttonPickFriends;
@property (strong, nonatomic) IBOutlet UILabel *labelFirstName;
@property (strong, nonatomic) FBFriendPickerViewController *friendPickerController;
@property (strong, nonatomic) NSDictionary<FBGraphUser> *loggedInUser;
@property (strong, nonatomic) FBRequestConnection *requestConnection;

- (void)performLoginLogout:(id)sender;

- (IBAction)postStatusUpdateClick:(UIButton *)sender;
- (IBAction)postPhotoClick:(UIButton *)sender;
- (IBAction)pickFriendsClick:(UIButton *)sender;

- (void)updateForSessionChange;
- (void)showAlert:(NSString *)message
           result:(id)result
            error:(NSError *)error;


@end

@implementation MPViewController

@synthesize buttonLoginLogout = _buttonLoginLogout;
@synthesize buttonPostStatus = _buttonPostStatus;
@synthesize buttonPostPhoto = _buttonPostPhoto;
@synthesize buttonPickFriends = _buttonPickFriends;
@synthesize friendPickerController = _friendPickerController;
@synthesize labelFirstName = _labelFirstName;
@synthesize loggedInUser = _loggedInUser;
@synthesize profilePic = _profilePic;
@synthesize requestConnection = _requestConnection;

- (void)viewDidLoad {    
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    self.buttonLoginLogout = [[UIBarButtonItem alloc] 
                              initWithTitle:@"Login" 
                              style:UIBarButtonItemStyleBordered 
                              target:self 
                              action:@selector(performLoginLogout:)];
    self.navigationItem.rightBarButtonItem = self.buttonLoginLogout;
        
    // FBSample logic
    // Bootstrap call to updateForSessionChange gets a fresh new session object
    [self updateForSessionChange];
    
}

- (void)viewDidUnload {
    self.buttonLoginLogout = nil;
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

// FBSample logic
// Main helper method to react to session changes, including initial opening of
// the active session, if it happens to be waiting with a cached token
- (void)updateForSessionChange {
    if (FBSession.activeSession.isOpen) {        
        // valid account UI
        
        // Once logged in, get "my" information, using a request* static helper,
        // and the FBRequestConnection class; a call to the instance startWithCompletionHelper
        // method returns an FBRequestConnection object, which can be used to cancel the request
        // if needed
        FBRequest *me = [FBRequest requestForMeWithSession:FBSession.activeSession];
        FBRequestConnection *newConnection = [me startWithCompletionHandler: ^(FBRequestConnection *connection,
                                                                               // using typed FBGraphUser protocol,
                                                                               // because we expect a person-shaped
                                                                               // response
                                                                               NSDictionary<FBGraphUser> *my, 
                                                                               NSError *error) {
            // Request completed...
            if (connection != self.requestConnection) {
                // not the completion we were waiting for...
                return;
            }
            
            self.requestConnection = nil;
            NSString *text = nil, *fbid = nil;
            if (!error) {
                // here we use helper properties of FBGraphUser to dot-through to first_name and
                // id properties of the json response from the server; alternatively we could use
                // NSDictionary methods such as objectForKey to get values from the my json object
                text = [NSString stringWithFormat:@"Hello %@!", my.first_name];
                fbid = my.id;
                self.loggedInUser = my;
            } else {
                text = error.localizedDescription;
                fbid = nil;   // default profile pic
            }  
            
            // setting the userID property of the FBProfilePictureView instance
            // causes the control to fetch and display the profile picture for the user
            self.profilePic.userID = fbid;            
            self.labelFirstName.text = text;
        }];
        
        // if there's an outstanding connection, just cancel, which causes
        // the connection to complete immediately with an error
        [self.requestConnection cancel];
        
        // keep track of the connection that we just created
        self.requestConnection = newConnection;
        
        // if we have an open session, then our login-logout button should be for logging out, and out
        // "action" buttons are operable.
        self.buttonLoginLogout.title = @"Logout";  
        self.buttonPostPhoto.enabled = YES;
        self.buttonPostStatus.enabled = YES;
        self.buttonPickFriends.enabled = YES;
    } else {
        
        // if we have a closed session then our login-logout button should be for log-in
        self.buttonLoginLogout.title = @"Login"; 
        self.labelFirstName.text = @"<Press Login>";
        self.profilePic.userID = nil;   // default profile pic; note if you are having trouble getting
                                        // the default profile pic to display in your own application,
                                        // it may be that you need to drag the FBiOSSDKResources.bundle 
                                        // into your project
        
        // our "action" buttons only make sense when we're logged in.
        self.buttonPostPhoto.enabled = NO;
        self.buttonPostStatus.enabled = NO;
        self.buttonPickFriends.enabled = NO;
        
        // because we use this method to bootstrap button setup, we may find that we also need
        // to open a session that is ready and waiting with a cached token
        if (FBSession.activeSession.state == FBSessionStateCreatedTokenLoaded) {
            [FBSession.activeSession openWithCompletionHandler:^(FBSession *session, 
                                                                 FBSessionState status, 
                                                                 NSError *error) {
                [self updateForSessionChange];
            }];
        }
    }
}


// FBSample logic
// Handler for login/logout button click, logs sessions in or out
- (void)performLoginLogout:(id)sender {
    
    // this button's job is to flip-flop the session from valid to invalid
    if (FBSession.activeSession.isOpen) {
        // if a user logs out explicitly, we call closeAndClear* which, like close, closes the
        // in memory FBSession object, and additionally clears any persisted token state and cache
        // for the user; typically an application would only call this method in response to a direct
        // user action that the user would associate with logging-out from an application
        [FBSession.activeSession closeAndClearTokenInformation];
    } else {
        // in order to get the FBSession object up and running, with the necessary permissions.  A more
        // sophisticated version of this app would create the session without the extended permissions,
        // wait until an action that required the extended permissions was needed, and then call 
        // reauthorizeWithPermissions on the existing session.
        [FBSession sessionOpenWithPermissions:[NSArray arrayWithObject:@"status_update"]
                            completionHandler:^(FBSession *session, 
                                                FBSessionState status, 
                                                NSError *error) {
            [self updateForSessionChange];
        }];
    } 
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
    [FBRequest startWithSession:[FBSession activeSession]
                      graphPath:@"me/feed"
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
    FBRequest *photoUploadRequest = [FBRequest requestForUploadPhoto:img session:FBSession.activeSession];
    
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
