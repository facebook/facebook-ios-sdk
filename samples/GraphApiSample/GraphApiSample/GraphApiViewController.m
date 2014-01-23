/*
 * Copyright 2010-present Facebook.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#import "GraphApiViewController.h"

#import <FacebookSDK/FacebookSDK.h>

#import "GraphApiAppDelegate.h"

static NSString *loadingText = @"Loading...";

@interface GraphApiViewController ()

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

@implementation GraphApiViewController

@synthesize buttonRequest = _buttonRequest;
@synthesize textObjectID = _textObjectID;
@synthesize textOutput = _textOutput;
@synthesize requestConnection = _requestConnection;

- (void)dealloc {
    [_requestConnection cancel];
}

//
// When the button is clicked, make sure we have a valid session and
// call sendRequests.
//
- (void)buttonRequestClickHandler:(id)sender {
    // FBSample logic
    // Check to see whether we have already opened a session.
    if (FBSession.activeSession.isOpen) {
        // login is integrated with the send button -- so if open, we send
        [self sendRequests];
    } else {
        [FBSession openActiveSessionWithReadPermissions:nil
                                           allowLoginUI:YES
                                      completionHandler:^(FBSession *session,
                                                          FBSessionState status,
                                                          NSError *error) {
                                          // if login fails for any reason, we alert
                                          if (error) {
                                              UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                                                              message:error.localizedDescription
                                                                                             delegate:nil
                                                                                    cancelButtonTitle:@"OK"
                                                                                    otherButtonTitles:nil];
                                              [alert show];
                                              // if otherwise we check to see if the session is open, an alternative to
                                              // to the FB_ISSESSIONOPENWITHSTATE helper-macro would be to check the isOpen
                                              // property of the session object; the macros are useful, however, for more
                                              // detailed state checking for FBSession objects
                                          } else if (FB_ISSESSIONOPENWITHSTATE(status)) {
                                              // send our requests if we successfully logged in
                                              [self sendRequests];
                                          }
                                      }];
    }
}

// FBSample logic
// Read the ids to request from textObjectID and generate a FBRequest
// object for each one.  Add these to the FBRequestConnection and
// then connect to Facebook to get results.  Store the FBRequestConnection
// in case we need to cancel it before it returns.
//
// When a request returns results, call requestComplete:result:error.
//
- (void)sendRequests {
    // extract the id's for which we will request the profile
    NSArray *fbids = [self.textObjectID.text componentsSeparatedByString:@","];

    if ([self.textObjectID.text length] == 0) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                        message:@"Object ID is required"
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
        return;
    }

    self.textOutput.text = loadingText;
    if ([self.textObjectID isFirstResponder]) {
        [self.textObjectID resignFirstResponder];
    }

    // create the connection object
    FBRequestConnection *newConnection = [[FBRequestConnection alloc] init];

    // for each fbid in the array, we create a request object to fetch
    // the profile, along with a handler to respond to the results of the request
    for (NSString *fbid in fbids) {

        // create a handler block to handle the results of the request for fbid's profile
        FBRequestHandler handler =
            ^(FBRequestConnection *connection, id result, NSError *error) {
                // output the results of the request
                [self requestCompleted:connection forFbID:fbid result:result error:error];
            };

        // create the request object, using the fbid as the graph path
        // as an alternative the request* static methods of the FBRequest class could
        // be used to fetch common requests, such as /me and /me/friends
        FBRequest *request = [[FBRequest alloc] initWithSession:FBSession.activeSession
                                                      graphPath:fbid];

        // add the request to the connection object, if more than one request is added
        // the connection object will compose the requests as a batch request; whether or
        // not the request is a batch or a singleton, the handler behavior is the same,
        // allowing the application to be dynamic in regards to whether a single or multiple
        // requests are occuring
        [newConnection addRequest:request completionHandler:handler];
    }

    // if there's an outstanding connection, just cancel
    [self.requestConnection cancel];

    // keep track of our connection, and start it
    self.requestConnection = newConnection;
    [newConnection start];
}

// FBSample logic
// Report any results.  Invoked once for each request we make.
- (void)requestCompleted:(FBRequestConnection *)connection
                 forFbID:fbID
                  result:(id)result
                   error:(NSError *)error {
    // not the completion we were looking for...
    if (self.requestConnection &&
        connection != self.requestConnection) {
        return;
    }

    // clean this up, for posterity
    self.requestConnection = nil;

    if ([self.textOutput.text isEqualToString:loadingText]) {
        self.textOutput.text = @"";
    }

    NSString *text;
    if (error) {
        // error contains details about why the request failed
        text = error.localizedDescription;
    } else {
        // result is the json response from a successful request
        NSDictionary *dictionary = (NSDictionary *)result;
        // we pull the name property out, if there is one, and display it
        text = (NSString *)[dictionary objectForKey:@"name"];
    }

    self.textOutput.text = [NSString stringWithFormat:@"%@%@: %@\r\n",
                            self.textOutput.text,
                            [fbID stringByTrimmingCharactersInSet:
                             [NSCharacterSet whitespaceAndNewlineCharacterSet]],
                            text];
}

#pragma mark - View lifecycle

- (void)viewDidUnload {
    [super viewDidUnload];
    [self.requestConnection cancel];

    self.buttonRequest = nil;
    self.textObjectID = nil;
    self.textOutput = nil;
    self.requestConnection = nil;
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
