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

#import "FBSDKLocation.h"

#import "FBSDKCoreKitBasicsImport.h"
#import "FBSDKMath.h"

NSString *const FBSDKLocationIdCodingKey = @"FBSDKLocationIdCodingKey";
NSString *const FBSDKLocationNameCodingKey = @"FBSDKLocationNameCodingKey";

@implementation FBSDKLocation

- (instancetype)initWithId:(NSString *)id
                      name:(NSString *)name
{
  if (self = [super init]) {
    _id = id;
    _name = name;
  }

  return self;
}

+ (instancetype)locationFromDictionary:(NSDictionary *)dictionary
{
  if (![FBSDKTypeUtility dictionaryValue:dictionary]) {
    return nil;
  }

  NSString *id = [FBSDKTypeUtility stringValueOrNil:dictionary[@"id"]];
  NSString *name = [FBSDKTypeUtility stringValueOrNil:dictionary[@"name"]];

  if (id == nil || name == nil) {
    return nil;
  }

  return [[FBSDKLocation alloc] initWithId:id name:name];
}

#pragma mark - Equality

- (NSUInteger)hash
{
  NSUInteger subhashes[] = {
    _id.hash,
    _name.hash,
  };
  return [FBSDKMath hashWithIntegerArray:subhashes count:sizeof(subhashes) / sizeof(subhashes[0])];
}

- (BOOL)isEqual:(id)object
{
  if (self == object) {
    return YES;
  }
  if (![object isKindOfClass:[FBSDKLocation class]]) {
    return NO;
  }
  return [self isEqualToLocation:object];
}

- (BOOL)isEqualToLocation:(FBSDKLocation *)location
{
  return [_id isEqualToString:location.id] && [_name isEqualToString:location.name];
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
  [coder encodeObject:_id forKey:FBSDKLocationIdCodingKey];
  [coder encodeObject:_name forKey:FBSDKLocationNameCodingKey];
}

- (instancetype)initWithCoder:(nonnull NSCoder *)coder
{
  NSString *id = [coder decodeObjectOfClass:NSString.class forKey:FBSDKLocationIdCodingKey];
  NSString *name = [coder decodeObjectOfClass:NSString.class forKey:FBSDKLocationNameCodingKey];

  return [self initWithId:id name:name];
}

@end
