/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !TARGET_OS_TV

#import <Foundation/Foundation.h>

#import <FBSDKCoreKit/FBSDKGraphRequestFactoryProtocol.h>
#import <FBSDKCoreKit/FBSDKSettingsProtocol.h>

#import "FBSDKEventLogging.h"
#import "FBSDKEventProcessing.h"
#import "FBSDKFeatureExtracting.h"
#import "FBSDKServerConfigurationProviding.h"
#import "FBSDKSuggestedEventsIndexerProtocol.h"
#import "FBSDKSwizzling.h"

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(SuggestedEventsIndexer)
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
