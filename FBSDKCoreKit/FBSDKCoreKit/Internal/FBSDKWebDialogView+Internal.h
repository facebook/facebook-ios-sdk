/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !TARGET_OS_TV

#import <FBSDKCoreKit/FBSDKCoreKit.h>

#import "FBSDKInternalURLOpener.h"
#import "FBSDKWebViewProviding.h"

NS_ASSUME_NONNULL_BEGIN

@interface FBSDKWebDialogView (Internal)

@property (class, nullable, nonatomic) id<FBSDKWebViewProviding> webViewProvider;
@property (class, nullable, nonatomic) id<FBSDKInternalURLOpener> urlOpener;
@property (class, nullable, nonatomic) id<FBSDKErrorCreating> errorFactory;

// UNCRUSTIFY_FORMAT_OFF
+ (void)configureWithWebViewProvider:(id<FBSDKWebViewProviding>)webViewProvider
                           urlOpener:(id<FBSDKInternalURLOpener>)urlOpener
                        errorFactory:(id<FBSDKErrorCreating>)errorFactory
NS_SWIFT_NAME(configure(webViewProvider:urlOpener:errorFactory:));
// UNCRUSTIFY_FORMAT_ON

@end

NS_ASSUME_NONNULL_END

#endif
