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

#import <Foundation/Foundation.h>
#import "FBConnect.h"

/**
 * This class is an example of saving the Facebook access token to perm store
 * so that the user do not need to login every time visit the app
 */
@interface Session : NSObject {
  Facebook *_facebook;
  NSString *_uid;
}

@property(nonatomic, retain) Facebook *facebook;
@property(nonatomic, retain) NSString *uid;

- (void) setSessionWithFacebook:(Facebook *)facebook andUid:(NSString *)uid;
- (Facebook *) getFacebook;
- (NSString *) getUid;
- (void) save;
- (void) unsave;
- (id) restore;
@end
