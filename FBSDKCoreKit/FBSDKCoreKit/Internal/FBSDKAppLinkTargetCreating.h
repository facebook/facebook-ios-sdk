/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !TARGET_OS_TV

#import "FBSDKAppLinkTargetProtocol.h"

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(AppLinkTargetCreating)
@protocol FBSDKAppLinkTargetCreating

// UNCRUSTIFY_FORMAT_OFF
- (id<FBSDKAppLinkTarget>)createAppLinkTargetWithURL:(nullable NSURL *)url
                                          appStoreId:(nullable NSString *)appStoreId
                                             appName:(NSString *)appName
NS_SWIFT_NAME(createAppLinkTarget(url:appStoreId:appName:));
// UNCRUSTIFY_FORMAT_ON

@end

NS_ASSUME_NONNULL_END

#endif
