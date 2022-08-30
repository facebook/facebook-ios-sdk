/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !TARGET_OS_TV

#import <FBSDKCoreKit/FBSDKWebView.h>
#import <Foundation/Foundation.h>

/**
 Internal Type exposed to facilitate transition to Swift.
 API Subject to change or removal without warning. Do not use.

 @warning INTERNAL - DO NOT USE
 */

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(_WebViewProviding)
@protocol FBSDKWebViewProviding

- (id<FBSDKWebView>)createWebViewWithFrame:(CGRect)frame
NS_SWIFT_NAME(createWebView(frame:));

@end

NS_ASSUME_NONNULL_END

#endif
