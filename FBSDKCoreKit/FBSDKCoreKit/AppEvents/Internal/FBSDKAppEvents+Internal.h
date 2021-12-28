/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <UIKit/UIApplication.h>

#import <FBSDKCoreKit/FBSDKCoreKit.h>

#import "FBSDKAEMReporterProtocol.h"
#import "FBSDKAppEventDropDetermining.h"
#import "FBSDKAppEventParametersExtracting.h"
#import "FBSDKAppEventsConfiguring.h"
#import "FBSDKAppEventsUtilityProtocol.h"
#import "FBSDKApplicationActivating.h"
#import "FBSDKApplicationLifecycleObserving.h"
#import "FBSDKApplicationStateSetting.h"
#import "FBSDKEventLogging.h"
#import "FBSDKEventsProcessing.h"
#import "FBSDKIntegrityParametersProcessorProvider.h"
#import "FBSDKLoggingNotifying.h"
#import "FBSDKMetadataIndexing.h"
#import "FBSDKSourceApplicationTracking.h"
#import "FBSDKTimeSpentRecording.h"
#import "FBSDKUserIDProviding.h"

NS_ASSUME_NONNULL_BEGIN

// Internally known event parameter values

FOUNDATION_EXPORT NSString *const FBSDKAppEventsDialogOutcomeValue_Completed;
FOUNDATION_EXPORT NSString *const FBSDKAppEventsDialogOutcomeValue_Failed;

@interface FBSDKAppEvents (Internal) <
  FBSDKAppEventsConfiguring,
  FBSDKApplicationActivating,
  FBSDKApplicationLifecycleObserving,
  FBSDKApplicationStateSetting,
  FBSDKEventLogging,
  FBSDKSourceApplicationTracking,
  FBSDKUserIDProviding
>

// Dependencies

@property (nullable, nonatomic) Class<FBSDKGateKeeperManaging> gateKeeperManager;
@property (nullable, nonatomic) id<FBSDKAppEventsConfigurationProviding> appEventsConfigurationProvider;
@property (nullable, nonatomic) id<FBSDKServerConfigurationProviding> serverConfigurationProvider;
@property (nullable, nonatomic) id<FBSDKGraphRequestFactory> graphRequestFactory;
@property (nullable, nonatomic) id<FBSDKFeatureChecking> featureChecker;
@property (nullable, nonatomic) id<FBSDKDataPersisting> primaryDataStore;
@property (nullable, nonatomic) Class<FBSDKLogging> logger;
@property (nullable, nonatomic) id<FBSDKSettings> settings;
@property (nullable, nonatomic) id<FBSDKPaymentObserving> paymentObserver;
@property (nullable, nonatomic) id<FBSDKSourceApplicationTracking, FBSDKTimeSpentRecording> timeSpentRecorder;
@property (nullable, nonatomic) id<FBSDKAppEventsStatePersisting> appEventsStateStore;
@property (nullable, nonatomic) id<FBSDKAppEventsParameterProcessing, FBSDKEventsProcessing> eventDeactivationParameterProcessor;
@property (nullable, nonatomic) id<FBSDKAppEventsParameterProcessing, FBSDKEventsProcessing> restrictiveDataFilterParameterProcessor;
@property (nullable, nonatomic) id<FBSDKATEPublisherCreating> atePublisherFactory;
@property (nullable, nonatomic) id<FBSDKAppEventsStateProviding> appEventsStateProvider;
@property (nullable, nonatomic) id<FBSDKAdvertiserIDProviding> advertiserIDProvider;
@property (nullable, nonatomic) id<FBSDKUserDataPersisting> userDataStore;
@property (nullable, nonatomic) id<FBSDKAppEventDropDetermining, FBSDKAppEventParametersExtracting, FBSDKAppEventsUtility, FBSDKLoggingNotifying> appEventsUtility;
@property (nullable, nonatomic) id<FBSDKInternalUtility> internalUtility;

#if !TARGET_OS_TV
@property (nullable, nonatomic) id<FBSDKEventProcessing, FBSDKIntegrityParametersProcessorProvider> onDeviceMLModelManager;
@property (nullable, nonatomic) id<FBSDKMetadataIndexing> metadataIndexer;
@property (nullable, nonatomic) id<FBSDKAppEventsReporter> skAdNetworkReporter;
@property (nullable, nonatomic) Class<FBSDKCodelessIndexing> codelessIndexer;
@property (nullable, nonatomic) Class<FBSDKSwizzling> swizzler;
@property (nullable, nonatomic) Class<FBSDKAEMReporter> aemReporter;
#endif

@end

NS_ASSUME_NONNULL_END
