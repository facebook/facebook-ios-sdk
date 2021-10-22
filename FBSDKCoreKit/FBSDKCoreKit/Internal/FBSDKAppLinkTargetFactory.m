/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !TARGET_OS_TV

#import "FBSDKAppLinkTargetFactory.h"

#import "FBSDKAppLinkTarget+Internal.h"

NS_ASSUME_NONNULL_BEGIN

@implementation FBSDKAppLinkTargetFactory : NSObject

- (id<FBSDKAppLinkTarget>)createAppLinkTargetWithURL:(nullable NSURL *)url
                                          appStoreId:(nullable NSString *)appStoreId
                                             appName:(NSString *)appName
{
  return [FBSDKAppLinkTarget appLinkTargetWithURL:url appStoreId:appStoreId appName:appName];
}

@end

NS_ASSUME_NONNULL_END

#endif
