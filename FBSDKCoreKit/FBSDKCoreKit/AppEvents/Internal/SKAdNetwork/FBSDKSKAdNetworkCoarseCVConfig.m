/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !TARGET_OS_TV

#import "FBSDKSKAdNetworkCoarseCVConfig.h"

#import <FBSDKCoreKit_Basics/FBSDKCoreKit_Basics.h>

@implementation FBSDKSKAdNetworkCoarseCVConfig

- (nullable instancetype)initWithJSON:(NSDictionary<NSString *, id> *)dict
{
  if ((self = [super init])) {
    dict = [FBSDKTypeUtility dictionaryValue:dict];
    if (!dict) {
      return nil;
    }
    NSNumber *postbackSequenceIndex = [FBSDKTypeUtility dictionary:dict objectForKey:@"postback_sequence_index" ofType:NSNumber.class];
    NSArray<FBSDKSKAdNetworkCoarseCVRule *> *cvRules = [FBSDKSKAdNetworkCoarseCVConfig parseRules:[FBSDKTypeUtility dictionary:dict objectForKey:@"coarse_cv_rules" ofType:NSArray.class]];
    if (postbackSequenceIndex == nil || !cvRules || cvRules.count == 0) {
      return nil;
    }
    _postbackSequenceIndex = postbackSequenceIndex.integerValue;
    _cvRules = cvRules;
  }
  return self;
}

+ (nullable NSArray<FBSDKSKAdNetworkCoarseCVRule *> *)parseRules:(NSArray<NSDictionary<NSString *, id> *> *)rules
{
  if (!rules) {
    return nil;
  }
  NSMutableArray<FBSDKSKAdNetworkEvent *> *parsedRules = [NSMutableArray new];
  for (NSDictionary<NSString *, id> *ruleEntry in rules) {
    FBSDKSKAdNetworkCoarseCVRule *rule = [[FBSDKSKAdNetworkCoarseCVRule alloc] initWithJSON:ruleEntry];
    if (!rule) {
      return nil;
    }
    [FBSDKTypeUtility array:parsedRules addObject:rule];
  }
  NSArray *coarseCVs = @[@"none", @"low", @"medium", @"high"];
  [parsedRules sortUsingComparator:^NSComparisonResult (FBSDKSKAdNetworkCoarseCVRule *obj1, FBSDKSKAdNetworkCoarseCVRule *obj2) {
    if ([coarseCVs indexOfObject:obj1.coarseCvValue] > [coarseCVs indexOfObject:obj2.coarseCvValue]) {
      return NSOrderedAscending;
    }
    if ([coarseCVs indexOfObject:obj1.coarseCvValue] < [coarseCVs indexOfObject:obj2.coarseCvValue]) {
      return NSOrderedDescending;
    }
    return NSOrderedSame;
  }];
  return [parsedRules copy];
}

@end

#endif
