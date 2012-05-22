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

@property (strong, nonatomic) IBOutlet UIActivityIndicatorView* spinner;
@property (strong, nonatomic) IBOutlet UIButton* loginButton;

- (IBAction)performLogin:(id)sender;

@end

@implementation SCLoginViewController

@synthesize spinner = _spinner;
@synthesize loginButton = _loginButton;

- (IBAction)performLogin:(id)sender 
{
    [self.spinner startAnimating];
    
    SCAppDelegate* appDelegate = [UIApplication sharedApplication].delegate;
    FBSession *session = [appDelegate invalidateAndGetNewSession];
    [session openWithCompletionHandler:
        ^(FBSession *session, FBSessionState state, NSError *error) {
            [self.spinner stopAnimating];
            switch (state) {
                case FBSessionStateOpen:
                    if (!error) {
                        [self dismissModalViewControllerAnimated:YES];
                    }
                    break;
                default:
                    break;
            }
            if (error) {
                UIAlertView *alertView =
                [[UIAlertView alloc] initWithTitle:@"Error"
                                           message:error.localizedDescription
                                          delegate:nil
                                 cancelButtonTitle:@"OK"
                                 otherButtonTitles:nil];
                [alertView show];
            }
        }
    ];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
    self.spinner = nil;
    self.loginButton = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
