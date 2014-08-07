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

#import "FBSDKMacros.h"

FBSDK_EXTERN NSString *const FBLikeActionControllerDidDisableNotification;
FBSDK_EXTERN NSString *const FBLikeActionControllerDidResetNotification;
FBSDK_EXTERN NSString *const FBLikeActionControllerDidUpdateNotification;
FBSDK_EXTERN NSString *const FBLikeActionControllerAnimatedKey;

@interface FBLikeActionController : NSObject <NSCoding, NSDiscardableContent>

+ (BOOL)isDisabled;

// this method will call beginContentAccess before returning the instance
+ (instancetype)likeActionControllerForObjectID:(NSString *)objectID;

@property (nonatomic, copy, readonly) NSString *likeCountString;
@property (nonatomic, copy, readonly) NSString *objectID;
@property (nonatomic, assign, readonly) BOOL objectIsLiked;
@property (nonatomic, copy, readonly) NSString *socialSentence;

- (void)refresh;
- (void)toggleLikeWithSoundEnabled:(BOOL)soundEnabled analyticsParameters:(NSDictionary *)analyticsParameters;

@end
