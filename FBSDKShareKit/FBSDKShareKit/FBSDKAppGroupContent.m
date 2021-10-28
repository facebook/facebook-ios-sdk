/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "FBSDKAppGroupContent.h"

#if TARGET_OS_TV

NSString *NSStringFromFBSDKAppGroupPrivacy(AppGroupPrivacy privacy)
{
  return @"Not available for tvOS";
}

#else

 #import "FBSDKHasher.h"
 #import "FBSDKShareUtility.h"

 #define FBSDK_APP_GROUP_CONTENT_GROUP_DESCRIPTION_KEY @"groupDescription"
 #define FBSDK_APP_GROUP_CONTENT_NAME_KEY @"name"
 #define FBSDK_APP_GROUP_CONTENT_PRIVACY_KEY @"privacy"

NSString *NSStringFromFBSDKAppGroupPrivacy(FBSDKAppGroupPrivacy privacy)
{
  switch (privacy) {
    case FBSDKAppGroupPrivacyClosed: {
      return @"closed";
    }
    case FBSDKAppGroupPrivacyOpen: {
      return @"open";
    }
  }
}

@implementation FBSDKAppGroupContent

 #pragma mark - Equality

- (NSUInteger)hash
{
  NSUInteger subhashes[] = {
    _groupDescription.hash,
    _name.hash,
    _privacy,
  };
  return [FBSDKHasher hashWithIntegerArray:subhashes count:sizeof(subhashes) / sizeof(subhashes[0])];
}

- (BOOL)isEqual:(id)object
{
  if (self == object) {
    return YES;
  }
  if (![object isKindOfClass:FBSDKAppGroupContent.class]) {
    return NO;
  }
  return [self isEqualToAppGroupContent:(FBSDKAppGroupContent *)object];
}

- (BOOL)isEqualToAppGroupContent:(FBSDKAppGroupContent *)content
{
  return (content
    && (_privacy == content.privacy)
    && [_name isEqual:content.name]
    && [_groupDescription isEqual:content.groupDescription]);
}

 #pragma mark - NSCoding

+ (BOOL)supportsSecureCoding
{
  return YES;
}

- (instancetype)initWithCoder:(NSCoder *)decoder
{
  if ((self = [self init])) {
    _groupDescription = [decoder decodeObjectOfClass:NSString.class
                                              forKey:FBSDK_APP_GROUP_CONTENT_GROUP_DESCRIPTION_KEY];
    _name = [decoder decodeObjectOfClass:NSString.class forKey:FBSDK_APP_GROUP_CONTENT_PRIVACY_KEY];
    _privacy = [decoder decodeIntegerForKey:FBSDK_APP_GROUP_CONTENT_PRIVACY_KEY];
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
  [encoder encodeObject:_groupDescription forKey:FBSDK_APP_GROUP_CONTENT_GROUP_DESCRIPTION_KEY];
  [encoder encodeObject:_name forKey:FBSDK_APP_GROUP_CONTENT_NAME_KEY];
  [encoder encodeInteger:_privacy forKey:FBSDK_APP_GROUP_CONTENT_PRIVACY_KEY];
}

 #pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone
{
  FBSDKAppGroupContent *copy = [FBSDKAppGroupContent new];
  copy->_groupDescription = [_groupDescription copy];
  copy->_name = [_name copy];
  copy->_privacy = _privacy;
  return copy;
}

@end

#endif
