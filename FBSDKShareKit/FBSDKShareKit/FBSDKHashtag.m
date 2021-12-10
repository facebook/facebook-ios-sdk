/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "FBSDKHashtag.h"

#define FBSDK_HASHTAG_STRING_KEY @"hashtag"

static NSRegularExpression *HashtagRegularExpression()
{
  static NSRegularExpression *hashtagRegularExpression = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    hashtagRegularExpression = [[NSRegularExpression alloc] initWithPattern:@"^#\\w+$" options:0 error:NULL];
  });
  return hashtagRegularExpression;
}

@implementation FBSDKHashtag

#pragma mark - Class Methods

+ (instancetype)hashtagWithString:(NSString *)hashtagString
{
  FBSDKHashtag *hashtag = [self new];
  hashtag.stringRepresentation = hashtagString;
  return hashtag;
}

#pragma mark - Properties

- (NSString *)description
{
  if (self.valid) {
    return _stringRepresentation;
  } else {
    return [NSString stringWithFormat:@"Invalid hashtag '%@'", _stringRepresentation];
  }
}

- (BOOL)isValid
{
  if (_stringRepresentation == nil) {
    return NO;
  }
  NSRange fullString = NSMakeRange(0, _stringRepresentation.length);
  NSRegularExpression *hashtagRegularExpression = HashtagRegularExpression();
  NSUInteger numberOfMatches = [hashtagRegularExpression numberOfMatchesInString:_stringRepresentation
                                                                         options:0
                                                                           range:fullString];
  return numberOfMatches > 0;
}

#pragma mark - Equality

- (NSUInteger)hash
{
  return _stringRepresentation.hash;
}

- (BOOL)isEqual:(id)object
{
  if (self == object) {
    return YES;
  }
  if (![object isKindOfClass:FBSDKHashtag.class]) {
    return NO;
  }
  return [self isEqualToHashtag:(FBSDKHashtag *)object];
}

- (BOOL)isEqualToHashtag:(FBSDKHashtag *)hashtag
{
  return (hashtag
    && [FBSDKInternalUtility.sharedUtility object:_stringRepresentation isEqualToObject:hashtag.stringRepresentation]);
}

#pragma mark - NSCoding

+ (BOOL)supportsSecureCoding
{
  return YES;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
  if ((self = [self init])) {
    _stringRepresentation = [aDecoder decodeObjectOfClass:NSString.class forKey:FBSDK_HASHTAG_STRING_KEY];
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
  [aCoder encodeObject:_stringRepresentation forKey:FBSDK_HASHTAG_STRING_KEY];
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone
{
  FBSDKHashtag *copy = [FBSDKHashtag new];
  copy.stringRepresentation = [_stringRepresentation copy];
  return copy;
}

@end
