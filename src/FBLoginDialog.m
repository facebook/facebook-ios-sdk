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

#import "FBDialog.h"
#import "FBLoginDialog.h"

///////////////////////////////////////////////////////////////////////////////////////////////////

@implementation FBLoginDialog

//////////////////////////////////////////////////////////////////////////////////////////////////
// private

/**
 * private helper method: Find a specific parameter from the url
 */
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

///////////////////////////////////////////////////////////////////////////////////////////////////
// public 

/*
 * initialize the FBLoginDialog with url and parameters
 */
- (id)initWithURL:(NSString*) loginURL 
      loginParams:(NSMutableDictionary*) params 
         delegate:(id <FBLoginDialogDelegate>) delegate{
  
  self = [super init];
  _serverURL = [loginURL retain];
  _params = [params retain];
  _loginDelegate = [delegate retain];
  return self;
}

///////////////////////////////////////////////////////////////////////////////////////////////////
// FBDialog

/**
 * Override FBDialog : to call when the webView Dialog will disappear
 */
- (void)dialogWillDisappear {
  [_webView stringByEvaluatingJavaScriptFromString:@"email.blur();"];
}

/**
 * Override FBDialog : to call when the webView Dialog did succeed
 */
- (void) dialogDidSucceed:(NSURL*)url {
  NSString* q = [url absoluteString];
  NSString* token = [self getStringFromUrl:q needle:@"access_token="];
  NSString* expTime = [self getStringFromUrl:q needle:@"expires_in="];
  NSDate* expirationDate =nil;
  
  if (expTime != nil) {
    int expVal = [expTime intValue];
    if (expVal == 0) {
      expirationDate = [NSDate distantFuture];
    } else {
      expirationDate = [NSDate dateWithTimeIntervalSinceNow:expVal];
    } 
  } 
  
  if ([_loginDelegate respondsToSelector:@selector(fbDialogLogin:expirationDate:)]) {
    [_loginDelegate fbDialogLogin:token expirationDate:expirationDate];
  }    
}

/**
 * Override FBDialog : free the space
 */
- (void)dealloc {
  _loginDelegate = nil;
  [_loginDelegate release];
  [super dealloc];
}

@end
