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

#import "UserInfo.h"
#import "FBConnect.h"


@implementation UserInfo

@synthesize facebook = _facebook,
                 uid = _uid,
         friendsList = _friendsList,
         friendsInfo = _friendsInfo,
    userInfoDelegate = _userInfoDelegate;

///////////////////////////////////////////////////////////////////////////////////////////////////

/**
 * initialization
 */
- (id) initializeWithFacebook:(Facebook *)facebook andDelegate:(id<UserInfoLoadDelegate>)delegate {
  self = [super init];
  _facebook = [facebook retain];
  _userInfoDelegate = [delegate retain];
  return self;
}

- (void)dealloc {
  [_facebook release];
  [_uid release];
  [_friendsList release];
  [_friendsInfo release];
  [super dealloc];
}

/**
 * Request all info from the user is start with request user id as the authorization flow does not 
 * return the user id. This is an intermediate solution to obtain the logged in user id
 * All other information are requested in the FBRequestDelegate function after Uid obtained. 
 */
- (void) requestAllInfo {
  [self requestUid];
}

/**
 * Request the user id of the logged in user.
 *
 * Currently the authorization flow does not return a user id anymore. This is
 * an intermediate solution to get the logged in user id.
 */
- (void) requestUid{
  [_facebook requestWithGraphPath:@"me" andDelegate:self];
}

/** 
 * Request friends detail information
 *
 * Use FQL to query detailed friends information
 */
- (void) requestFriendsDetail{
  NSString *query = @"SELECT uid, name, pic_square, status FROM user WHERE uid IN (";
  query = [query stringByAppendingFormat:@"SELECT uid2 FROM friend WHERE uid1 = %@)", _uid];
  NSMutableDictionary * params = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                  query, @"query",
                                  nil];
  [_facebook requestWithMethodName: @"fql.query" 
                         andParams: params
                     andHttpMethod: @"POST" 
                       andDelegate: self]; 
  [query release];
}

/**
 * FBRequestDelegate
 */
- (void)request:(FBRequest*)request didLoad:(id)result{
     
  if ([request.url hasPrefix:@"https://graph.facebook.com/me"]) {
    self.uid = [result objectForKey:@"id"]; 
    [self requestFriendsDetail];   
  } else {
    _friendsInfo = [[[[NSMutableArray alloc] init] autorelease] retain];
    for (NSDictionary *info in result) {
      NSString *friend_id = [NSString stringWithString:[[info objectForKey:@"uid"] stringValue]];
      NSString *friend_name = nil;
      if ([info objectForKey:@"name"] != [NSNull null]) {
        friend_name = [NSString stringWithString:[info objectForKey:@"name"]];
      } 
      NSString *friend_pic = [info objectForKey:@"pic_square"];
      NSString *friend_status = [info objectForKey:@"status"];
      NSMutableDictionary *friend_info = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                          friend_id,@"uid",
                                          friend_name, @"name", 
                                          friend_pic, @"pic", 
                                          friend_status, @"status", 
                                          nil];
      [_friendsInfo addObject:friend_info];
    }
    if ([self.userInfoDelegate respondsToSelector:@selector(userInfoDidLoad)]) {
      [_userInfoDelegate userInfoDidLoad];
    }
  }
}

- (void)request:(FBRequest*)request didFailWithError:(NSError*)error {
  NSLog(@"%@",[error localizedDescription]);
  if ([self.userInfoDelegate respondsToSelector:@selector(userInfoFailToLoad)]) {
    [_userInfoDelegate userInfoFailToLoad];
  }
}

@end
