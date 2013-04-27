/*
 * Copyright 2010-present Facebook.
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
#import <FacebookSDK/FacebookSDK.h>

extern NSString *const SUInvalidSlotNumber;

@protocol FBGraphUser;

@interface SUUserManager : NSObject

@property (readonly) int maximumUserSlots;
// FBSample logic
// This is where our active session is maintained
@property (strong, readonly) FBSession *currentSession;
@property (readonly) int currentUserSlot;

- (id)init;

- (NSString*)getUserIDInSlot:(int)slot;
- (NSString*)getUserNameInSlot:(int)slot;
- (void)updateUser:(NSDictionary<FBGraphUser> *)user inSlot:(int)slot;

- (BOOL)isSlotEmpty:(int)slot;
- (BOOL)areAllSlotsEmpty;

- (void)switchToNoActiveUser;
- (FBSession *)switchToUserInSlot:(int)slot;

@end
