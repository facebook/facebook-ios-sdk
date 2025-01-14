/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <UIKit/UIApplication.h>

#import <FBSDKCoreKit/FBSDKCoreKit.h>

#import "FBSDKEventLogging.h"

NS_ASSUME_NONNULL_BEGIN

// Internally known event parameter values

FOUNDATION_EXPORT NSString *const FBSDKAppEventsDialogOutcomeValue_Completed;
FOUNDATION_EXPORT NSString *const FBSDKAppEventsDialogOutcomeValue_Failed;

@interface FBSDKAppEvents (Internal)

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
@property (nullable, nonatomic) id<FBSDKAppEventsParameterProcessing> protectedModeManager;
@property (nullable, nonatomic) id<FBSDKMACARuleMatching> bannedParamsManager;
@property (nullable, nonatomic) id<FBSDKMACARuleMatching> stdParamEnforcementManager;
@property (nullable, nonatomic) id<FBSDKMACARuleMatching> macaRuleMatchingManager;
@property (nullable, nonatomic) id<FBSDKEventsProcessing> blocklistEventsManager;
@property (nullable, nonatomic) id<FBSDKEventsProcessing> redactedEventsManager;
@property (nullable, nonatomic) id<FBSDKAppEventsParameterProcessing> sensitiveParamsManager;
@property (nullable, nonatomic) id<FBSDKATEPublisherCreating> atePublisherFactory;
@property (nullable, nonatomic) id<FBSDKAppEventsStateProviding> appEventsStateProvider;
@property (nullable, nonatomic) id<FBSDKAdvertiserIDProviding> advertiserIDProvider;
@property (nullable, nonatomic) id<FBSDKUserDataPersisting> userDataStore;
@property (nullable, nonatomic) id<FBSDKAppEventDropDetermining, FBSDKAppEventParametersExtracting, FBSDKAppEventsUtility, FBSDKLoggingNotifying> appEventsUtility;
@property (nullable, nonatomic) id<FBSDKInternalUtility> internalUtility;
@property (nullable, nonatomic) id<FBSDKTransactionObserving> transactionObserver;
@property (nullable, nonatomic) id<FBSDKIAPFailedTransactionLoggingCreating> failedTransactionLoggingFactory;
@property (nullable, nonatomic) id<FBSDKIAPDedupeProcessing> iapDedupeProcessor;
@property (nullable, nonatomic) id<FBSDKIAPTransactionCaching> iapTransactionCache;

#if !TARGET_OS_TV
@property (nullable, nonatomic) id<FBSDKEventProcessing, FBSDKIntegrityParametersProcessorProvider> onDeviceMLModelManager;
@property (nullable, nonatomic) id<FBSDKMetadataIndexing> metadataIndexer;
@property (nullable, nonatomic) id<FBSDKAppEventsReporter> skAdNetworkReporter;
@property (nullable, nonatomic) id<FBSDKAppEventsReporter> skAdNetworkReporterV2;
@property (nullable, nonatomic) Class<FBSDKCodelessIndexing> codelessIndexer;
@property (nullable, nonatomic) Class<FBSDKSwizzling> swizzler;
@property (nullable, nonatomic) Class<FBSDKAEMReporter> aemReporter;
#endif

@end

NS_ASSUME_NONNULL_END
