/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !TARGET_OS_TV

#import "FBSDKSwitchContextContent.h"

#import <FBSDKCoreKit/FBSDKCoreKit.h>

#import <FacebookGamingServices/FacebookGamingServices-Swift.h>

#define FBSDK_APP_REQUEST_CONTENT_CONTEXT_TOKEN_KEY @"contextToken"

@interface FBSDKSwitchContextContent () <NSCopying, NSObject>
@end

@implementation FBSDKSwitchContextContent

- (instancetype)initDialogContentWithContextID:(NSString *)contextID;
{
  if ((self = [super init])) {
    self.contextTokenID = contextID;
  }
  return self;
}

#pragma mark - FBSDKSharingValidation

- (BOOL)validateWithError:(NSError *__autoreleasing *)errorRef
{
  BOOL hasContextToken = self.contextTokenID.length > 0;
  if (!hasContextToken) {
    if (errorRef != NULL) {
      NSString *message = @"The contextToken is required.";
      id<FBSDKErrorCreating> errorFactory = [FBSDKErrorFactory new];
      *errorRef = [errorFactory requiredArgumentErrorWithDomain:FBSDKErrorDomain
                                                           name:@"contextToken"
                                                        message:message
                                                underlyingError:nil];
    }
    return NO;
  }
  return YES;
}

#pragma mark - Equality

- (NSUInteger)hash
{
  NSUInteger subhashes[] = {
    self.contextTokenID.hash,
  };
  return [self hashWithIntegerArray:subhashes count:sizeof(subhashes) / sizeof(subhashes[0])];
}

// TODO - delete when we convert to Swift and can use Hashable
- (NSUInteger)hashWithIntegerArray:(NSUInteger *)values count:(NSUInteger)count
{
  if (count == 0) {
    return 0;
  }
  return values[0];
}

- (BOOL)isEqual:(id)object
{
  if (self == object) {
    return YES;
  }
  if (![object isKindOfClass:FBSDKSwitchContextContent.class]) {
    return NO;
  }
  FBSDKSwitchContextContent *content = object;
  return (content
    && [FBSDKInternalUtility.sharedUtility object:self.contextTokenID isEqualToObject:content.contextTokenID]);
}

#pragma mark - NSCoding

+ (BOOL)supportsSecureCoding
{
  return YES;
}

- (instancetype)initWithCoder:(NSCoder *)decoder
{
  if ((self = [self init])) {
    self.contextTokenID = [decoder decodeObjectOfClass:NSString.class forKey:FBSDK_APP_REQUEST_CONTENT_CONTEXT_TOKEN_KEY];
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
  [encoder encodeObject:self.contextTokenID forKey:FBSDK_APP_REQUEST_CONTENT_CONTEXT_TOKEN_KEY];
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone
{
  FBSDKSwitchContextContent *copy = [FBSDKSwitchContextContent new];
  copy.contextTokenID = [self.contextTokenID copy];
  return copy;
}

@end

#endif
