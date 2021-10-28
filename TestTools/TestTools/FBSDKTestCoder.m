/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "FBSDKTestCoder.h"

@implementation FBSDKTestCoder

- (instancetype)init
{
  if ((self = [super init])) {
    _encodedObject = [NSMutableDictionary dictionary];
    _decodedObject = [NSMutableDictionary dictionary];
  }

  return self;
}

- (void)encodeObject:(id)object forKey:(NSString *)key
{
  self.encodedObject[key] = object;
}

- (void)encodeBool:(BOOL)value forKey:(NSString *)key
{
  NSNumber *converted = [NSNumber numberWithBool:value];
  self.encodedObject[key] = converted;
}

- (void)encodeDouble:(double)value forKey:(NSString *)key
{
  NSNumber *converted = [NSNumber numberWithDouble:value];
  self.encodedObject[key] = converted;
}

- (void)encodeInteger:(NSInteger)value forKey:(NSString *)key
{
  NSNumber *converted = [NSNumber numberWithInteger:value];
  self.encodedObject[key] = converted;
}

- (nullable id)decodeObjectOfClass:(Class)aClass forKey:(NSString *)key
{
  self.decodedObject[key] = aClass;

  return nil;
}

- (nullable id)decodeObjectOfClasses:(NSSet<Class> *)classes forKey:(NSString *)key
{
  self.decodedObject[key] = classes;

  return nil;
}

- (nullable id)decodeObjectForKey:(NSString *)key
{
  self.decodedObject[key] = @"decodeObjectForKey";

  return nil;
}

- (BOOL)decodeBoolForKey:(NSString *)key
{
  self.decodedObject[key] = @"decodeBoolForKey";

  return YES;
}

- (double)decodeDoubleForKey:(NSString *)key
{
  self.decodedObject[key] = @"decodeDoubleForKey";

  return 1;
}

- (NSInteger)decodeIntegerForKey:(NSString *)key
{
  self.decodedObject[key] = @"decodeIntegerForKey";

  return 1;
}

@end
