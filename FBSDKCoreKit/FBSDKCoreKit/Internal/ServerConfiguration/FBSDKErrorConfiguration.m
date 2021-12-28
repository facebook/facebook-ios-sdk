/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "FBSDKErrorConfiguration.h"

#import <FBSDKCoreKit_Basics/FBSDKCoreKit_Basics.h>

#import "FBSDKGraphRequestProtocol.h"
#import "FBSDKInternalUtility+Internal.h"
#import "FBSDKSettings.h"

static NSString *const kErrorCategoryOther = @"other";
static NSString *const kErrorCategoryTransient = @"transient";
static NSString *const kErrorCategoryLogin = @"login";

#define FBSDKERRORCONFIGURATION_DICTIONARY_KEY @"configurationDictionary"

@interface FBSDKErrorConfiguration ()
@property (nonatomic) NSMutableDictionary<NSString *, id> *configurationDictionary;
@end

@implementation FBSDKErrorConfiguration

- (instancetype)initWithDictionary:(NSDictionary<NSString *, id> *)dictionary
{
  if ((self = [super init])) {
    if (dictionary) {
      _configurationDictionary = [NSMutableDictionary dictionaryWithDictionary:dictionary];
    } else {
      _configurationDictionary = [NSMutableDictionary dictionary];
      NSString *localizedOK =
      NSLocalizedStringWithDefaultValue(
        @"ErrorRecovery.OK",
        @"FacebookSDK",
        [FBSDKInternalUtility.sharedUtility bundleForStrings],
        @"OK",
        @"The title of the label to start attempting error recovery"
      );
      NSString *localizedCancel =
      NSLocalizedStringWithDefaultValue(
        @"ErrorRecovery.Cancel",
        @"FacebookSDK",
        [FBSDKInternalUtility.sharedUtility bundleForStrings],
        @"Cancel",
        @"The title of the label to decline attempting error recovery"
      );
      NSString *localizedTransientSuggestion =
      NSLocalizedStringWithDefaultValue(
        @"ErrorRecovery.Transient.Suggestion",
        @"FacebookSDK",
        [FBSDKInternalUtility.sharedUtility bundleForStrings],
        @"The server is temporarily busy, please try again.",
        @"The fallback message to display to retry transient errors"
      );
      NSString *localizedLoginRecoverableSuggestion =
      NSLocalizedStringWithDefaultValue(
        @"ErrorRecovery.Login.Suggestion",
        @"FacebookSDK",
        [FBSDKInternalUtility.sharedUtility bundleForStrings],
        @"Please log into this app again to reconnect your Facebook account.",
        @"The fallback message to display to recover invalidated tokens"
      );
      NSArray<NSDictionary<NSString *, id> *> *fallbackArray = @[
        @{ @"name" : @"login",
           @"items" : @[@{ @"code" : @102 },
                        @{ @"code" : @190 }],
           @"recovery_message" : localizedLoginRecoverableSuggestion,
           @"recovery_options" : @[localizedOK, localizedCancel]},
        @{ @"name" : @"transient",
           @"items" : @[@{ @"code" : @1 },
                        @{ @"code" : @2 },
                        @{ @"code" : @4 },
                        @{ @"code" : @9 },
                        @{ @"code" : @17 },
                        @{ @"code" : @341 }],
           @"recovery_message" : localizedTransientSuggestion,
           @"recovery_options" : @[localizedOK]},
      ];
      [self updateWithArray:fallbackArray];
    }
  }
  return self;
}

- (nullable FBSDKErrorRecoveryConfiguration *)recoveryConfigurationForCode:(nullable NSString *)code
                                                                   subcode:(nullable NSString *)subcode
                                                                   request:(nonnull id<FBSDKGraphRequest>)request
{
  code = code ?: @"*";
  subcode = subcode ?: @"*";
  FBSDKErrorRecoveryConfiguration *configuration = (_configurationDictionary[code][subcode]
    ?: _configurationDictionary[code][@"*"]
      ?: _configurationDictionary[@"*"][subcode]
        ?: _configurationDictionary[@"*"][@"*"]);
  if (configuration.errorCategory == FBSDKGraphRequestErrorRecoverable
      && FBSDKSettings.sharedSettings.clientToken
      && [request.parameters[@"access_token"] hasSuffix:FBSDKSettings.sharedSettings.clientToken]) {
    // do not attempt to recovery client tokens.
    return nil;
  }
  return configuration;
}

- (void)updateWithArray:(NSArray<NSDictionary<NSString *, id> *> *)array
{
  for (NSDictionary<NSString *, id> *dictionary in [FBSDKTypeUtility arrayValue:array]) {
    [FBSDKTypeUtility dictionary:dictionary enumerateKeysAndObjectsUsingBlock:^(NSString *key, id obj, BOOL *stop) {
      FBSDKGraphRequestError category;
      NSString *action = [FBSDKTypeUtility coercedToStringValue:dictionary[@"name"]];
      if ([action isEqualToString:kErrorCategoryOther]) {
        category = FBSDKGraphRequestErrorOther;
      } else if ([action isEqualToString:kErrorCategoryTransient]) {
        category = FBSDKGraphRequestErrorTransient;
      } else {
        category = FBSDKGraphRequestErrorRecoverable;
      }
      NSString *suggestion = dictionary[@"recovery_message"];
      NSArray<NSString *> *options = dictionary[@"recovery_options"];

      NSArray *validItems = [FBSDKTypeUtility dictionary:dictionary objectForKey:@"items" ofType:NSArray.class];
      for (NSDictionary<NSString *, id> *codeSubcodesDictionary in validItems) {
        NSDictionary<NSString *, id> *validCodeSubcodesDictionary = [FBSDKTypeUtility dictionaryValue:codeSubcodesDictionary];
        if (!validCodeSubcodesDictionary) {
          continue;
        }

        NSNumber *numericCode = [FBSDKTypeUtility dictionary:validCodeSubcodesDictionary objectForKey:@"code" ofType:NSNumber.class];
        NSString *code = numericCode.stringValue;
        if (!code) {
          return;
        }

        NSMutableDictionary<NSString *, id> *currentSubcodes = self->_configurationDictionary[code];
        if (!currentSubcodes) {
          currentSubcodes = [NSMutableDictionary dictionary];
          [FBSDKTypeUtility dictionary:self->_configurationDictionary setObject:currentSubcodes forKey:code];
        }

        NSArray *validSubcodes = [FBSDKTypeUtility dictionary:validCodeSubcodesDictionary objectForKey:@"subcodes" ofType:NSArray.class];
        if (validSubcodes.count > 0) {
          for (NSNumber *subcodeNumber in validSubcodes) {
            NSNumber *validSubcodeNumber = [FBSDKTypeUtility numberValue:subcodeNumber];
            if (validSubcodeNumber == nil) {
              continue;
            }
            [FBSDKTypeUtility dictionary:currentSubcodes setObject:[[FBSDKErrorRecoveryConfiguration alloc]
                                                                    initWithRecoveryDescription:suggestion
                                                                    optionDescriptions:options
                                                                    category:category
                                                                    recoveryActionName:action] forKey:validSubcodeNumber.stringValue];
          }
        } else {
          [FBSDKTypeUtility dictionary:currentSubcodes setObject:[[FBSDKErrorRecoveryConfiguration alloc]
                                                                  initWithRecoveryDescription:suggestion
                                                                  optionDescriptions:options
                                                                  category:category
                                                                  recoveryActionName:action] forKey:@"*"];
        }
      }
    }];
  }
}

#pragma mark - NSSecureCoding

+ (BOOL)supportsSecureCoding
{
  return YES;
}

- (instancetype)initWithCoder:(NSCoder *)decoder
{
  NSSet<Class> *classes = [NSSet setWithArray:@[
    NSDictionary.class,
    NSString.class,
    FBSDKErrorRecoveryConfiguration.class,
                           ]];

  NSDictionary<NSString *, id> *configurationDictionary = [decoder decodeObjectOfClasses:classes
                                                                                  forKey:FBSDKERRORCONFIGURATION_DICTIONARY_KEY];
  return [self initWithDictionary:configurationDictionary];
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
  [encoder encodeObject:_configurationDictionary forKey:FBSDKERRORCONFIGURATION_DICTIONARY_KEY];
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone
{
  return self;
}

@end
