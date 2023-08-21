/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !TARGET_OS_TV

#import <FBSDKCoreKit/FBSDKSuggestedEventsIndexerProtocol.h>
#import <Foundation/Foundation.h>

@protocol FBSDKGraphRequestFactory;
@protocol FBSDKServerConfigurationProviding;
@protocol FBSDKSwizzling;
@protocol FBSDKSettings;
@protocol FBSDKEventLogging;
@protocol FBSDKFeatureExtracting;
@protocol FBSDKEventProcessing;

NS_ASSUME_NONNULL_BEGIN

/**
 Internal type exposed to facilitate transition to Swift.
 API Subject to change or removal without warning. Do not use.

 @warning INTERNAL - DO NOT USE
 */
NS_SWIFT_NAME(_SuggestedEventsIndexer)
@interface FBSDKSuggestedEventsIndexer : NSObject <FBSDKSuggestedEventsIndexer>

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

- (instancetype)initWithGraphRequestFactory:(id<FBSDKGraphRequestFactory>)graphRequestFactory
                serverConfigurationProvider:(id<FBSDKServerConfigurationProviding>)serverConfigurationProvider
                                   swizzler:(Class<FBSDKSwizzling>)swizzler
                                   settings:(id<FBSDKSettings>)settings
                                eventLogger:(id<FBSDKEventLogging>)eventLogger
                           featureExtractor:(Class<FBSDKFeatureExtracting>)featureExtractor
                             eventProcessor:(id<FBSDKEventProcessing>)eventProcessor
  NS_DESIGNATED_INITIALIZER;

- (void)enable;

@end

NS_ASSUME_NONNULL_END

#endif
