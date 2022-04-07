/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !TARGET_OS_TV

#import "FBSDKAppLinkCreating.h"
#import "FBSDKAppLinkEventPosting.h"
#import "FBSDKAppLinkTargetCreating.h"
#import "FBSDKAppLinkURL.h"
#import "FBSDKSettings.h"
#import "FBSDKURL.h"

NS_ASSUME_NONNULL_BEGIN

@interface FBSDKURL (Internal) <FBSDKAppLinkURL>

@property (class, nullable, nonatomic, readonly) id<FBSDKSettings> settings;
@property (class, nullable, nonatomic, readonly) id<FBSDKAppLinkCreating> appLinkFactory;
@property (class, nullable, nonatomic, readonly) id<FBSDKAppLinkTargetCreating> appLinkTargetFactory;
@property (class, nullable, nonatomic, readonly) id<FBSDKAppLinkEventPosting> appLinkEventPoster;

// UNCRUSTIFY_FORMAT_OFF
+ (void)configureWithSettings:(id<FBSDKSettings>)settings
               appLinkFactory:(id<FBSDKAppLinkCreating>)appLinkFactory
         appLinkTargetFactory:(id<FBSDKAppLinkTargetCreating>)appLinkTargetFactory
           appLinkEventPoster:(id<FBSDKAppLinkEventPosting>)appLinkEventPoster
NS_SWIFT_NAME(configure(settings:appLinkFactory:appLinkTargetFactory:appLinkEventPoster:));
// UNCRUSTIFY_FORMAT_ON

+ (FBSDKURL *)URLForRenderBackToReferrerBarURL:(NSURL *)url;

#if DEBUG
+ (void)reset;
#endif

@end

NS_ASSUME_NONNULL_END

#endif
