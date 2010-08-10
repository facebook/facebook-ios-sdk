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

#import "FriendsRequestResult.h"


@implementation FriendsRequestResult

- (id) initializeWithDelegate:(id<FriendsRequestDelegate>)delegate {
  self = [super init];
  _friendsRequestDelegate = [delegate retain];
  return self;   
}

/**
 * FBRequestDelegate
 */
- (void)request:(FBRequest*)request didLoad:(id)result{
  
    NSMutableArray *friendsInfo = [[[NSMutableArray alloc] init] autorelease];
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
      [friendsInfo addObject:friend_info];
    }
    

    [_friendsRequestDelegate FriendsRequestCompleteWithFriendsInfo:friendsInfo];
    
}


@end
