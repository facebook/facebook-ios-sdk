/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "FBSDKDynamicFrameworkLoaderProxy.h"

#import "FBSDKDynamicFrameworkLoader.h"

@implementation FBSDKDynamicFrameworkLoaderProxy
+ (CFTypeRef)loadkSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
{
  return [FBSDKDynamicFrameworkLoader loadkSecAttrAccessibleAfterFirstUnlockThisDeviceOnly];
}

@end
