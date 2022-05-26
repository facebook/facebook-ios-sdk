/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !TARGET_OS_TV

#import <Foundation/Foundation.h>

#import <FBSDKLoginKit/FBSDKLoginCompletionParametersBlock.h>

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(LoginCompleting)
@protocol FBSDKLoginCompleting

/**
 Invoke \p handler with the login parameters derived from the authentication result.
 See the implementing class's documentation for whether it completes synchronously or asynchronously.
 */
- (void)completeLoginWithHandler:(FBSDKLoginCompletionParametersBlock)handler;

/**
 Invoke \p handler with the login parameters derived from the authentication result.
 See the implementing class's documentation for whether it completes synchronously or asynchronously.
 */
- (void)completeLoginWithHandler:(FBSDKLoginCompletionParametersBlock)handler
                           nonce:(nullable NSString *)nonce
                    codeVerifier:(nullable NSString *)codeVerifier;

@end

NS_ASSUME_NONNULL_END

#endif
