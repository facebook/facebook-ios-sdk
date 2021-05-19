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

#import "FBSDKUserAgeRange.h"

#import "FBSDKCoreKitBasicsImport.h"
#import "FBSDKMath.h"

NSString *const FBSDKUserAgeRangeMinCodingKey = @"FBSDKUserAgeRangeMinCodingKey";
NSString *const FBSDKUserAgeRangeMaxCodingKey = @"FBSDKUserAgeRangeMaxCodingKey";

@implementation FBSDKUserAgeRange

- (instancetype)initMin:(NSNumber *)min
                    max:(NSNumber *)max
{
  if (self = [super init]) {
    _min = min;
    _max = max;
  }

  return self;
}

+ (instancetype)ageRangeFromDictionary:(NSDictionary *)dictionary
{
  if (![FBSDKTypeUtility dictionaryValue:dictionary]) {
    return nil;
  }

  NSNumber *min = [FBSDKTypeUtility numberValue:dictionary[@"min"]];
  NSNumber *max = [FBSDKTypeUtility numberValue:dictionary[@"max"]];

  if ((min == nil && max == nil)
      || (min != nil && min.longValue < 0)
      || (max != nil && max.longValue < 0)
      || (min != nil && max != nil && min.longValue >= max.longValue)) {
    return nil;
  }

  return [[FBSDKUserAgeRange alloc] initMin:min max:max];
}

#pragma mark - Equality

- (NSUInteger)hash
{
  NSUInteger subhashes[] = {
    _min.hash,
    _max.hash,
  };
  return [FBSDKMath hashWithIntegerArray:subhashes count:sizeof(subhashes) / sizeof(subhashes[0])];
}

- (BOOL)isEqual:(id)object
{
  if (self == object) {
    return YES;
  }
  if (![object isKindOfClass:[FBSDKUserAgeRange class]]) {
    return NO;
  }
  return [self isEqualToUserAgeRange:object];
}

- (BOOL)isEqualToUserAgeRange:(FBSDKUserAgeRange *)ageRange
{
  return (_max == ageRange.max) && (_min == ageRange.min);
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone
{
  // we're immutable.
  return self;
}

#pragma mark NSCoding
+ (BOOL)supportsSecureCoding
{
  return YES;
}

- (void)encodeWithCoder:(nonnull NSCoder *)coder
{
  [coder encodeObject:_min forKey:FBSDKUserAgeRangeMinCodingKey];
  [coder encodeObject:_max forKey:FBSDKUserAgeRangeMaxCodingKey];
}

- (instancetype)initWithCoder:(nonnull NSCoder *)coder
{
  NSNumber *min = [coder decodeObjectOfClass:NSNumber.class forKey:FBSDKUserAgeRangeMinCodingKey];
  NSNumber *max = [coder decodeObjectOfClass:NSNumber.class forKey:FBSDKUserAgeRangeMaxCodingKey];

  return [self initMin:min max:max];
}

@end
