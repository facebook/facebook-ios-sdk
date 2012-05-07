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

#import <FBiOSSDK/FBRequest.h>
#import "JRAppDelegate.h"
#import "JRViewController.h"

static NSString *loadingText = @"Loading...";

@interface JRViewController ()

@property (strong, nonatomic) IBOutlet UIButton *buttonRequest;
@property (strong, nonatomic) IBOutlet UITextField *textObjectID;
@property (strong, nonatomic) IBOutlet UITextView *textOutput;
@property (strong, nonatomic) FBRequestConnection *requestConnection;

- (IBAction)buttonRequestClickHandler:(id)sender;

- (void)sendRequests;

- (void)requestCompleted:(FBRequestConnection *)connection
                 forFbID:(NSString *)fbID
                  result:(id)result
                   error:(NSError *)error;

@end

@implementation JRViewController

@synthesize buttonRequest = _buttonRequest;
@synthesize textObjectID = _textObjectID;
@synthesize textOutput = _textOutput;
@synthesize requestConnection = _requestConnection;

- (void)dealloc
{
    [_requestConnection cancel];
}

//
// When the button is clicked, make sure we have a valid session and
// call sendRequests.
//
- (void)buttonRequestClickHandler:(id)sender
{
    JRAppDelegate *appDelegate = [UIApplication sharedApplication].delegate;
    if ([appDelegate.session isValid]) {
        [self sendRequests];
    } else {
        appDelegate.session = [[FBSession alloc] init];

        FBSessionStatusHandler handler =
            ^(FBSession *session, 
              FBSessionState status, 
              NSError *error) {
            if (error) {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                                message:error.localizedDescription
                                                               delegate:nil
                                                      cancelButtonTitle:@"OK"
                                                      otherButtonTitles:nil];
                [alert show];
            } else if (FB_ISSESSIONVALIDWITHSTATE(status)) {
                [self sendRequests];
            }
        };

        [appDelegate.session loginWithCompletionHandler:handler];
    }
}

//
// Read the ids to request from textObjectID and generate a FBRequest
// object for each one.  Add these to the FBRequestConnection and
// then connect to Facebook to get results.  Store the FBRequestConnection
// in case we need to cancel it before it returns.
//
// When a request returns results, call requestComplete:result:error.
//
- (void)sendRequests
{
    NSArray *fbids = [self.textObjectID.text componentsSeparatedByString:@","];
    
    self.textOutput.text = loadingText;
    if ([self.textObjectID isFirstResponder]) {
        [self.textObjectID resignFirstResponder];
    }
    
    JRAppDelegate *appDelegate = [UIApplication sharedApplication].delegate;
    FBRequestConnection *newConnection = [[FBRequestConnection alloc] init];
    
    for (NSString *fbid in fbids) {
        FBRequestHandler handler =
            ^(FBRequestConnection *connection, id result, NSError *error) {
                [self requestCompleted:connection forFbID:fbid result:result error:error];
            };
        
        FBRequest *request = [[FBRequest alloc] initWithSession:appDelegate.session
                                                      graphPath:fbid];
        [newConnection addRequest:request completionHandler:handler];
    }
    
    // if there's an outstanding connection, just cancel
    [self.requestConnection cancel];    
    
    self.requestConnection = newConnection;    
    [newConnection start];
}

//
// Report any results.  Invoked once for each request we make.
- (void)requestCompleted:(FBRequestConnection *)connection
                 forFbID:fbID
                  result:(id)result
                   error:(NSError *)error
{
    // not the completion we were looking for...
    if (connection != self.requestConnection) {
        return;
    }

    if ([self.textOutput.text isEqualToString:loadingText]) {
        self.textOutput.text = @"";
    }

    NSString *text;
    if (error) {
        text = error.localizedDescription;
    } else {
        NSDictionary *dictionary = (NSDictionary *)result;
        text = (NSString *)[dictionary objectForKey:@"name"];
    }
    
    self.textOutput.text = [NSString stringWithFormat:@"%@%@: %@\r\n",
                            self.textOutput.text, fbID, text];
}

#pragma mark - View lifecycle

- (void)viewDidUnload
{
    [super viewDidUnload];
    [self.requestConnection cancel];

    self.buttonRequest = nil;
    self.textObjectID = nil;
    self.textOutput = nil;
    self.requestConnection = nil;
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

@end
