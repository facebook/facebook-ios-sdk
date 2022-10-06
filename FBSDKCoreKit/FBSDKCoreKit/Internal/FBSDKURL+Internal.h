/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !TARGET_OS_TV

#import <FBSDKCoreKit/FBSDKCoreKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface FBSDKURL (Internal) 

@property (class, nullable, nonatomic, readonly) id<FBSDKSettings> settings;
@property (class, nullable, nonatomic, readonly) id<FBSDKAppLinkCreating> appLinkFactory;
@property (class, nullable, nonatomic, readonly) id<FBSDKAppLinkTargetCreating> appLinkTargetFactory;
@property (class, nullable, nonatomic, readonly) id<FBSDKAppLinkEventPosting> appLinkEventPoster;

+ (FBSDKURL *)URLForRenderBackToReferrerBarURL:(NSURL *)url;

#if DEBUG
+ (void)reset;
#endif

@end

NS_ASSUME_NONNULL_END

#endif
