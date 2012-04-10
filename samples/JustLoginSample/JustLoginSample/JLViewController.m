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

- (void)viewDidLoad
{    
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
    JLAppDelegate *appDelegate = [[UIApplication sharedApplication]delegate];
    if (appDelegate.session.isValid) {        
        // valid account UI
        [buttonLoginLogout setTitle:@"Logout" forState:UIControlStateNormal];        
        [textNoteOrLink setText:[NSString stringWithFormat:@"https://graph.facebook.com/me/friends?access_token=%@",
                                 appDelegate.session.accessToken]];
    } else {        
        // invalid account UI
        [buttonLoginLogout setTitle:@"Login" forState:UIControlStateNormal];        
        [textNoteOrLink setText:@"Login to create a link to fetch account data"];
        
        // create a fresh session object in case of subsequent login
        appDelegate.session = [[FBSession alloc] init]; 
        if (appDelegate.session.status == FBSessionStateLoadedValidToken) {
            // even though we had a cached token, we need to login to make the session usable
            [appDelegate.session loginWithCompletionHandler:^(FBSession *session, 
                                                              FBSessionState status, 
                                                              NSError *error) {
                [self updateForSessionChange];
            }];
        }
    }
}

// FBSample logic
// handler for button click, logs sessions in or out
- (IBAction)buttonClickHandler:(id)sender {
    // get the app delegate
    JLAppDelegate *appDelegate = [[UIApplication sharedApplication]delegate];
    
    // this button's job is to flip-flop the session from valid to invalid
    if (appDelegate.session.isValid) {
        // if a user logs out explicitly, we logout the session, which deletes any cached token 
        [appDelegate.session logout];
    } else {
        // in order to get the FBSession object up and running
        [appDelegate.session loginWithCompletionHandler:^(FBSession *session, 
                                                          FBSessionState status, 
                                                          NSError *error) {
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

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
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
