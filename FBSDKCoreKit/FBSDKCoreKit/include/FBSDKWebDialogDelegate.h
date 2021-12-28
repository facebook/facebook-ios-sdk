/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !TARGET_OS_TV

#import <Foundation/Foundation.h>

#import <FBSDKCoreKit/FBSDKWebDialog.h>

@class FBSDKWebDialog;

NS_ASSUME_NONNULL_BEGIN

/**
 Internal Type exposed to facilitate transition to Swift.
 API Subject to change or removal without warning. Do not use.

 @warning INTERNAL - DO NOT USE
 */
NS_SWIFT_NAME(WebDialogDelegate)
@protocol FBSDKWebDialogDelegate

/**
 Internal Type exposed to facilitate transition to Swift.
 API Subject to change or removal without warning. Do not use.

 @warning INTERNAL - DO NOT USE
 */
- (void)webDialog:(FBSDKWebDialog *)webDialog didCompleteWithResults:(NSDictionary<NSString *, id> *)results;

/**
 Internal Type exposed to facilitate transition to Swift.
 API Subject to change or removal without warning. Do not use.

 @warning INTERNAL - DO NOT USE
 */
- (void)webDialog:(FBSDKWebDialog *)webDialog didFailWithError:(NSError *)error;

/**
 Internal Type exposed to facilitate transition to Swift.
 API Subject to change or removal without warning. Do not use.

 @warning INTERNAL - DO NOT USE
 */
- (void)webDialogDidCancel:(FBSDKWebDialog *)webDialog;

@end

NS_ASSUME_NONNULL_END

#endif
