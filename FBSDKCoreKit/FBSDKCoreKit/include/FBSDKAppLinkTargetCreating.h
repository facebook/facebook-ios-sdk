/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !TARGET_OS_TV

#import <FBSDKCoreKit/FBSDKAppLinkTargetProtocol.h>

NS_ASSUME_NONNULL_BEGIN

/**
 Internal type exposed to facilitate transition to Swift.
 API Subject to change or removal without warning. Do not use.

 @warning INTERNAL - DO NOT USE
 */
NS_SWIFT_NAME(_AppLinkTargetCreating)
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
