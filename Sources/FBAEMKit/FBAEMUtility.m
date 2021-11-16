/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "TargetConditionals.h"

#if !TARGET_OS_TV

 #import "FBAEMUtility.h"

 #import "FBCoreKitBasicsImportForAEMKit.h"

static NSString *const ITEM_PRICE_KEY = @"item_price";
static NSString *const QUANTITY_KEY = @"quantity";

@implementation FBAEMUtility

+ (instancetype)sharedUtility
{
  static FBAEMUtility *instance;
  static dispatch_once_t sharedUtilityNonce;
  dispatch_once(&sharedUtilityNonce, ^{
    instance = [self new];
  });
  return instance;
}

- (NSNumber *)getInSegmentValue:(nullable NSDictionary<NSString *, id> *)parameters
                   matchingRule:(id<FBAEMAdvertiserRuleMatching>)matchingRule
{
  if (!parameters) {
    return @(0);
  }

  double value = 0;
  NSArray<NSDictionary *> *contentsData = [FBSDKTypeUtility dictionary:parameters objectForKey:@"fb_content" ofType:NSArray.class];
  for (NSDictionary *entry in contentsData) {
    NSDictionary<NSString *, NSArray *> *entryParameters = @{@"fb_content" : @[entry]};
    if (![matchingRule isMatchedEventParameters:entryParameters]) {
      continue;
    }
    NSNumber *itemPrice = [FBSDKTypeUtility dictionary:entry objectForKey:ITEM_PRICE_KEY ofType:NSNumber.class] ?: @(0);
    NSNumber *quantity = [FBSDKTypeUtility dictionary:entry objectForKey:QUANTITY_KEY ofType:NSNumber.class] ?: @(1);
    value += itemPrice.doubleValue * quantity.doubleValue;
  }
  return [NSNumber numberWithDouble:value];
}

@end

#endif
