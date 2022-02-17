/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
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
static NSString *const FB_CONTENT_KEY = @"fb_content";
static NSString *const FB_CONTENT_ID_KEY = @"fb_content_id";
static NSString *const ID_KEY = @"id";

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
  NSArray<NSDictionary<NSString *, id> *> *contentsData = [FBSDKTypeUtility dictionary:parameters objectForKey:@"fb_content" ofType:NSArray.class];
  for (NSDictionary<NSString *, id> *entry in contentsData) {
    NSDictionary<NSString *, NSArray<NSDictionary<NSString *, id> *> *> *entryParameters = @{@"fb_content" : @[entry]};
    if (![matchingRule isMatchedEventParameters:entryParameters]) {
      continue;
    }
    NSNumber *itemPrice = [FBSDKTypeUtility dictionary:entry objectForKey:ITEM_PRICE_KEY ofType:NSNumber.class] ?: @(0);
    NSNumber *quantity = [FBSDKTypeUtility dictionary:entry objectForKey:QUANTITY_KEY ofType:NSNumber.class] ?: @(1);
    value += itemPrice.doubleValue * quantity.doubleValue;
  }
  return [NSNumber numberWithDouble:value];
}

- (nullable NSString *)getContentID:(nullable NSDictionary<NSString *, id> *)parameters
{
  // Extract content ids from fb_content and fall back to fb_content_id if fb_content doesn't exist
  @try {
    NSString *content = [FBSDKTypeUtility dictionary:parameters objectForKey:FB_CONTENT_KEY ofType:NSString.class];
    if (content) {
      NSArray<NSDictionary<NSString *, id> *> *json = [FBSDKTypeUtility arrayValue:[FBSDKTypeUtility JSONObjectWithData:[content dataUsingEncoding:NSUTF8StringEncoding]
                                                                                                                options:0
                                                                                                                  error:nil]];
      NSMutableArray<NSString *> *contentIDs = [NSMutableArray new];
      for (NSDictionary<NSString *, id> *entry in json) {
        NSDictionary<NSString *, id> *item = [FBSDKTypeUtility dictionaryValue:entry];
        id contentID = [FBSDKTypeUtility dictionary:item objectForKey:ID_KEY ofType:NSString.class]
        ?: [FBSDKTypeUtility dictionary:item objectForKey:ID_KEY ofType:NSNumber.class];
        [FBSDKTypeUtility array:contentIDs addObject:[FBSDKTypeUtility coercedToStringValue:contentID]];
      }
      return [FBSDKBasicUtility JSONStringForObject:contentIDs error:nil invalidObjectHandler:nil];
    }
  } @catch (NSException *exception) {
    NSLog(@"Fail to parse AEM fb_content");
  }
  return [FBSDKTypeUtility dictionary:parameters objectForKey:FB_CONTENT_ID_KEY ofType:NSString.class];
}

@end

#endif
