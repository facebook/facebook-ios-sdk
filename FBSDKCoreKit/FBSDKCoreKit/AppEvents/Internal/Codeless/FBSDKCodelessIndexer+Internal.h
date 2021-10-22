/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !TARGET_OS_TV

#import <Foundation/Foundation.h>

// TODO: Can these all be forward decls?

#import "FBSDKAdvertiserIDProviding.h"
#import "FBSDKCodelessIndexer.h"
#import "FBSDKDataPersisting.h"
#import "FBSDKEnableable.h"
#import "FBSDKGraphRequestConnectionFactoryProtocol.h"
#import "FBSDKGraphRequestFactoryProtocol.h"
#import "FBSDKServerConfigurationProviding.h"
#import "FBSDKSettingsProtocol.h"
#import "FBSDKSwizzling.h"

NS_ASSUME_NONNULL_BEGIN

@interface FBSDKCodelessIndexer (Internal) <FBSDKEnableable>

+ (void)configureWithGraphRequestFactory:(id<FBSDKGraphRequestFactory>)graphRequestFactory
             serverConfigurationProvider:(id<FBSDKServerConfigurationProviding>)serverConfigurationProvider
                                   store:(id<FBSDKDataPersisting>)store
           graphRequestConnectionFactory:(id<FBSDKGraphRequestConnectionFactory>)graphRequestConnectionFactory
                                swizzler:(Class<FBSDKSwizzling>)swizzler
                                settings:(id<FBSDKSettings>)settings
                    advertiserIDProvider:(id<FBSDKAdvertiserIDProviding>)advertisingIDProvider;

@end

NS_ASSUME_NONNULL_END

#endif
