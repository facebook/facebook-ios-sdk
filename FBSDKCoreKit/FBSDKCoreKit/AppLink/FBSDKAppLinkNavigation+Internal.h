/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !TARGET_OS_TV

#import <FBSDKCoreKit/FBSDKAppLinkNavigation.h>
#import <FBSDKCoreKit/FBSDKAppLinkResolving.h>
#import <FBSDKCoreKit/FBSDKSettingsProtocol.h>

#import "FBSDKAppLinkEventPosting.h"
#import "FBSDKInternalURLOpener.h"

NS_ASSUME_NONNULL_BEGIN

@interface FBSDKAppLinkNavigation (Internal)

@property (class, nullable, nonatomic) id<FBSDKSettings> settings;
@property (class, nullable, nonatomic) id<FBSDKInternalURLOpener> urlOpener;
@property (class, nullable, nonatomic) id<FBSDKAppLinkEventPosting> appLinkEventPoster;
@property (class, nullable, nonatomic) id<FBSDKAppLinkResolving> appLinkResolver;

+ (void)configureWithSettings:(id<FBSDKSettings>)settings
                    urlOpener:(id<FBSDKInternalURLOpener>)urlOpener
           appLinkEventPoster:(id<FBSDKAppLinkEventPosting>)appLinkEventPoster
              appLinkResolver:(id<FBSDKAppLinkResolving>)appLinkResolver;

@end

NS_ASSUME_NONNULL_END

#endif
