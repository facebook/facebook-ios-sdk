/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <Foundation/Foundation.h>
#import <FBSDKCoreKit/FBSDKDomainConfiguration.h>

@protocol FBSDKGraphRequestFactory;
@protocol FBSDKGraphRequestConnectionFactory;
@protocol FBSDKSettings;
@protocol FBSDKDataPersisting;

NS_ASSUME_NONNULL_BEGIN

/**
 Internal type exposed to facilitate transition to Swift.
 API Subject to change or removal without warning. Do not use.

 @warning INTERNAL - DO NOT USE
 */
NS_SWIFT_NAME(_DomainConfigurationBlock)
typedef void (^FBSDKDomainConfigurationBlock)(void);

/**
 Internal type exposed to facilitate transition to Swift.
 API Subject to change or removal without warning. Do not use.

 @warning INTERNAL - DO NOT USE
 */
NS_SWIFT_NAME(_DomainConfigurationProviding)
@protocol FBSDKDomainConfigurationProviding

- (FBSDKDomainConfiguration *)cachedDomainConfiguration;

// UNCRUSTIFY_FORMAT_OFF
- (void)configureWithSettings:(id<FBSDKSettings>)settings
                    dataStore:(id<FBSDKDataPersisting>)dataStore
          graphRequestFactory:(id<FBSDKGraphRequestFactory>)graphRequestFactory
graphRequestConnectionFactory:(id<FBSDKGraphRequestConnectionFactory>)graphRequestConnectionFactory
NS_SWIFT_NAME(configure(settings:dataStore:graphRequestFactory:graphRequestConnectionFactory:));
// UNCRUSTIFY_FORMAT_ON

- (void)loadDomainConfigurationWithCompletionBlock:(nullable FBSDKDomainConfigurationBlock)completionBlock;

- (void)processInvalidDomainsIfNeeded:(NSSet<NSString *> *)domainSet;

@end

NS_ASSUME_NONNULL_END
