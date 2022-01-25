/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "FBSDKUnarchiverProvider.h"

#import "FBSDKObjectDecoder.h"

@implementation FBSDKUnarchiverProvider

+ (NSKeyedUnarchiver *)_unarchiverFor:(NSData *)data
{
  NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingFromData:data error:NULL];
  return unarchiver;
}

+ (id<FBSDKObjectDecoding>)createSecureUnarchiverFor:(NSData *)data
{
  NSKeyedUnarchiver *unarchiver = [FBSDKUnarchiverProvider _unarchiverFor:data];
  unarchiver.requiresSecureCoding = YES;
  return [[FBSDKObjectDecoder alloc]initWith:unarchiver];
}

+ (id<FBSDKObjectDecoding>)createInsecureUnarchiverFor:(NSData *)data
{
  NSKeyedUnarchiver *unarchiver = [FBSDKUnarchiverProvider _unarchiverFor:data];
  unarchiver.requiresSecureCoding = NO;
  return [[FBSDKObjectDecoder alloc]initWith:unarchiver];
}

@end
