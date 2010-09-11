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

// Your Facebook APP Id must be set before running this example
// See http://www.facebook.com/developers/createapp.php
static NSString* kAppId = nil;

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
                      @"read_stream", @"offline_access",nil] retain];
  }
  
  return self;
}

/**
 * Set initial view
 */
- (void) viewDidLoad {
  _facebook = [[Facebook alloc] init];
  [self.label setText:@"Please log in"];
  _getUserInfoButton.hidden    = YES;
  _getPublicInfoButton.hidden   = YES;
  _publishButton.hidden        = YES;
  _uploadPhotoButton.hidden    = YES;
  _fbButton.isLoggedIn   = NO;
  [_fbButton updateImage];
  
}

///////////////////////////////////////////////////////////////////////////////////////////////////
// NSObject

- (void) dealloc {
  [_label release];
  [_fbButton release];
  [_getUserInfoButton release];
  [_getPublicInfoButton release];
  [_publishButton release];
  [_uploadPhotoButton release];
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
  [_facebook authorize:kAppId permissions:_permissions delegate:self];
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
 *
 * This lets you make a Graph API Call to get the information of current logged in user.
 */
- (IBAction) getUserInfo: (id)sender {
  [_facebook requestWithGraphPath:@"me" andDelegate:self];
}


/**
 * Example of REST API CAll
 *
 * This lets you make a REST API Call to get a user's public information with FQL.
 */
- (IBAction) getPublicInfo: (id)sender {
  NSMutableDictionary * params = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                  @"SELECT uid,name FROM user WHERE uid=4", @"query",
                                  nil];
  [_facebook requestWithMethodName: @"fql.query" 
                         andParams: params
                     andHttpMethod: @"POST" 
                       andDelegate: self]; 
}

/**
 * Example of display Facebook dialogs
 *
 * This lets you publish a story to the user's stream. It uses UIServer, which is a consistent 
 * way of displaying user-facing dialogs
 */
- (IBAction) publishStream: (id)sender {
  
  SBJSON *jsonWriter = [[SBJSON new] autorelease];
  
  NSDictionary* actionLinks = [NSArray arrayWithObjects:[NSDictionary dictionaryWithObjectsAndKeys: 
                               @"Always Running",@"text",@"http://itsti.me/",@"href", nil], nil];
  
  NSString *actionLinksStr = [jsonWriter stringWithObject:actionLinks];
  NSDictionary* attachment = [NSDictionary dictionaryWithObjectsAndKeys:
                               @"a long run", @"name",
                               @"The Facebook Running app", @"caption",
                               @"it is fun", @"description",
                               @"http://itsti.me/", @"href", nil];
  NSString *attachmentStr = [jsonWriter stringWithObject:attachment];
  NSMutableDictionary* params = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                 kAppId, @"api_key",
                                 @"Share on Facebook",  @"user_message_prompt",
                                 actionLinksStr, @"action_links",
                                 attachmentStr, @"attachment",
                                 nil];
  
  
  [_facebook dialog: @"stream.publish"
          andParams: params
        andDelegate:self];
  
}


-(IBAction) uploadPhoto: (id)sender {
  NSString *path = @"http://www.facebook.com/images/devsite/iphone_connect_btn.jpg";
  NSURL    *url  = [NSURL URLWithString:path];
  NSData   *data = [NSData dataWithContentsOfURL:url];
  UIImage  *img  = [[UIImage alloc] initWithData:data];
 
  NSMutableDictionary * params = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                  img, @"picture",
                                  nil];
  [_facebook requestWithMethodName: @"photos.upload" 
                         andParams: params
                     andHttpMethod: @"POST" 
                       andDelegate: self]; 
  [img release];  
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
  _getPublicInfoButton.hidden   = NO;
  _publishButton.hidden        = NO;
  _uploadPhotoButton.hidden    = NO;
  _fbButton.isLoggedIn         = YES;
  [_fbButton updateImage];
}

/**
 * Callback for facebook did not login
 */
- (void)fbDidNotLogin:(BOOL)cancelled {
  NSLog(@"did not login");
}

/**
 * Callback for facebook logout
 */ 
-(void) fbDidLogout {
  [self.label setText:@"Please log in"];
  _getUserInfoButton.hidden    = YES;
  _getPublicInfoButton.hidden   = YES;
  _publishButton.hidden        = YES;
  _uploadPhotoButton.hidden = YES;
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
- (void)request:(FBRequest*)request didLoad:(id)result {
  if ([result isKindOfClass:[NSArray class]]) {
    result = [result objectAtIndex:0]; 
  }
  if ([result objectForKey:@"owner"]) {
    [self.label setText:@"Photo upload Success"];
  } else {
    [self.label setText:[result objectForKey:@"name"]];
  }
};

///////////////////////////////////////////////////////////////////////////////////////////////////
// FBDialogDelegate

/** 
 * Called when a UIServer Dialog successfully return
 */
- (void)dialogDidComplete:(FBDialog*)dialog{
   [self.label setText:@"publish successfully"];
}

@end
