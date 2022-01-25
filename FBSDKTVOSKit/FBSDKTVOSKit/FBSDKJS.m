/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "FBSDKJS.h"

#import <FBSDKCoreKit/FBSDKCoreKit.h>

@implementation FBSDKJS

+ (NSString *)accessTokenString
{
  return FBSDKAccessToken.currentAccessToken.tokenString;
}

+ (BOOL)hasGranted:(NSString *)permission
{
  return [FBSDKAccessToken.currentAccessToken hasGranted:permission];
}

+ (BOOL)isLoggedIn
{
  return (FBSDKAccessToken.currentAccessToken != nil);
}

+ (void)logEvent:(FBSDKAppEventName)eventName
{
  [FBSDKAppEvents.shared logEvent:eventName];
}

+ (void)logEvent:(FBSDKAppEventName)eventName parameters:(nullable NSDictionary<FBSDKAppEventParameterName, id> *)parameters
{
  [FBSDKAppEvents.shared logEvent:eventName parameters:parameters];
}

+ (void)logPurchase:(double)purchaseAmount currency:(NSString *)currency
{
  [FBSDKAppEvents.shared logPurchase:purchaseAmount currency:currency];
}

+ (void)logPurchase:(double)purchaseAmount
           currency:(NSString *)currency
         parameters:(nullable NSDictionary<FBSDKAppEventParameterName, id> *)parameters
{
  [FBSDKAppEvents.shared logPurchase:purchaseAmount currency:currency parameters:parameters];
}

@end
