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

// FBSample logic
// Here we define an outlet for a FBProfilePictureView
@property (strong, nonatomic) IBOutlet FBProfilePictureView *profilePic;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *buttonLoginLogout;
@property (strong, nonatomic) IBOutlet UILabel *labelFirstName;
@property (strong, nonatomic) FBRequestConnection *requestConnection;

- (IBAction)performLoginLogout:(id)sender;

- (void)updateForSessionChange;

@end

@implementation MPViewController

@synthesize buttonLoginLogout = _buttonLoginLogout;
@synthesize labelFirstName = _labelFirstName;
@synthesize profilePic = _profilePic;
@synthesize requestConnection = _requestConnection;

- (void)viewDidLoad {    
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
        
    // FBSample logic
    // Bootstrap call to updateForSessionChange gets a fresh new session object
    [self updateForSessionChange];
    
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
                text = [NSString stringWithFormat:@"Yo %@, make this app yours!", my.first_name];
                fbid = my.id;
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
        
        // if we have an open session, then our login-logout button should be for loging out
        self.buttonLoginLogout.title = @"Logout";  
        
    } else {
        
        // if we have a closed session then our login-logout button should be for log-in
        self.buttonLoginLogout.title = @"Login"; 
        self.labelFirstName.text = @"<Press Login>";
        self.profilePic.userID = nil;   // default profile pic; note if you are having trouble getting
                                        // the default profile pic to display in your own application,
                                        // it may be that you need to drag the FBiOSSDKResources.bundle 
                                        // into your project
        
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
- (IBAction)performLoginLogout:(id)sender {
    
    // this button's job is to flip-flop the session from valid to invalid
    if (FBSession.activeSession.isOpen) {
        // if a user logs out explicitly, we call closeAndClear* which, like close, closes the
        // in memory FBSession object, and additionally clears any persisted token state and cache
        // for the user; typically an application would only call this method in response to a direct
        // user action that the user would associate with logging-out from an application
        [FBSession.activeSession closeAndClearTokenInformation];
    } else {
        // in order to get the FBSession object up and running
        [FBSession sessionOpenWithPermissions:nil
                            completionHandler:^(FBSession *session, 
                                                FBSessionState status, 
                                                NSError *error) {
            [self updateForSessionChange];
        }];
    } 
}

- (void)viewDidUnload {
    self.buttonLoginLogout = nil;
    self.labelFirstName = nil;
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

@end
