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

#import "Session.h"
#import "FBConnect.h"

@implementation Session

@synthesize facebook = _facebook,
                 uid = _uid;

- (id) init {
  if (self = [super init]) {
    _facebook = nil;
    _uid = nil;
  }
  return self;
}

- (void) setSessionWithFacebook:(Facebook *)facebook andUid:(NSString *)uid {
  _facebook = [facebook retain];
  _uid = [uid retain];
}

- (Facebook *) getFacebook {
  return _facebook; 
}

- (NSString *) getUid {
  return _uid; 
}

- (void) save {
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  if ((_uid != (NSString *) [NSNull null]) && (_uid.length > 0)) {
    [defaults setObject:_uid forKey:@"FBUserId"];
  } else {
    [defaults removeObjectForKey:@"FBUserId"];
  }
  
  NSString *access_token = _facebook.accessToken;
  if ((access_token != (NSString *) [NSNull null]) && (access_token.length > 0)) {
    [defaults setObject:access_token forKey:@"FBAccessToken"];
  } else {
    [defaults removeObjectForKey:@"FBAccessToken"];
  }
 
  NSDate *expirationDate = _facebook.expirationDate;  
  if (expirationDate) {
    [defaults setObject:expirationDate forKey:@"FBSessionExpires"];
  } else {
    [defaults removeObjectForKey:@"FBSessionExpires"];
  }
  
  [defaults synchronize];
  
}

- (void) unsave {
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  [defaults removeObjectForKey:@"FBUserId"];
  [defaults removeObjectForKey:@"FBAccessToken"];
  [defaults removeObjectForKey:@"FBSessionExpires"];
  [defaults synchronize]; 
}

- (id) restore {
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  NSString *uid = [defaults objectForKey:@"FBUserId"];
  if (uid) {
    NSDate* expirationDate = [defaults objectForKey:@"FBSessionExpires"];
    if (!expirationDate || [expirationDate timeIntervalSinceNow] > 0) {
      _uid = uid;
      _facebook = [[[[Facebook alloc] init] retain] autorelease];
      _facebook.accessToken = [[defaults stringForKey:@"FBAccessToken"] copy];
      _facebook.expirationDate = [expirationDate retain];
    
      return _facebook;
    }
  }
  return nil;  
}


@end
