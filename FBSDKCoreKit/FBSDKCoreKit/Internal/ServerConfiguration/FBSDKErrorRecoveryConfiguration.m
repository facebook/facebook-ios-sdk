/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "FBSDKErrorRecoveryConfiguration.h"

#define FBSDK_ERROR_RECOVERY_CONFIGURATION_DESCRIPTION_KEY @"description"
#define FBSDK_ERROR_RECOVERY_CONFIGURATION_OPTIONS_KEY @"options"
#define FBSDK_ERROR_RECOVERY_CONFIGURATION_CATEGORY_KEY @"category"
#define FBSDK_ERROR_RECOVERY_CONFIGURATION_ACTION_KEY @"action"

@implementation FBSDKErrorRecoveryConfiguration

- (instancetype)initWithRecoveryDescription:(NSString *)description
                         optionDescriptions:(NSArray<NSString *> *)optionDescriptions
                                   category:(FBSDKGraphRequestError)category
                         recoveryActionName:(NSString *)recoveryActionName
{
  if ((self = [super init])) {
    _localizedRecoveryDescription = [description copy];
    _localizedRecoveryOptionDescriptions = [optionDescriptions copy];
    _errorCategory = category;
    _recoveryActionName = [recoveryActionName copy];
  }
  return self;
}

#pragma mark - NSSecureCoding

+ (BOOL)supportsSecureCoding
{
  return YES;
}

- (instancetype)initWithCoder:(NSCoder *)decoder
{
  NSString *description = [decoder decodeObjectOfClass:NSString.class forKey:FBSDK_ERROR_RECOVERY_CONFIGURATION_DESCRIPTION_KEY];
  NSArray<NSString *> *options = [decoder decodeObjectOfClasses:[NSSet setWithArray:@[NSArray.class, NSString.class]] forKey:FBSDK_ERROR_RECOVERY_CONFIGURATION_OPTIONS_KEY];
  NSNumber *category = [decoder decodeObjectOfClass:NSNumber.class forKey:FBSDK_ERROR_RECOVERY_CONFIGURATION_CATEGORY_KEY];
  NSString *action = [decoder decodeObjectOfClass:NSString.class forKey:FBSDK_ERROR_RECOVERY_CONFIGURATION_ACTION_KEY];

  return [self initWithRecoveryDescription:description
                        optionDescriptions:options
                                  category:category.unsignedIntegerValue
                        recoveryActionName:action];
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
  [encoder encodeObject:_localizedRecoveryDescription forKey:FBSDK_ERROR_RECOVERY_CONFIGURATION_DESCRIPTION_KEY];
  [encoder encodeObject:_localizedRecoveryOptionDescriptions forKey:FBSDK_ERROR_RECOVERY_CONFIGURATION_OPTIONS_KEY];
  [encoder encodeObject:@(_errorCategory) forKey:FBSDK_ERROR_RECOVERY_CONFIGURATION_CATEGORY_KEY];
  [encoder encodeObject:_recoveryActionName forKey:FBSDK_ERROR_RECOVERY_CONFIGURATION_ACTION_KEY];
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone
{
  // immutable
  return self;
}

@end
