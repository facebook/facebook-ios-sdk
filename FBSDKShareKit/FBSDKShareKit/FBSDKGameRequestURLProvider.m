/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "FBSDKGameRequestURLProvider.h"

#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <FBSDKCoreKit_Basics/FBSDKCoreKit_Basics.h>

#define FBSDK_GAME_REQUEST_URL_HOST @"fb.gg"
#define FBSDK_GAME_REQUEST_URL_PATH @"/game_requestui/%@/"

@implementation FBSDKGameRequestURLProvider

+ (NSMutableArray *_Nonnull)_getQueryArrayFromGameRequestDictionary:(NSDictionary<NSString *, id> *_Nonnull)content
{
  NSMutableArray *queryItems = [NSMutableArray array];
  for (NSString *key in content) {
    [FBSDKTypeUtility array:queryItems addObject:[NSURLQueryItem queryItemWithName:key value:content[key]]];
  }
  return queryItems;
}

+ (nullable NSURL *)createDeepLinkURLWithQueryDictionary:(NSDictionary<NSString *, id> *)queryDictionary
{
  NSURLComponents *components = [NSURLComponents new];
  components.scheme = FBSDKURLSchemeHTTPS;
  components.host = FBSDK_GAME_REQUEST_URL_HOST;
  components.path = [NSString stringWithFormat:FBSDK_GAME_REQUEST_URL_PATH, FBSDKAccessToken.currentAccessToken.appID];
  components.queryItems = [FBSDKGameRequestURLProvider _getQueryArrayFromGameRequestDictionary:queryDictionary];
  return components.URL;
}

+ (nullable NSString *)filtersNameForFilters:(FBSDKGameRequestFilter)filters
{
  switch (filters) {
    case FBSDKGameRequestFilterNone: {
      return nil;
    }
    case FBSDKGameRequestFilterAppUsers: {
      return @"app_users";
    }
    case FBSDKGameRequestFilterAppNonUsers: {
      return @"app_non_users";
    }
    case FBSDKGameRequestFilterEverybody: {
      NSString *graphDomain = [FBSDKUtility getGraphDomainFromToken];
      if ([graphDomain isEqualToString:@"gaming"] && [FBSDKInternalUtility.sharedUtility isFacebookAppInstalled]) {
        return @"everybody";
      }
      return nil;
    }
    default: {
      return nil;
    }
  }
}

+ (nullable NSString *)actionTypeNameForActionType:(FBSDKGameRequestActionType)actionType
{
  switch (actionType) {
    case FBSDKGameRequestActionTypeNone: {
      return nil;
    }
    case FBSDKGameRequestActionTypeSend: {
      return @"send";
    }
    case FBSDKGameRequestActionTypeAskFor: {
      return @"askfor";
    }
    case FBSDKGameRequestActionTypeTurn: {
      return @"turn";
    }
    case FBSDKGameRequestActionTypeInvite: {
      return @"invite";
    }
    default: {
      return nil;
    }
  }
}

@end
