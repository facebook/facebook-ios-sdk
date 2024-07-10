/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <Foundation/Foundation.h>

@protocol FBSDKAEMReporter;
@protocol FBSDKGateKeeperManaging;
@protocol FBSDKAppEventsConfigurationProviding;
@protocol FBSDKSourceApplicationTracking;
@protocol FBSDKServerConfigurationProviding;
@protocol FBSDKGraphRequestFactory;
@protocol FBSDKFeatureChecking;
@protocol FBSDKDataPersisting;
@protocol FBSDKInternalUtility;
@protocol FBSDKLogging;
@protocol FBSDKSettings;
@protocol FBSDKPaymentObserving;
@protocol FBSDKTimeSpentRecording;
@protocol FBSDKAppEventsStatePersisting;
@protocol FBSDKAppEventsParameterProcessing;
@protocol FBSDKAppEventsParameterProcessing;
@protocol FBSDKATEPublisherCreating;
@protocol FBSDKAppEventsStateProviding;
@protocol FBSDKAdvertiserIDProviding;
@protocol FBSDKUserDataPersisting;
@protocol FBSDKLoggingNotifying;
@protocol FBSDKAppEventsUtility;
@protocol FBSDKAppEventDropDetermining;
@protocol FBSDKCAPIReporter;
@protocol FBSDKAppEventParametersExtracting;
@protocol FBSDKMACARuleMatching;
@protocol FBSDKEventsProcessing;
#if !TARGET_OS_TV
@protocol FBSDKEventProcessing;
@protocol FBSDKMetadataIndexing;
@protocol FBSDKAppEventsReporter;
@protocol FBSDKCodelessIndexing;
@protocol FBSDKSwizzling;
#endif

NS_ASSUME_NONNULL_BEGIN

/**
 Internal type exposed to facilitate transition to Swift.
 API Subject to change or removal without warning. Do not use.

 @warning INTERNAL - DO NOT USE
 */
NS_SWIFT_NAME(_AppEventsConfiguring)
@protocol FBSDKAppEventsConfiguring

- (void)   configureWithGateKeeperManager:(Class<FBSDKGateKeeperManaging>)gateKeeperManager
           appEventsConfigurationProvider:(id<FBSDKAppEventsConfigurationProviding>)appEventsConfigurationProvider
              serverConfigurationProvider:(id<FBSDKServerConfigurationProviding>)serverConfigurationProvider
                      graphRequestFactory:(id<FBSDKGraphRequestFactory>)graphRequestFactory
                           featureChecker:(id<FBSDKFeatureChecking>)featureChecker
                         primaryDataStore:(id<FBSDKDataPersisting>)primaryDataStore
                                   logger:(Class<FBSDKLogging>)logger
                                 settings:(id<FBSDKSettings>)settings
                          paymentObserver:(id<FBSDKPaymentObserving>)paymentObserver
                        timeSpentRecorder:(id<FBSDKSourceApplicationTracking, FBSDKTimeSpentRecording>)timeSpentRecorder
                      appEventsStateStore:(id<FBSDKAppEventsStatePersisting>)appEventsStateStore
      eventDeactivationParameterProcessor:(id<FBSDKAppEventsParameterProcessing>)eventDeactivationParameterProcessor
  restrictiveDataFilterParameterProcessor:(id<FBSDKAppEventsParameterProcessing>)restrictiveDataFilterParameterProcessor
                      atePublisherFactory:(id<FBSDKATEPublisherCreating>)atePublisherFactory
                   appEventsStateProvider:(id<FBSDKAppEventsStateProviding>)appEventsStateProvider
                     advertiserIDProvider:(id<FBSDKAdvertiserIDProviding>)advertiserIDProvider
                            userDataStore:(id<FBSDKUserDataPersisting>)userDataStore
                         appEventsUtility:(id<FBSDKAppEventDropDetermining, FBSDKAppEventParametersExtracting, FBSDKAppEventsUtility, FBSDKLoggingNotifying>)appEventsUtility
                          internalUtility:(id<FBSDKInternalUtility>)internalUtility
                             capiReporter:(id<FBSDKCAPIReporter>)capiReporter
                     protectedModeManager:(id<FBSDKAppEventsParameterProcessing>)protectedModeManager
                  macaRuleMatchingManager:(id<FBSDKMACARuleMatching>)macaRuleMatchingManager
                   blocklistEventsManager:(nonnull id<FBSDKEventsProcessing>)blocklistEventsManager
                   redactedEventsManager:(nonnull id<FBSDKEventsProcessing>)redactedEventsManager
                  sensitiveParamsManager:(nonnull id<FBSDKAppEventsParameterProcessing>)sensitiveParamsManager
NS_SWIFT_NAME(configure(gateKeeperManager:appEventsConfigurationProvider:serverConfigurationProvider:graphRequestFactory:featureChecker:primaryDataStore:logger:settings:paymentObserver:timeSpentRecorder:appEventsStateStore:eventDeactivationParameterProcessor:restrictiveDataFilterParameterProcessor:atePublisherFactory:appEventsStateProvider:advertiserIDProvider:userDataStore:appEventsUtility:internalUtility:capiReporter:protectedModeManager:macaRuleMatchingManager:blocklistEventsManager:redactedEventsManager:sensitiveParamsManager:));

#if !TARGET_OS_TV

// UNCRUSTIFY_FORMAT_OFF
- (void)configureNonTVComponentsWithOnDeviceMLModelManager:(id<FBSDKEventProcessing>)modelManager
                                           metadataIndexer:(id<FBSDKMetadataIndexing>)metadataIndexer
                                       skAdNetworkReporter:(nullable id<FBSDKAppEventsReporter>)skAdNetworkReporter
                                       skAdNetworkReporterV2:(nullable id<FBSDKAppEventsReporter>)skAdNetworkReporterV2
                                           codelessIndexer:(Class<FBSDKCodelessIndexing>)codelessIndexer
                                                  swizzler:(Class<FBSDKSwizzling>)swizzler
                                               aemReporter:(Class<FBSDKAEMReporter>)aemReporter
NS_SWIFT_NAME(configureNonTVComponents(onDeviceMLModelManager:metadataIndexer:skAdNetworkReporter:skAdNetworkReporterV2:codelessIndexer:swizzler:aemReporter:));
// UNCRUSTIFY_FORMAT_ON

#endif

@end

NS_ASSUME_NONNULL_END
