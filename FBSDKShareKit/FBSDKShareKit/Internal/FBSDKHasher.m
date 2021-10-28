/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "FBSDKHasher.h"

@implementation FBSDKHasher

+ (NSUInteger)hashWithInteger:(NSUInteger)value1 andInteger:(NSUInteger)value2
{
  return [self hashWithLong:(((unsigned long long)value1) << 32 | value2)];
}

+ (NSUInteger)hashWithIntegerArray:(NSUInteger *)values count:(NSUInteger)count
{
  if (count == 0) {
    return 0;
  }
  NSUInteger hash = values[0];
  for (NSUInteger i = 1; i < count; ++i) {
    hash = [self hashWithInteger:hash andInteger:values[i]];
  }
  return hash;
}

+ (NSUInteger)hashWithLong:(unsigned long long)value
{
  value = (~value) + (value << 18); // key = (key << 18) - key - 1;
  value ^= (value >> 31);
  value *= 21; // key = (key + (key << 2)) + (key << 4);
  value ^= (value >> 11);
  value += (value << 6);
  value ^= (value >> 22);
  return (NSUInteger)value;
}

+ (NSUInteger)hashWithInteger:(NSUInteger)value
{
  NSUInteger hash = (NSUInteger)value;
#if !TARGET_RT_64_BIT
  hash = ~hash + (hash << 15); // key = (key << 15) - key - 1;
  hash ^= (hash >> 12);
  hash += (hash << 2);
  hash ^= (hash >> 4);
  hash *= 2057; // key = (key + (key << 3)) + (key << 11);
  hash ^= (hash >> 16);
#else
  hash += ~hash + (hash << 21); // key = (key << 21) - key - 1;
  hash ^= (hash >> 24);
  hash = (hash + (hash << 3)) + (hash << 8);
  hash ^= (hash >> 14);
  hash = (hash + (hash << 2)) + (hash << 4); // key * 21
  hash ^= (hash >> 28);
  hash += (hash << 31);
#endif
  return hash;
}

@end
