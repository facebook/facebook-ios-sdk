/*
 * Copyright 2010-present Facebook.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
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

@property (readonly) NSInteger maximumUserSlots;
// FBSample logic
// This is where our active session is maintained
@property (strong, readonly) FBSession *currentSession;
@property (readonly) NSInteger currentUserSlot;

- (NSString *)getUserIDInSlot:(NSInteger)slot;
- (NSString *)getUserNameInSlot:(NSInteger)slot;
- (void)updateUser:(NSDictionary<FBGraphUser> *)user inSlot:(NSInteger)slot;

- (BOOL)isSlotEmpty:(NSInteger)slot;
- (BOOL)areAllSlotsEmpty;

- (void)switchToNoActiveUser;
- (FBSession *)switchToUserInSlot:(NSInteger)slot;

@end
