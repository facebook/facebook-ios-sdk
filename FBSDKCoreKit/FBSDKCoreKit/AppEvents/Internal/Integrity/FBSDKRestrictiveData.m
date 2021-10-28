/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "FBSDKRestrictiveData.h"

#import <Foundation/Foundation.h>

#import <FBSDKCoreKit_Basics/FBSDKCoreKit_Basics.h>

#define RESTRICTIVE_PARAM @"restrictive_param"
#define DEPRECATED_PARAM @"deprecated_param"
#define IS_DEPRECATED_EVENT @"is_deprecated_event"

@implementation FBSDKRestrictiveData

- (instancetype)initWithEventName:(FBSDKAppEventName)eventName params:(id)params
{
  self = [super init];
  if (self) {
    NSDictionary<NSString *, id> *paramDict = [FBSDKTypeUtility dictionaryValue:params];
    if (!paramDict) {
      return nil;
    }
    _eventName = eventName;
    _restrictiveParams = paramDict[RESTRICTIVE_PARAM] ? [FBSDKTypeUtility dictionaryValue:paramDict[RESTRICTIVE_PARAM]] : nil;
    _deprecatedParams = paramDict[DEPRECATED_PARAM] ? [FBSDKTypeUtility arrayValue:paramDict[DEPRECATED_PARAM]] : nil;
    _deprecatedEvent = (paramDict[IS_DEPRECATED_EVENT] && [paramDict[IS_DEPRECATED_EVENT] respondsToSelector:@selector(boolValue)]) ? [paramDict[IS_DEPRECATED_EVENT] boolValue] : NO;
  }
  return self;
}

@end
