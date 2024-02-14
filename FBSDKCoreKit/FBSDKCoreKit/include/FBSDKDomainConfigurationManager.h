/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */
#import <FBSDKCoreKit/FBSDKDomainConfigurationProviding.h>
#import <Foundation/Foundation.h>

@protocol FBSDKGraphRequestFactory;
@protocol FBSDKGraphRequestConnectionFactory;
@protocol FBSDKSettings;
@protocol FBSDKDataPersisting;

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(_DomainConfigurationManager)
@interface FBSDKDomainConfigurationManager : NSObject <FBSDKDomainConfigurationProviding>

+ (instancetype)sharedInstance;

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

@property (nullable, nonatomic) id<FBSDKGraphRequestFactory> graphRequestFactory;
@property (nullable, nonatomic) id<FBSDKGraphRequestConnectionFactory> graphRequestConnectionFactory;
@property (nullable, nonatomic) id<FBSDKSettings> settings;
@property (nullable, nonatomic) id<FBSDKDataPersisting> dataStore;

@end

NS_ASSUME_NONNULL_END
