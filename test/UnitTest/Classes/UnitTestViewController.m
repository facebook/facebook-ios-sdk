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

#import "UnitTestViewController.h"
#import "FBConnect.h"

// Your Facebook APP Id must be set before running this example
// See http://www.facebook.com/developers/createapp.php
static NSString* kAppId = @"230820755197";
static NSString* kTestUser =@"499095509";

@implementation UnitTestViewController

//////////////////////////////////////////////////////////////////////////////////////////////////
// Private helper function

- (NSString *) getStringFromUrl: (NSString*) url needle:(NSString *) needle {
  NSString * str = nil;
  NSRange start = [url rangeOfString:needle];
  if (start.location != NSNotFound) {
    NSRange end = [[url substringFromIndex:start.location+start.length] rangeOfString:@"&"];
    NSUInteger offset = start.location+start.length;
    str = end.location == NSNotFound
    ? [url substringFromIndex:offset]
    : [url substringWithRange:NSMakeRange(offset, end.location)];  
    str = [str stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]; 
  }
  
  return str;
}

- (void) verifySessionInvalid {
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
                                 _token,@"access_token",
                                 nil];
  
  
  [_facebook dialog: @"feed"
          andParams: params
        andDelegate:self];
  
  
}

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

  
}

/**
 * Test start as view appear
 */
 
- (void) viewDidAppear:(BOOL)animated {
  [self startTest];
}

/**
 * Start test with authorize as the first step
 */
- (void) startTest {
  [_facebook authorize:kAppId permissions:_permissions delegate:self];
}

///////////////////////////////////////////////////////////////////////////////////////////////////
// NSObject

- (void) dealloc {
  
  [_facebook release];
  [_permissions release];
  [super dealloc];
}

///////////////////////////////////////////////////////////////////////////////////////////////////
// Test Cases

- (void) testLogin {
  NSLog(@"Test authorization");
  if (_facebook.accessToken) {
    NSLog(@"Test pass, accessToken obtained:%@",_facebook.accessToken);
    
  } else {
    NSLog(@"Test fail, unable to obtain accessToken");
    
  }
  _token = [_facebook.accessToken retain];
}

- (void) testLogout {
  NSLog(@"Test Logout");
  [_facebook logout:self];
}

- (void) testStreamPublish {
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
  
  
  [_facebook dialog: @"feed"
          andParams: params
        andDelegate:self];
  
  
}


- (void) testPublicApi {
  NSLog(@"Test Public Api");
  NSMutableDictionary * params = [NSMutableDictionary dictionaryWithObjectsAndKeys:
    [NSString stringWithFormat:@"SELECT uid,name FROM user WHERE uid=%@", kTestUser],
    @"query",
    nil];
  [_facebook requestWithMethodName: @"fql.query" 
                         andParams: params
                     andHttpMethod: @"POST" 
                       andDelegate: self];   
  
  
}

- (void) testAuthenticatedApi {
  NSLog(@"Test Authenticated Api");  
  
  [_facebook requestWithGraphPath:@"me" andDelegate:self];
  
  NSDateFormatter *formatter = [[NSDateFormatter alloc] init]; 
  NSString        *dateString;  
  [formatter setDateFormat:@"dd-MM-yyyy HH:mm"];  
  dateString = [formatter stringFromDate:[NSDate date]];  
  [formatter release];
  NSString *msg = @"Hello World";
  msg = [msg stringByAppendingString:dateString];
  
  NSMutableDictionary * params = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                  msg, @"message",
                                  nil];
  
  [_facebook requestWithGraphPath:@"me/feed" 
                        andParams:params 
                    andHttpMethod:@"POST" 
                      andDelegate:self]; 
  
}


- (void) testApiError {
  NSLog(@"Test Authenticated Api Error");  
  NSDateFormatter *formatter = [[NSDateFormatter alloc] init]; 
  NSString        *dateString;  
  [formatter setDateFormat:@"dd-MM-yyyy HH:mm"];  
  dateString = [formatter stringFromDate:[NSDate date]];  
  [formatter release];
  NSString *msg = @"Hi World";
  msg = [msg stringByAppendingString:dateString];
  
  NSMutableDictionary * params = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                  msg, @"message",
                                  nil];
  
  [_facebook requestWithGraphPath:[NSString stringWithFormat:@"%@/feed", kTestUser]
                        andParams:params 
                    andHttpMethod:@"POST" 
                      andDelegate:self]; 
  
}

///////////////////////////////////////////////////////////////////////////////////////////////////
// FBSessionDelegate

/** 
 * Start All test when the user logged in
 */
- (void) fbDidLogin {
  [self testLogin];
  [self testPublicApi];
  [self testAuthenticatedApi];
  [self testApiError];
  [self testStreamPublish];
}

-(void) fbDidLogout {
  if (_facebook.accessToken != nil) {
    NSLog(@"Test fail for test Logout");
  } else {
    [self verifySessionInvalid];
  }
  
}

///////////////////////////////////////////////////////////////////////////////////////////////////
// FBRequestDelegate

- (void)request:(FBRequest*)request didLoad:(id)result{

  if ([request.url hasPrefix:@"https://api.facebook.com/method/fql.query"]) {
    if (![[[result objectAtIndex:0] objectForKey:@"name"] 
          isEqualToString:@"Maria Diijieeji Letuchywitz"]) {
      NSLog(@"Test fail at test Public Api ");
    } else {
      NSLog(@"Test Success at test Public Api");
    }

  } else if ([request.url hasPrefix:@"https://graph.facebook.com/me/feed"]) {
    NSString *post_id = [result objectForKey:@"id"];
    if (post_id.length > 0) {
      NSLog(@"Test Success for testAuthenticatedApi POST");
    } else {
      NSLog(@"Test Fail for testAuthenticatedApi POST");
    }

  } else if ([request.url hasPrefix:@"https://graph.facebook.com/me"]) {
    if ([[result objectForKey:@"name"] length] > 0 ) {
      NSLog(@"Test Success at testAuthenticatedApi");
    } else {
      NSLog(@"Test Fail at testAuthenticatedApi");
    }
  } 
}

- (void)request:(FBRequest*)request didFailWithError:(NSError*)error{
  if ([request.url hasPrefix:[NSString stringWithFormat:@"%https://graph.facebook.com/%@/feed", 
                              kTestUser]]) {
    if ([[[[error userInfo] objectForKey:@"error"] objectForKey:@"message"] 
         isEqualToString:@"(#210) User not visible"])
      
      NSLog(@"Test Success at test Authenticated Api Error");
    
  }
}

///////////////////////////////////////////////////////////////////////////////////////////////////
// FBDialogDelegate

- (void)dialogCompleteWithUrl:(NSURL *)url {
  NSString *post_id = [self getStringFromUrl:[url absoluteString] needle:@"post_id="];

  if (post_id.length > 0) {
    NSLog(@"Test Success for testStreamPublish");
  } else {
    NSLog(@"Test Fail for testStreamPublish");
  }
   [self testLogout];
}
  

- (void)dialog:(FBDialog*)dialog didFailWithError:(NSError*)error {
  if (error.code == 190) {
    NSLog(@"Test Logout Succeed");
  } else {
    NSLog(@"Test Logout Fail");
  }
  
}
@end


