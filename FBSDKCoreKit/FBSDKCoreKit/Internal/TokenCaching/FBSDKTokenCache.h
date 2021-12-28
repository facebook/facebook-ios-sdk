/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
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
@protocol FBSDKKeychainStore;

FOUNDATION_EXPORT NSString *const DefaultKeychainServicePrefix;

NS_SWIFT_NAME(TokenCache)
@interface FBSDKTokenCache : NSObject <FBSDKTokenCaching>

@property (nonatomic) id<FBSDKSettings> settings;
@property (nonatomic) id<FBSDKKeychainStore> keychainStore;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

- (instancetype)initWithSettings:(id<FBSDKSettings>)settings
                   keychainStore:(id<FBSDKKeychainStore>)keychainStore;

@end

NS_ASSUME_NONNULL_END
