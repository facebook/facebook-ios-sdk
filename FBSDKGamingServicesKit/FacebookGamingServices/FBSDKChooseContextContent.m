// Copyright (c) 2014-present, Facebook, Inc. All rights reserved.
//
// You are hereby granted a non-exclusive, worldwide, royalty-free license to use,
// copy, modify, and distribute this software in source code or binary form for use
// in connection with the web services and APIs provided by Facebook.
// Copyright (c) 2014-present, Facebook, Inc. All rights reserved.
//
// You are hereby granted a non-exclusive, worldwide, royalty-free license to use,
// copy, modify, and distribute this software in source code or binary form for use
// in connection with the web services and APIs provided by Facebook.
//
// As with any software that integrates with the Facebook platform, your use of
// this software is subject to the Facebook Developer Principles and Policies
// [http://developers.facebook.com/policy/]. This copyright notice shall be
// included in all copies or substantial portions of the software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
// FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
// COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
// IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
// CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

#import "TargetConditionals.h"

#if !TARGET_OS_TV

 #import "FBSDKChooseContextContent.h"

 #import <FBSDKCoreKit/FBSDKCoreKit.h>

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
