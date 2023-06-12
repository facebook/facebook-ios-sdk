/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !TARGET_OS_TV

#import "FBSDKSKAdnetworkUtils.h"

#import <FBSDKCoreKit_Basics/FBSDKCoreKit_Basics.h>

@implementation FBSDKSKAdnetworkUtils

+ (nullable NSArray<FBSDKSKAdNetworkEvent *> *)parseEvents:(NSArray<NSDictionary<NSString *, id> *> *)events
{
  if (!events) {
    return nil;
  }
  NSMutableArray<FBSDKSKAdNetworkEvent *> *parsedEvents = [NSMutableArray new];
  for (NSDictionary<NSString *, id> *eventEntry in events) {
    FBSDKSKAdNetworkEvent *event = [[FBSDKSKAdNetworkEvent alloc] initWithJSON:eventEntry];
    if (!event) {
      return nil;
    }
    [FBSDKTypeUtility array:parsedEvents addObject:event];
  }
  return [parsedEvents copy];
}

@end

#endif
