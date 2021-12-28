/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "FBSDKCoreKitTests-Swift.h"

@interface ObjCTestObject ()
@property (nonatomic) NSString *a;
@end

@implementation ObjCTestObject

- (instancetype)init
{
  if ((self = [super init])) {
    _a = @"BLAH";
  }
  return self;
}

@end
