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
@property (strong, nonatomic) IBOutlet UIBarButtonItem *buttonLoginLogout;
@property (strong, nonatomic) IBOutlet UILabel *labelFirstName;
@property (strong, nonatomic) FBRequestConnection *requestConnection;

- (IBAction)performLoginLogout:(id)sender;

- (void)updateForSessionChange;

@end

@implementation MPViewController

@synthesize buttonLoginLogout;
@synthesize labelFirstName;
@synthesize profilePic;
@synthesize requestConnection = _requestConnection;

- (void)viewDidLoad {    
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
        
    // FBSample logic
    // bootstrap call to updateForSessionChange gets a fresh new session object
    [self updateForSessionChange];
    
}

// FBSample logic
// main helper method to react to session changes, including creation of session
// object when one has gone invalid, or at init time
- (void)updateForSessionChange {
    // get the app delegate
    MPAppDelegate *appDelegate = [[UIApplication sharedApplication]delegate];
    if (appDelegate.session.isOpen) {        
        // valid account UI
        
        // Once logged in, get "my" information.
        FBRequest *me = [FBRequest requestForMeWithSession:appDelegate.session];
        FBRequestConnection *newConnection = 
        [me startWithCompletionHandler: ^(FBRequestConnection *connection, 
                                          NSDictionary<FBGraphUser> *my, // expecting a person here
                                          NSError *error) {
            // Request completed...
              if (connection != self.requestConnection) {
                  // not the completion we were waiting for...
                  return;
              }
                
              self.requestConnection = nil;
              NSString *text = nil, *fbid = nil;
              if (!error) {
                  text = [NSString stringWithFormat:@"Yo %@, make this app yours!", my.first_name];
                  fbid = my.id;
              } else {
                  text = error.localizedDescription;
                  fbid = nil;   // default profile pic
              }  
                
              self.labelFirstName.text = text;
              profilePic.userID = fbid;
          }];
        
        // If there's an outstanding connection, just cancel
        [self.requestConnection cancel];
        self.requestConnection = newConnection;
        
        buttonLoginLogout.title = @"Logout";  
        
    } else {
        
        // invalid account UI, or just logged out.
        buttonLoginLogout.title = @"Login"; 
        labelFirstName.text = @"<Press Login>";
        profilePic.userID = nil; // default profile pic
        
        // create a fresh session object in case of subsequent login
        appDelegate.session = [[FBSession alloc] init]; 
        if (appDelegate.session.state == FBSessionStateCreatedTokenLoaded) {
            // even though we had a cached token, we need to login to make the session usable
            [appDelegate.session openWithCompletionHandler:^(FBSession *session, 
                                                             FBSessionState status, 
                                                             NSError *error) {
                [self updateForSessionChange];
            }];
        }
    }
}


// FBSample logic
// handler for button click, logs sessions in or out
- (IBAction)performLoginLogout:(id)sender {
    // get the app delegate
    MPAppDelegate *appDelegate = [[UIApplication sharedApplication]delegate];
    
    // this button's job is to flip-flop the session from valid to invalid
    if (appDelegate.session.isOpen) {
        // if a user logs out explicitly, we logout the session, which deletes any cached token 
        [appDelegate.session closeAndClearTokenInformation];
    } else {
        // in order to get the FBSession object up and running
        [appDelegate.session openWithCompletionHandler:^(FBSession *session, 
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
