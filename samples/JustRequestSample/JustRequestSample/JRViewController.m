//
//  JRViewController.m
//  JustRequestSample
//
//  Created by Michael Marucheck on 4/3/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <FBiOSSDK/FBRequest.h>
#import "JRAppDelegate.h"
#import "JRViewController.h"

static NSString *loadingText = @"Loading...";

@interface JRViewController ()

@property (retain, nonatomic) IBOutlet UIButton *buttonRequest;
@property (retain, nonatomic) IBOutlet UITextField *textObjectID;
@property (retain, nonatomic) IBOutlet UITextView *textOutput;
@property (retain, nonatomic) FBRequestConnection *requestConnection;

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

    [_buttonRequest release];
    [_textObjectID release];
    [_textOutput release];
    [_requestConnection release];

    [super dealloc];
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
                [alert release];
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
    FBRequestConnection *connection = [[FBRequestConnection alloc] init];
    
    for (NSString *fbid in fbids) {
        FBRequestHandler handler =
            ^(FBRequestConnection *connection, id result, NSError *error) {
                [self requestCompleted:connection forFbID:fbid result:result error:error];
            };
        
        FBRequest *request = [[FBRequest alloc] initWithSession:appDelegate.session
                                                      graphPath:fbid];
        [connection addRequest:request completionHandler:handler];
    }
    
    [connection start];
    self.requestConnection = connection;
}

//
// Report any results
- (void)requestCompleted:(FBRequestConnection *)connection
                 forFbID:fbID
                  result:(id)result
                   error:(NSError *)error
{
    if (connection == self.requestConnection) {
        self.requestConnection = nil;
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
