/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <Foundation/Foundation.h>
#import <FBSDKCoreKit/FBSDKDomainConfigurationProviding.h>
#import <FBSDKCoreKit/FBSDKGraphRequest.h>
#import <FBSDKCoreKit/FBSDKGraphRequestMetadata.h>

NS_ASSUME_NONNULL_BEGIN

/**
 Internal type exposed to facilitate transition to Swift.
 API Subject to change or removal without warning. Do not use.

 @warning INTERNAL - DO NOT USE
 */
NS_SWIFT_NAME(_DomainHandler)
@interface FBSDKDomainHandler : NSObject

+ (instancetype)sharedInstance;

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

- (void)configureWithGraphRequestFactory:(id<FBSDKDomainConfigurationProviding>)domainConfigurationProvider
                                settings:(id<FBSDKSettings>)settings
                               dataStore:(id<FBSDKDataPersisting>)dataStore
                     graphRequestFactory:(id<FBSDKGraphRequestFactory>)graphRequestFactory
           graphRequestConnectionFactory:(id<FBSDKGraphRequestConnectionFactory>)graphRequestConnectionFactory
  NS_SWIFT_NAME(configure(domainConfigurationProvider:settings:dataStore:graphRequestFactory:graphRequestConnectionFactory:));

- (void)loadDomainConfigurationWithCompletionBlock:(nullable FBSDKDomainConfigurationBlock)completionBlock;

/**
 Internal method exposed to facilitate transition to Swift.
 API Subject to change or removal without warning. Do not use.

 @warning INTERNAL - DO NOT USE
 */
- (NSString *)getURLPrefixForSingleRequest:(id<FBSDKGraphRequest>)request
               isAdvertiserTrackingEnabled:(BOOL)isATTOptIn;

/**
 Internal method exposed to facilitate transition to Swift.
 API Subject to change or removal without warning. Do not use.

 @warning INTERNAL - DO NOT USE
 */
- (NSString *)getURLPrefixForBatchRequest:(NSArray<FBSDKGraphRequestMetadata *> *)requestsMetaData
              isAdvertiserTrackingEnabled:(BOOL)isATTOptIn;

/**
 @method
 
 This method determines if the current authentication token is for the gaming domain
 @return a BOOL indicating  if the current authentication token is for the gaming domain
 */
+ (BOOL)isAuthenticatedForGamingDomain;

+ (NSString *)getCleanedGraphPathFromRequest:(id<FBSDKGraphRequest>)request;
- (nullable NSString *)getATTScopeEndpointForGraphPath:(NSString *)graphPath;
- (BOOL)isDomainHandlingEnabled;

@end

NS_ASSUME_NONNULL_END
