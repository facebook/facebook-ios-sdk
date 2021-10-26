/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <Foundation/Foundation.h>

@protocol FBSDKGateKeeperManaging;
@protocol FBSDKAppEventsConfigurationProviding;
@protocol FBSDKServerConfigurationProviding;
@protocol FBSDKGraphRequestFactory;
@protocol FBSDKFeatureChecking;
@protocol FBSDKDataPersisting;
@protocol FBSDKLogging;
@protocol FBSDKSettings;
@protocol FBSDKPaymentObserving;
@protocol FBSDKTimeSpentRecordingCreating;
@protocol FBSDKAppEventsStatePersisting;
@protocol FBSDKAppEventsParameterProcessing;
@protocol FBSDKAppEventsParameterProcessing;
@protocol FBSDKAtePublisherCreating;
@protocol FBSDKAppEventsStateProviding;
@protocol FBSDKSwizzling;
@protocol FBSDKAdvertiserIDProviding;
@protocol FBSDKUserDataPersisting;

#if !TARGET_OS_TV
@protocol FBSDKEventProcessing;
@protocol FBSDKMetadataIndexing;
@protocol FBSDKAppEventsReporter;
@protocol FBSDKEnableable;
#endif

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(AppEventsConfiguring)
@protocol FBSDKAppEventsConfiguring

- (void)   configureWithGateKeeperManager:(Class<FBSDKGateKeeperManaging>)gateKeeperManager
           appEventsConfigurationProvider:(Class<FBSDKAppEventsConfigurationProviding>)appEventsConfigurationProvider
              serverConfigurationProvider:(id<FBSDKServerConfigurationProviding>)serverConfigurationProvider
                      graphRequestFactory:(id<FBSDKGraphRequestFactory>)graphRequestFactory
                           featureChecker:(id<FBSDKFeatureChecking>)featureChecker
                                    store:(id<FBSDKDataPersisting>)store
                                   logger:(Class<FBSDKLogging>)logger
                                 settings:(id<FBSDKSettings>)settings
                          paymentObserver:(id<FBSDKPaymentObserving>)paymentObserver
                 timeSpentRecorderFactory:(id<FBSDKTimeSpentRecordingCreating>)timeSpentRecorderFactory
                      appEventsStateStore:(id<FBSDKAppEventsStatePersisting>)appEventsStateStore
      eventDeactivationParameterProcessor:(id<FBSDKAppEventsParameterProcessing>)eventDeactivationParameterProcessor
  restrictiveDataFilterParameterProcessor:(id<FBSDKAppEventsParameterProcessing>)restrictiveDataFilterParameterProcessor
                      atePublisherFactory:(id<FBSDKAtePublisherCreating>)atePublisherFactory
                   appEventsStateProvider:(id<FBSDKAppEventsStateProviding>)appEventsStateProvider
                                 swizzler:(Class<FBSDKSwizzling>)swizzler
                     advertiserIDProvider:(id<FBSDKAdvertiserIDProviding>)advertiserIDProvider
                            userDataStore:(id<FBSDKUserDataPersisting>)userDataStore;

#if !TARGET_OS_TV

- (void)configureNonTVComponentsWithOnDeviceMLModelManager:(id<FBSDKEventProcessing>)modelManager
                                           metadataIndexer:(id<FBSDKMetadataIndexing>)metadataIndexer
                                       skAdNetworkReporter:(nullable id<FBSDKAppEventsReporter>)skAdNetworkReporter
                                           codelessIndexer:(Class<FBSDKEnableable>)codelessIndexer;

#endif

@end

NS_ASSUME_NONNULL_END
