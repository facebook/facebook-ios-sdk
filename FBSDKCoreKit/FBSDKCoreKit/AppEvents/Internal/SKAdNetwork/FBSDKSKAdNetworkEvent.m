/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !TARGET_OS_TV

#import "FBSDKSKAdNetworkEvent.h"

#import <Foundation/Foundation.h>

#import <FBSDKCoreKit_Basics/FBSDKCoreKit_Basics.h>

@implementation FBSDKSKAdNetworkEvent

- (nullable instancetype)initWithJSON:(NSDictionary<NSString *, id> *)dict
{
  if ((self = [super init])) {
    dict = [FBSDKTypeUtility dictionaryValue:dict];
    if (!dict) {
      return nil;
    }
    _eventName = [FBSDKTypeUtility dictionary:dict objectForKey:@"event_name" ofType:NSString.class];
    // Event name is a required field
    if (!_eventName) {
      return nil;
    }
    // Values is an optional field
    NSArray<NSDictionary<NSString *, id> *> *valueEntries = [FBSDKTypeUtility dictionary:dict objectForKey:@"values" ofType:NSArray.class];
    if (valueEntries) {
      NSMutableDictionary<NSString *, NSNumber *> *valueDict = [NSMutableDictionary new];
      for (NSDictionary<NSString *, id> *valueEntry in valueEntries) {
        NSDictionary<NSString *, id> *value = [FBSDKTypeUtility dictionaryValue:valueEntry];
        NSString *currency = [FBSDKTypeUtility dictionary:value objectForKey:@"currency" ofType:NSString.class];
        NSNumber *amount = [FBSDKTypeUtility dictionary:value objectForKey:@"amount" ofType:NSNumber.class];
        if (!currency || amount == nil) {
          return nil;
        }
        [FBSDKTypeUtility dictionary:valueDict setObject:amount forKey:currency.uppercaseString];
      }
      _values = [valueDict copy];
    }
  }
  return self;
}

@end

#endif
