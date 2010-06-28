/*
 * Copyright 2010 Facebook
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


#import "DemoAppViewController.h"
#import "FBConnect.h"

// Your Facebook API Key must be set before running this example
// See http://www.facebook.com/developers/createapp.php
static NSString* kApiKey = @"39c66d68e4adfa4691c4b93cf0afa93d";

@implementation DemoAppViewController

@synthesize label = _label;

//////////////////////////////////////////////////////////////////////////////////////////////////
// UIViewController

/**
 * initialization 
 */
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
  if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
    _permissions =  [[NSArray arrayWithObjects: 
                      @"publish_stream",@"read_stream", @"offline_access",nil] retain];
  }
  
  return self;
}

/**
 * Set initial view
 */
- (void) viewDidLoad {
  _facebook = [[[[Facebook alloc] init] autorelease] retain];
  [self.label setText:@"Please log in"];
  _getUserInfoButton.hidden    = YES;
  _getUserInfoButton2.hidden   = YES;
  _publishButton.hidden        = YES;
  _fbButton.isLoggedIn   = NO;
  [_fbButton updateImage];
  
}

///////////////////////////////////////////////////////////////////////////////////////////////////
// NSObject

- (void) dealloc {
  [_label release];
  [_fbButton release];
  [_getUserInfoButton release];
  [_getUserInfoButton2 release];
  [_publishButton release];
  [_facebook release];
  [_permissions release];
  [super dealloc];
}

///////////////////////////////////////////////////////////////////////////////////////////////////
// private

/**
 * Example of facebook login and permission request
 */
- (void) login {
  [_facebook authorize:kApiKey permissions:_permissions delegate:self];
}

/**
 * Example of facebook logout
 */
- (void) logout {
  [_facebook logout:self]; 
}

///////////////////////////////////////////////////////////////////////////////////////////////////
// IBAction

/**
 * Login/out button click
 */
- (IBAction) fbButtonClick: (id) sender {
  if (_fbButton.isLoggedIn) {
    [self logout];
  } else {
    [self login];
  }
}

/**
 * Example of graph API CAll
 */
- (IBAction) getUserInfo: (id)sender {
  [_facebook requestWithGraphPath:@"me" andDelegate:self];
}

/**
 * Example of REST API call
 */
- (IBAction) getUserInfo2: (id)sender {
  NSMutableDictionary * params = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                                      @"4", @"uids",
                                                      @"name", @"fields",
                                                      nil];
  [_facebook requestWithMethodName: @"users.getInfo" 
             andParams: params
             andHttpMethod: @"POST" 
             andDelegate: self]; 
}

/**
 * Example of display UIServer dialog
 */
- (IBAction) publishStream: (id)sender {
  
  SBJSON *jsonWriter = [[SBJSON new] autorelease];
  
  NSDictionary* actionLinks = [NSDictionary dictionaryWithObjectsAndKeys: 
                               @"Always Running",@"text",@"http://itsti.me/",@"href", nil];
  
  NSString *actionLinksStr = [jsonWriter stringWithObject:actionLinks];
  NSDictionary* attachment = [NSDictionary dictionaryWithObjectsAndKeys:
                               @"a long run", @"name",
                               @"The Facebook Running app", @"caption",
                               @"it is fun", @"description",
                               @"http://itsti.me/", @"href", nil];
  NSString *attachmentStr = [jsonWriter stringWithObject:attachment];
  NSMutableDictionary* params = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                 kApiKey, @"api_key",
                                 @"Share on Facebook",  @"user_message_prompt",
                                 actionLinksStr, @"action_links",
                                 attachmentStr, @"attachment",
                                 nil];
  
  
  [_facebook dialog: @"stream.publish"
          andParams: params
        andDelegate:self];
  
}




// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
  return YES;
}


/**
 * Callback for facebook login
 */ 
-(void) fbDidLogin {
  [self.label setText:@"logged in"];
  _getUserInfoButton.hidden    = NO;
  _getUserInfoButton2.hidden   = NO;
  _publishButton.hidden        = NO;
  _fbButton.isLoggedIn         = YES;
  [_fbButton updateImage];
}

/**
 * Callback for facebook logout
 */ 
-(void) fbDidLogout {
  [self.label setText:@"Please log in"];
  _getUserInfoButton.hidden    = YES;
  _getUserInfoButton2.hidden   = YES;
  _publishButton.hidden        = YES;
  _fbButton.isLoggedIn         = NO;
  [_fbButton updateImage];
}

///////////////////////////////////////////////////////////////////////////////////////////////////
// FBRequestDelegate

/**
 * Callback when a request receives Response
 */ 
- (void)request:(FBRequest*)request didReceiveResponse:(NSURLResponse*)response{
  NSLog(@"received response");
};

/**
 * Called when an error prevents the request from completing successfully.
 */
- (void)request:(FBRequest*)request didFailWithError:(NSError*)error{
  [self.label setText:[error localizedDescription]];
};

/**
 * Called when a request returns and its response has been parsed into an object.
 * The resulting object may be a dictionary, an array, a string, or a number, depending
 * on thee format of the API response.
 */
- (void)request:(FBRequest*)request didLoad:(id)result{
  if ([result isKindOfClass:[NSArray class]]) {
    result = [result objectAtIndex:0]; 
  }
  [self.label setText:[result objectForKey:@"name"]];
};

///////////////////////////////////////////////////////////////////////////////////////////////////
// FBDialogDelegate

/** 
 * Called when a UIServer Dialog successfully return
 */
- (void)dialogDidSucceed:(FBDialog*)dialog{
   [self.label setText:@"publish successfully"];
}

@end
