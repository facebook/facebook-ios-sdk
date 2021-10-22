/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "FBSDKObjectDecoder.h"

@interface FBSDKObjectDecoder ()
@property (nonatomic, strong) NSKeyedUnarchiver *unarchiver;
@end

@implementation FBSDKObjectDecoder

- (instancetype)initWith:(NSKeyedUnarchiver *)unarchiver
{
  self = [super init];
  if (self) {
    self.unarchiver = unarchiver;
  }
  return self;
}

- (id)decodeObjectOfClass:(Class)aClass forKey:(NSString *)key
{
  return [self.unarchiver decodeObjectOfClass:aClass forKey:key];
}

- (id)decodeObjectOfClasses:(NSSet<Class> *)classes forKey:(NSString *)key
{
  return [self.unarchiver decodeObjectOfClasses:classes forKey:key];
}

@end
