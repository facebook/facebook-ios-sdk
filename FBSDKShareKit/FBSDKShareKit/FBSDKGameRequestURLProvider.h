// Copyright (c) 2014-present, Facebook, Inc. All rights reserved.
//
// You are hereby granted a non-exclusive, worldwide, royalty-free license to use,
// copy, modify, and distribute this software in source code or binary form for use
// in connection with the web services and APIs provided by Facebook.
//
// As with any software that integrates with the Facebook platform, your use of
// this software is subject to the Facebook Developer Principles and Policies
// [http://developers.facebook.com/policy/]. This copyright notice shall be
// included in all copies or substantial portions of the software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
// FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
// COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
// IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
// CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

#import <Foundation/Foundation.h>
#import "TargetConditionals.h"
#import "FBSDKCoreKitImport.h"

@class FBSDKGameRequestContent;

NS_ASSUME_NONNULL_BEGIN
/**
 NS_ENUM(NSUInteger, FBSDKGameRequestActionType)
  Additional context about the nature of the request.
 */
typedef NS_ENUM(NSUInteger, FBSDKGameRequestActionType)
{
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
typedef NS_ENUM(NSUInteger, FBSDKGameRequestFilter)
{
  /** No filter, all friends can be displayed. */
  FBSDKGameRequestFilterNone = 0,
  /** Friends using the app can be displayed. */
  FBSDKGameRequestFilterAppUsers,
  /** Friends not using the app can be displayed. */
  FBSDKGameRequestFilterAppNonUsers,
  /**All friends can be displayed if FB app is installed.*/
  FBSDKGameRequestFilterEverybody
} NS_SWIFT_NAME(GameRequestFilter);

NS_SWIFT_NAME(GameRequestURLProvider)
@interface FBSDKGameRequestURLProvider : NSObject
+ (NSURL *_Nullable)createDeepLinkURLWithQueryDictionary:(NSDictionary *_Nonnull)queryDictionary;
+ (NSString *_Nullable)filtersNameForFilters:(FBSDKGameRequestFilter)filters;
+ (NSString *_Nullable)actionTypeNameForActionType:(FBSDKGameRequestActionType)actionType;
@end
NS_ASSUME_NONNULL_END
