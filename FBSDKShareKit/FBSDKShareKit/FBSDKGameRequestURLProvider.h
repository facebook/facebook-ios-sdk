/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <Foundation/Foundation.h>

#import <FBSDKCoreKit/FBSDKCoreKit.h>

NS_ASSUME_NONNULL_BEGIN
/**
 NS_ENUM(NSUInteger, FBSDKGameRequestActionType)
  Additional context about the nature of the request.
 */
typedef NS_ENUM(NSUInteger, FBSDKGameRequestActionType) {
  /** No action type */
  FBSDKGameRequestActionTypeNone = 0,
  /** Send action type: The user is sending an object to the friends. */
  FBSDKGameRequestActionTypeSend,
  /** Ask For action type: The user is asking for an object from friends. */
  FBSDKGameRequestActionTypeAskFor,
  /** Turn action type: It is the turn of the friends to play against the user in a match. (no object) */
  FBSDKGameRequestActionTypeTurn,
  /** Invite action type: The user is inviting a friend. */
  FBSDKGameRequestActionTypeInvite,
} NS_SWIFT_NAME(GameRequestActionType);

/**
 NS_ENUM(NSUInteger, FBSDKGameRequestFilters)
  Filter for who can be displayed in the multi-friend selector.
 */
typedef NS_ENUM(NSUInteger, FBSDKGameRequestFilter) {
  /** No filter, all friends can be displayed. */
  FBSDKGameRequestFilterNone = 0,
  /** Friends using the app can be displayed. */
  FBSDKGameRequestFilterAppUsers,
  /** Friends not using the app can be displayed. */
  FBSDKGameRequestFilterAppNonUsers,
  /**All friends can be displayed if FB app is installed.*/
  FBSDKGameRequestFilterEverybody,
} NS_SWIFT_NAME(GameRequestFilter);

NS_SWIFT_NAME(GameRequestURLProvider)
@interface FBSDKGameRequestURLProvider : NSObject
+ (NSURL *_Nullable)createDeepLinkURLWithQueryDictionary:(NSDictionary<NSString *, id> *_Nonnull)queryDictionary;
+ (NSString *_Nullable)filtersNameForFilters:(FBSDKGameRequestFilter)filters;
+ (NSString *_Nullable)actionTypeNameForActionType:(FBSDKGameRequestActionType)actionType;
@end
NS_ASSUME_NONNULL_END
