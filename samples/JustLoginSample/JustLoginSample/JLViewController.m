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

#import "JLViewController.h"
#import "JLAppDelegate.h"

@interface JLViewController () 

@property (strong, nonatomic) IBOutlet UIButton *buttonLoginLogout;
@property (strong, nonatomic) IBOutlet UITextView *textNoteOrLink;

- (IBAction)buttonClickHandler:(id)sender;
- (void)updateForSessionChange;

@end

@implementation JLViewController
@synthesize textNoteOrLink;
@synthesize buttonLoginLogout;

- (void)viewDidLoad {    
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    // FBSample logic
    // This application uses a single method to handle session transitions and
    // the related changes to buttons, etc.; we call the method from here in
    //  order to bootstrap and gets a fresh new session object
    [self updateForSessionChange];
    
}

// FBSample logic
// main helper method to react to session changes, including creation of session
// object when one has gone invalid, or at init time
- (void)updateForSessionChange {
    // get the app delegate, so that we can reference the session property
    JLAppDelegate *appDelegate = [[UIApplication sharedApplication]delegate];
    if (appDelegate.session.isOpen) {        
        // valid account UI is shown whenever the session is open
        [buttonLoginLogout setTitle:@"Log out" forState:UIControlStateNormal];        
        [textNoteOrLink setText:[NSString stringWithFormat:@"https://graph.facebook.com/me/friends?access_token=%@",
                                 appDelegate.session.accessToken]];
    } else {        
        // login-needed account UI is shown whenever the session is closed
        [buttonLoginLogout setTitle:@"Log in" forState:UIControlStateNormal];        
        [textNoteOrLink setText:@"Login to create a link to fetch account data"];
        
        // create a fresh session object
        appDelegate.session = [[FBSession alloc] init];
        
        // if we don't have a cached token, a call to open here would cause UX for login to
        // occur; we don't want that to happen unless the user clicks the login button, and so
        // we check here to make sure we have a token before calling open
        if (appDelegate.session.state == FBSessionStateCreatedTokenLoaded) {
            // even though we had a cached token, we need to login to make the session usable
            [appDelegate.session openWithCompletionHandler:^(FBSession *session, 
                                                             FBSessionState status, 
                                                             NSError *error) {
                // we recurse here, in order to update buttons and labels
                [self updateForSessionChange];
            }];
        }
    }
}

// FBSample logic
// handler for button click, logs sessions in or out
- (IBAction)buttonClickHandler:(id)sender {
    // get the app delegate so that we can access the session property
    JLAppDelegate *appDelegate = [[UIApplication sharedApplication]delegate];
    
    // this button's job is to flip-flop the session from open to closed
    if (appDelegate.session.isOpen) {
        // if a user logs out explicitly, we delete any cached token information, and next
        // time they run the applicaiton they will be presented with log in UX again; most
        // users will simply close the app or switch away, without logging out; this will
        // cause the implicit cached-token login to occur on next launch of the application
        [appDelegate.session closeAndClearTokenInformation];
    } else {
        // if the session isn't open, let's open it now and present the login UX to the user
        [appDelegate.session openWithCompletionHandler:^(FBSession *session, 
                                                         FBSessionState status, 
                                                         NSError *error) {
            // and here we make sure to update our UX according to the new session state
            [self updateForSessionChange];
        }];
    } 
}

#pragma mark Template generated code

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload
{
    [self setButtonLoginLogout:nil];
    [self setTextNoteOrLink:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
    } else {
        return YES;
    }
}

#pragma mark -

@end
