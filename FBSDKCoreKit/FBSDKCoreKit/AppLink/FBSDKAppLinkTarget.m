/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !TARGET_OS_TV

#import "FBSDKAppLinkTarget.h"

@interface FBSDKAppLinkTarget ()

@property (nonatomic, strong) NSURL *URL;
@property (nonatomic, copy) NSString *appStoreId;
@property (nonatomic, copy) NSString *appName;

@end

@implementation FBSDKAppLinkTarget

+ (instancetype)appLinkTargetWithURL:(nullable NSURL *)url
                          appStoreId:(nullable NSString *)appStoreId
                             appName:(NSString *)appName
{
  FBSDKAppLinkTarget *target = [self new];
  target.URL = url;
  target.appStoreId = appStoreId;
  target.appName = appName;
  return target;
}

@end

#endif
