/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <Foundation/Foundation.h>

#import <FBSDKCoreKit/FBSDKAccessToken.h>
#import <FBSDKCoreKit/FBSDKTokenCaching.h>

NS_ASSUME_NONNULL_BEGIN

@protocol FBSDKSettings;
@protocol FBSDKKeychainStoreProviding;

NS_SWIFT_NAME(TokenCache)
@interface FBSDKTokenCache : NSObject <FBSDKTokenCaching>

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

- (instancetype)initWithSettings:(id<FBSDKSettings>)settings
            keychainStoreFactory:(id<FBSDKKeychainStoreProviding>)keychainStoreFactory;

@end

NS_ASSUME_NONNULL_END
