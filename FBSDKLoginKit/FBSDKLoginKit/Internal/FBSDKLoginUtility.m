/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !TARGET_OS_TV

#import "FBSDKLoginUtility.h"

#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <FBSDKCoreKit_Basics/FBSDKCoreKit_Basics.h>

#import "FBSDKLoginConstants.h"

@implementation FBSDKLoginUtility

+ (NSString *)stringForAudience:(FBSDKDefaultAudience)audience
{
  switch (audience) {
    case FBSDKDefaultAudienceOnlyMe:
      return @"only_me";
    case FBSDKDefaultAudienceFriends:
      return @"friends";
    case FBSDKDefaultAudienceEveryone:
      return @"everyone";
  }
}

+ (nullable NSDictionary<NSString *, id> *)queryParamsFromLoginURL:(NSURL *)url
{
  NSString *expectedUrlPrefix = [FBSDKInternalUtility.sharedUtility
                                 appURLWithHost:@"authorize"
                                 path:@""
                                 queryParameters:@{}
                                 error:NULL].absoluteString;
  if (![url.absoluteString hasPrefix:expectedUrlPrefix]) {
    // Don't have an App ID, just verify path.
    NSString *host = url.host;
    if (![host isEqualToString:@"authorize"]) {
      return nil;
    }
  }
  NSMutableDictionary<NSString *, id> *params = [NSMutableDictionary dictionaryWithDictionary:[FBSDKInternalUtility.sharedUtility parametersFromFBURL:url]];

  NSString *userID = [self.class userIDFromSignedRequest:params[@"signed_request"]];
  if (userID) {
    [FBSDKTypeUtility dictionary:params setObject:userID forKey:@"user_id"];
  }

  return params;
}

+ (nullable NSString *)userIDFromSignedRequest:(nullable NSString *)signedRequest
{
  if (!signedRequest) {
    return nil;
  }

  NSArray *signatureAndPayload = [signedRequest componentsSeparatedByString:@"."];
  NSString *userID = nil;

  if (signatureAndPayload.count == 2) {
    NSData *data = [FBSDKBase64 decodeAsData:[FBSDKTypeUtility array:signatureAndPayload objectAtIndex:1]];
    if (data) {
      NSDictionary<NSString *, id> *dictionary = [FBSDKTypeUtility JSONObjectWithData:data options:0 error:nil];
      userID = dictionary[@"user_id"];
    }
  }
  return userID;
}

@end

#endif
