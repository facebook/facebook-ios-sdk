/*
 * Copyright (c) Facebook, Inc. and its affiliates.
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

#if !TARGET_OS_TV
@protocol FBSDKEventProcessing;
@protocol FBSDKMetadataIndexing;
@protocol FBSDKAppEventsReporter;
@protocol FBSDKCodelessIndexing;
@protocol FBSDKSwizzling;
#endif

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(AppEventsConfiguring)
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
                            userDataStore:(id<FBSDKUserDataPersisting>)userDataStore;

#if !TARGET_OS_TV

- (void)configureNonTVComponentsWithOnDeviceMLModelManager:(id<FBSDKEventProcessing>)modelManager
                                           metadataIndexer:(id<FBSDKMetadataIndexing>)metadataIndexer
                                       skAdNetworkReporter:(nullable id<FBSDKAppEventsReporter>)skAdNetworkReporter
                                           codelessIndexer:(Class<FBSDKCodelessIndexing>)codelessIndexer
                                                  swizzler:(Class<FBSDKSwizzling>)swizzler
                                               aemReporter:(Class<FBSDKAEMReporter>)aemReporter;

#endif

@end

NS_ASSUME_NONNULL_END
