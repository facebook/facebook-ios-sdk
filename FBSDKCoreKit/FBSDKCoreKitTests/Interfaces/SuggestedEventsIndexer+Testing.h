/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "FBSDKSuggestedEventsIndexer.h"

@protocol FBSDKGraphRequestFactory;
@protocol FBSDKServerConfigurationProviding;
@protocol FBSDKFeatureExtracting;

NS_ASSUME_NONNULL_BEGIN

@interface FBSDKSuggestedEventsIndexer (Testing)

@property (nonatomic, readonly) id<FBSDKGraphRequestFactory> graphRequestFactory;
@property (nonatomic, readonly) id<FBSDKServerConfigurationProviding> serverConfigurationProvider;
@property (nonatomic, readonly) Class<FBSDKSwizzling> swizzler;
@property (nonatomic, readonly) id<FBSDKSettings> settings;
@property (nonatomic, readonly) id<FBSDKEventLogging> eventLogger;
@property (nonatomic, readonly) Class<FBSDKFeatureExtracting> featureExtractor;
@property (nullable, nonatomic, weak) id<FBSDKEventProcessing> eventProcessor;
@property (nonatomic, readonly) NSSet<NSString *> *optInEvents;
@property (nonatomic, readonly) NSSet<NSString *> *unconfirmedEvents;

+ (void)reset;

// UNCRUSTIFY_FORMAT_OFF
- (instancetype)initWithGraphRequestFactory:(id<FBSDKGraphRequestFactory>)graphRequestFactory
                serverConfigurationProvider:(id<FBSDKServerConfigurationProviding>)serverConfigurationProvider
                                   swizzler:(Class<FBSDKSwizzling>)swizzler
                                   settings:(id<FBSDKSettings>)settings
                                eventLogger:(id<FBSDKEventLogging>)eventLogger
                           featureExtractor:(Class<FBSDKFeatureExtracting>)featureExtractor
                             eventProcessor:(id<FBSDKEventProcessing>)eventProcessor
NS_SWIFT_NAME(init(graphRequestFactory:serverConfigurationProvider:swizzler:settings:eventLogger:featureExtractor:eventProcessor:));
// UNCRUSTIFY_FORMAT_ON

- (void)logSuggestedEvent:(FBSDKAppEventName)event
                     text:(NSString *)text
             denseFeature:(nullable NSString *)denseFeature;
- (void)predictEventWithUIResponder:(UIResponder *)uiResponder
                               text:(NSString *)text;
- (void)handleView:(UIView *)view
      withDelegate:(nullable id)delegate;
- (void)matchSubviewsIn:(nullable UIView *)view;

@end

NS_ASSUME_NONNULL_END
