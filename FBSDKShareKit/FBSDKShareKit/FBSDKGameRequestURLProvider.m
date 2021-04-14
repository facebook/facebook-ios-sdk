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

#import "FBSDKGameRequestURLProvider.h"

#ifdef FBSDKCOCOAPODS
 #import <FBSDKCoreKit/FBSDKCoreKit+Internal.h>
#else
 #import "FBSDKCoreKit+Internal.h"
#endif

#define FBSDK_GAME_REQUEST_URL_SCHEME @"https"
#define FBSDK_GAME_REQUEST_URL_HOST @"fb.gg"
#define FBSDK_GAME_REQUEST_URL_PATH @"/game_requestui/%@/"

@implementation FBSDKGameRequestURLProvider

+ (NSMutableArray *_Nonnull)_getQueryArrayFromGameRequestDictionary:(NSDictionary *_Nonnull)content
{
  NSMutableArray *queryItems = [NSMutableArray array];
  for (NSString *key in content) {
    [FBSDKTypeUtility array:queryItems addObject:[NSURLQueryItem queryItemWithName:key value:content[key]]];
  }
  return queryItems;
}

+ (nullable NSURL *)createDeepLinkURLWithQueryDictionary:(NSDictionary *)queryDictionary
{
  NSURLComponents *components = [NSURLComponents new];
  components.scheme = FBSDK_GAME_REQUEST_URL_SCHEME;
  components.host = FBSDK_GAME_REQUEST_URL_HOST;
  components.path = [NSString stringWithFormat:FBSDK_GAME_REQUEST_URL_PATH, FBSDKAccessToken.currentAccessToken.appID];
  components.queryItems = [FBSDKGameRequestURLProvider _getQueryArrayFromGameRequestDictionary:queryDictionary];
  return components.URL;
}

+ (NSString *)filtersNameForFilters:(FBSDKGameRequestFilter)filters
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
      if ([graphDomain isEqualToString:@"gaming"] && [FBSDKInternalUtility isFacebookAppInstalled]) {
        return @"everybody";
      }
      return nil;
    }
    default: {
      return nil;
    }
  }
}

+ (NSString *)actionTypeNameForActionType:(FBSDKGameRequestActionType)actionType
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
