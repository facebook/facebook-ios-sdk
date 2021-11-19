/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "TargetConditionals.h"

#if !TARGET_OS_TV

 #import "FBSDKChooseContextContent.h"

 #import <FBSDKCoreKit/FBSDKCoreKit.h>

 #import <FacebookGamingServices/FacebookGamingServices-Swift.h>

@interface FBSDKChooseContextContent () <NSCopying, NSObject>
@end

@implementation FBSDKChooseContextContent

- (BOOL)validateWithError:(NSError *__autoreleasing *)errorRef
{
  if (!self.minParticipants && !self.maxParticipants) {
    return YES;
  }

  BOOL minimumGreaterThanMaximum = self.minParticipants > self.maxParticipants;
  if (minimumGreaterThanMaximum && self.maxParticipants != 0) {
    if (errorRef != NULL) {
      NSString *message = @"The minimum size cannot be greater than the maximum size";
      *errorRef = [FBSDKError requiredArgumentErrorWithDomain:FBSDKErrorDomain
                                                         name:@"minParticipants"
                                                      message:message];
    }
    return NO;
  }
  return YES;
}

+ (NSString *)filtersNameForFilters:(FBSDKChooseContextFilter)filter
{
  switch (filter) {
    case FBSDKChooseContextFilterNewContextOnly: {
      return @"NEW_CONTEXT_ONLY";
    }
    case FBSDKChooseContextFilterExistingChallenges: {
      return @"INCLUDE_EXISTING_CHALLENGES";
    }
    case FBSDKChooseContextFilterNewPlayersOnly: {
      return @"NEW_PLAYERS_ONLY";
    }
    case FBSDKChooseContextFilterNone:
    default: {
      return @"NO_FILTER";
    }
  }
}

 #pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone
{
  FBSDKChooseContextContent *copy = [FBSDKChooseContextContent new];
  copy.filter = self.filter;
  copy.minParticipants = self.minParticipants;
  copy.maxParticipants = self.maxParticipants;
  return copy;
}

@end
#endif
