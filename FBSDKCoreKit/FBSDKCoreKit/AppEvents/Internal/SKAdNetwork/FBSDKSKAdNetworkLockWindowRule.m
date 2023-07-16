/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !TARGET_OS_TV

#import "FBSDKSKAdNetworkLockWindowRule.h"
#import "FBSDKSKAdnetworkUtils.h"

#import <FBSDKCoreKit_Basics/FBSDKCoreKit_Basics.h>

@implementation FBSDKSKAdNetworkLockWindowRule

- (nullable instancetype)initWithJSON:(NSDictionary<NSString *, id> *)dict
{
  if ((self = [super init])) {
    dict = [FBSDKTypeUtility dictionaryValue:dict];
    if (!dict) {
      return nil;
    }
    NSString *lockWindowType = [FBSDKTypeUtility dictionary:dict objectForKey:@"lock_window_type" ofType:NSString.class];
    NSNumber *time = [FBSDKTypeUtility dictionary:dict objectForKey:@"time" ofType:NSNumber.class];
    NSArray<FBSDKSKAdNetworkEvent *> *events = [FBSDKSKAdnetworkUtils parseEvents:[FBSDKTypeUtility dictionary:dict objectForKey:@"events" ofType:NSArray.class]];
    NSNumber *postbackSequenceIndex = [FBSDKTypeUtility dictionary:dict objectForKey:@"postback_sequence_index" ofType:NSNumber.class];
    if (!lockWindowType || postbackSequenceIndex == nil || lockWindowType.length == 0) {
      return nil;
    }
    if ([lockWindowType isEqual: @"time"] && time == nil) {
      return nil;
    }
    if ([lockWindowType isEqual: @"event"] && (events == nil || events.count == 0)) {
      return nil;
    }
    _lockWindowType = lockWindowType;
    _time = time.integerValue;
    _events = events;
    _postbackSequenceIndex = postbackSequenceIndex.integerValue;
  }
  return self;
}

@end

#endif
