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

#import "SCLoginViewController.h"
#import "SCAppDelegate.h"

@interface SCLoginViewController ()

@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *spinner;
@property (strong, nonatomic) IBOutlet UIButton *loginButton;

- (IBAction)performLogin:(id)sender;

@end

@implementation SCLoginViewController

@synthesize spinner = _spinner;
@synthesize loginButton = _loginButton;

- (IBAction)performLogin:(id)sender {
    [self.spinner startAnimating];
    
    // FBSample logic
    // The user has initiated a login, so call the openSession method.
    SCAppDelegate *appDelegate = [UIApplication sharedApplication].delegate;
    [appDelegate openSessionWithAllowLoginUI:YES];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self.spinner stopAnimating];
}

- (void)loginFailed {
    // FBSample logic
    // Our UI is quite simple, so all we need to do in the case of the user getting
    // back to this screen without having been successfully authorized is to
    // stop showing our activity indicator. The user can initiate another login
    // attempt by clicking the Login button again.
    [self.spinner stopAnimating];
}

- (void)viewDidUnload {
    self.spinner = nil;
    self.loginButton = nil;

    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
