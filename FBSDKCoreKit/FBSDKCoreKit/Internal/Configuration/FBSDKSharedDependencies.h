/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <Foundation/Foundation.h>

#if !TARGET_OS_TV
 #import <FBAEMKit/FBAEMKit.h>

 #import "FBSDKAEMReporterProtocol.h"
#endif

#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <FBSDKCoreKit_Basics/FBSDKCoreKit_Basics.h>

#import "FBSDKATEPublisherCreating.h"
#import "FBSDKAdvertiserIDProviding.h"
#import "FBSDKAppEventDropDetermining.h"
#import "FBSDKAppEventParametersExtracting.h"
#import "FBSDKAppEventsConfigurationProviding.h"
#import "FBSDKAppEventsParameterProcessing.h"
#import "FBSDKAppEventsReporter.h"
#import "FBSDKAppEventsStatePersisting.h"
#import "FBSDKAppEventsStateProviding.h"
#import "FBSDKAppLinkCreating.h"
#import "FBSDKAppLinkEventPosting.h"
#import "FBSDKAppLinkTargetCreating.h"
#import "FBSDKAppLinkURLCreating.h"
#import "FBSDKCodelessIndexing.h"
#import "FBSDKDataPersisting.h"
#import "FBSDKDeviceInformationProviding.h"
#import "FBSDKErrorConfigurationProviding.h"
#import "FBSDKErrorCreating.h"
#import "FBSDKErrorReporting.h"
#import "FBSDKEventLogging.h"
#import "FBSDKEventProcessing.h"
#import "FBSDKEventsProcessing.h"
#import "FBSDKFeatureDisabling.h"
#import "FBSDKFeatureExtracting.h"
#import "FBSDKGateKeeperManaging.h"
#import "FBSDKGraphRequestPiggybackManaging.h"
#import "FBSDKIntegrityParametersProcessorProvider.h"
#import "FBSDKInternalURLOpener.h"
#import "FBSDKMacCatalystDetermining.h"
#import "FBSDKMetadataIndexing.h"
#import "FBSDKNotificationProtocols.h"
#import "FBSDKOperatingSystemVersionComparing.h"
#import "FBSDKPaymentObserving.h"
#import "FBSDKRulesFromKeyProvider.h"
#import "FBSDKServerConfigurationProviding.h"
#import "FBSDKSourceApplicationTracking.h"
#import "FBSDKSuggestedEventsIndexerProtocol.h"
#import "FBSDKSwizzling.h"
#import "FBSDKTimeSpentRecording.h"
#import "FBSDKURLSessionProxyProviding.h"
#import "FBSDKUserDataPersisting.h"
#import "FBSDKUserIDProviding.h"
#import "FBSDKWebViewProviding.h"
#import "__FBSDKLoggerCreating.h"

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(SharedDependencies)
@interface FBSDKSharedDependencies : NSObject

@property (nonatomic, readonly) Class<FBSDKAccessTokenProviding, FBSDKAccessTokenSetting, FBSDKTokenStringProviding> accessTokenWallet;
@property (nonatomic, readonly) id<FBSDKAdvertiserIDProviding> advertiserIDProvider;
@property (nonatomic, readonly) id<FBSDKAppEventsConfigurationProviding> appEventsConfigurationProvider;
@property (nonatomic, readonly) id<FBSDKAppEventsStateProviding> appEventsStateProvider;
@property (nonatomic, readonly) id<FBSDKAppEventsStatePersisting> appEventsStateStore;
@property (nonatomic, readonly) id applicationActivationNotifier;
@property (nonatomic, readonly) id<FBSDKATEPublisherCreating> atePublisherFactory;
@property (nonatomic, readonly) Class<FBSDKAuthenticationTokenProviding, FBSDKAuthenticationTokenSetting> authenticationTokenWallet;
@property (nonatomic, readonly) id<FBSDKCrashHandler> crashHandler;
@property (nonatomic, readonly) id<FBSDKCrashObserving> crashObserver;
@property (nonatomic, readonly) id<FBSDKDataPersisting> defaultDataStore;
@property (nonatomic, readonly) id<FBSDKDeviceInformationProviding> deviceInformationProvider;
@property (nonatomic, readonly) id<FBSDKErrorConfigurationProviding> errorConfigurationProvider;
@property (nonatomic, readonly) id<FBSDKErrorCreating> errorFactory;
@property (nonatomic, readonly) id<FBSDKErrorReporting> errorReporter;
@property (nonatomic, readonly) id<FBSDKAppEventsParameterProcessing, FBSDKEventsProcessing> eventDeactivationManager;
@property (nonatomic, readonly) id<FBSDKEventLogging> eventLogger;
@property (nonatomic, readonly) id<FBSDKFeatureChecking, FBSDKFeatureDisabling> featureChecker;
@property (nonatomic, readonly) Class<FBSDKGateKeeperManaging> gateKeeperManager;
@property (nonatomic, readonly) id<FBSDKGraphRequestConnectionFactory> graphRequestConnectionFactory;
@property (nonatomic, readonly) id<FBSDKGraphRequestFactory> graphRequestFactory;
@property (nonatomic, readonly) id<FBSDKInfoDictionaryProviding> infoDictionaryProvider;
@property (nonatomic, readonly) Class<FBSDKLogging> logger;
@property (nonatomic, readonly) id<__FBSDKLoggerCreating> loggerFactory;
@property (nonatomic, readonly) id<FBSDKMacCatalystDetermining> macCatalystDeterminator;
@property (nonatomic, readonly) id<FBSDKOperatingSystemVersionComparing> operatingSystemVersionComparer;
@property (nonatomic, readonly) id<FBSDKPaymentObserving> paymentObserver;
@property (nonatomic, readonly) Class<FBSDKGraphRequestPiggybackManaging> piggybackManager;
@property (nonatomic, readonly) id<FBSDKAppEventsParameterProcessing, FBSDKEventsProcessing> restrictiveDataFilterManager;
@property (nonatomic, readonly) id<FBSDKServerConfigurationProviding> serverConfigurationProvider;
@property (nonatomic, readonly) id<FBSDKSettings> settings;
@property (nonatomic, readonly) id<FBSDKSourceApplicationTracking, FBSDKTimeSpentRecording> timeSpentRecorder;
@property (nonatomic, readonly) id<FBSDKTokenCaching> tokenCache;
@property (nonatomic, readonly) id<FBSDKURLSessionProxyProviding> urlSessionProxyFactory;
@property (nonatomic, readonly) id<FBSDKUserDataPersisting> userDataStore;

#if !TARGET_OS_TV

@property (nullable, nonatomic, readonly) id<FBAEMNetworking> aemNetworker;
@property (nullable, nonatomic, readonly) Class<FBSDKAEMReporter> aemReporter;
@property (nonatomic, readonly) id<FBSDKAppEventParametersExtracting> appEventParametersExtractor;
@property (nonatomic, readonly) id<FBSDKAppEventDropDetermining> appEventsDropDeterminer;
@property (nonatomic, readonly) id<FBSDKAppLinkEventPosting> appLinkEventPoster;
@property (nonatomic, readonly) id<FBSDKAppLinkCreating> appLinkFactory;
@property (nonatomic, readonly) id<FBSDKAppLinkResolving> appLinkResolver;
@property (nonatomic, readonly) id<FBSDKAppLinkTargetCreating> appLinkTargetFactory;
@property (nonatomic, readonly) id<FBSDKAppLinkURLCreating> appLinkURLFactory;
@property (nonatomic, readonly) Class<FBSDKCodelessIndexing> codelessIndexer;
@property (nonatomic, readonly) Class<FBSDKFileDataExtracting> dataExtractor;
@property (nonatomic, readonly) Class<FBSDKFeatureExtracting> featureExtractor;
@property (nonatomic, readonly) id<FBSDKFileManaging> fileManager;
@property (nonatomic, readonly) id<FBSDKInternalURLOpener> internalURLOpener;
@property (nonatomic, readonly) id<FBSDKInternalUtility> internalUtility;
@property (nonatomic, readonly) id<FBSDKMetadataIndexing> metadataIndexer;
@property (nonatomic, readonly) id<FBSDKEventProcessing, FBSDKIntegrityParametersProcessorProvider> modelManager;
@property (nonatomic, readonly) id<FBSDKNotificationPosting, FBSDKNotificationObserving> notificationCenter;
@property (nonatomic, readonly) Class<FBSDKProfileProviding> profileSetter;
@property (nonatomic, readonly) id<FBSDKRulesFromKeyProvider> rulesFromKeyProvider;
@property (nonatomic, readonly) id<FBSDKSessionProviding> sessionDataTaskProvider;
@property (nullable, nonatomic, readonly) id<FBSDKAppEventsReporter, FBSKAdNetworkReporting> skAdNetworkReporter;
@property (nonatomic, readonly) id<FBSDKSuggestedEventsIndexer> suggestedEventsIndexer;
@property (nonatomic, readonly) Class<FBSDKSwizzling> swizzler;
@property (nonatomic, readonly) id<FBSDKURLHosting> urlHoster;
@property (nonatomic, readonly) id<FBSDKUserIDProviding> userIDProvider;
@property (nonatomic, readonly) id<FBSDKWebViewProviding> webViewProvider;

#endif

- (instancetype)initWithAccessTokenWallet:(Class<FBSDKAccessTokenProviding, FBSDKAccessTokenSetting, FBSDKTokenStringProviding>)accessTokenWallet
                     advertiserIDProvider:(id<FBSDKAdvertiserIDProviding>)advertiserIDProvider
           appEventsConfigurationProvider:(id<FBSDKAppEventsConfigurationProviding>)appEventsConfigurationProvider
                   appEventsStateProvider:(id<FBSDKAppEventsStateProviding>)appEventsStateProvider
                      appEventsStateStore:(id<FBSDKAppEventsStatePersisting>)appEventsStateStore
            applicationActivationNotifier:(id)applicationActivationNotifier
                      atePublisherFactory:(id<FBSDKATEPublisherCreating>)atePublisherFactory
                authenticationTokenWallet:(Class<FBSDKAuthenticationTokenProviding, FBSDKAuthenticationTokenSetting>)authenticationTokenWallet
                             crashHandler:(id<FBSDKCrashHandler>)crashHandler
                            crashObserver:(id<FBSDKCrashObserving>)crashObserver
                         defaultDataStore:(id<FBSDKDataPersisting>)defaultDataStore
                deviceInformationProvider:(id<FBSDKDeviceInformationProviding>)deviceInformationProvider
               errorConfigurationProvider:(id<FBSDKErrorConfigurationProviding>)errorConfigurationProvider
                             errorFactory:(id<FBSDKErrorCreating>)errorFactory
                            errorReporter:(id<FBSDKErrorReporting>)errorReporter
                 eventDeactivationManager:(id<FBSDKAppEventsParameterProcessing, FBSDKEventsProcessing>)eventDeactivationManager
                              eventLogger:(id<FBSDKEventLogging>)eventLogger
                           featureChecker:(id<FBSDKFeatureChecking, FBSDKFeatureDisabling>)featureChecker
                        gateKeeperManager:(Class<FBSDKGateKeeperManaging>)gateKeeperManager
            graphRequestConnectionFactory:(id<FBSDKGraphRequestConnectionFactory>)graphRequestConnectionFactory
                      graphRequestFactory:(id<FBSDKGraphRequestFactory>)graphRequestFactory
                   infoDictionaryProvider:(id<FBSDKInfoDictionaryProviding>)infoDictionaryProvider
                                   logger:(Class<FBSDKLogging>)logger
                            loggerFactory:(id<__FBSDKLoggerCreating>)loggerFactory
                  macCatalystDeterminator:(id<FBSDKMacCatalystDetermining>)macCatalystDeterminator
           operatingSystemVersionComparer:(id<FBSDKOperatingSystemVersionComparing>)operatingSystemVersionComparer
                          paymentObserver:(id<FBSDKPaymentObserving>)paymentObserver
                         piggybackManager:(Class<FBSDKGraphRequestPiggybackManaging>)piggybackManager
             restrictiveDataFilterManager:(id<FBSDKAppEventsParameterProcessing, FBSDKEventsProcessing>)restrictiveDataFilterManager
              serverConfigurationProvider:(id<FBSDKServerConfigurationProviding>)serverConfigurationProvider
                                 settings:(id<FBSDKSettings>)settings
                        timeSpentRecorder:(id<FBSDKSourceApplicationTracking, FBSDKTimeSpentRecording>)timeSpentRecorder
                               tokenCache:(id<FBSDKTokenCaching>)tokenCache
                   urlSessionProxyFactory:(id<FBSDKURLSessionProxyProviding>)urlSessionProxyFactory
                            userDataStore:(id<FBSDKUserDataPersisting>)userDataStore
#if !TARGET_OS_TV
  // UNCRUSTIFY_FORMAT_OFF
                             aemNetworker:(nullable id<FBAEMNetworking>)aemNetworker
                              aemReporter:(nullable Class<FBSDKAEMReporter>)aemReporter
              appEventParametersExtractor:(id<FBSDKAppEventParametersExtracting>)appEventParametersExtractor
                  appEventsDropDeterminer:(id<FBSDKAppEventDropDetermining>)appEventsDropDeterminer
                       appLinkEventPoster:(id<FBSDKAppLinkEventPosting>)appLinkEventPoster
                           appLinkFactory:(id<FBSDKAppLinkCreating>)appLinkFactory
                          appLinkResolver:(id<FBSDKAppLinkResolving>)appLinkResolver
                     appLinkTargetFactory:(id<FBSDKAppLinkTargetCreating>)appLinkTargetFactory
                        appLinkURLFactory:(id<FBSDKAppLinkURLCreating>)appLinkURLFactory
                          codelessIndexer:(Class<FBSDKCodelessIndexing>)codelessIndexer
                            dataExtractor:(Class<FBSDKFileDataExtracting>)dataExtractor
                         featureExtractor:(Class<FBSDKFeatureExtracting>)featureExtractor
                              fileManager:(id<FBSDKFileManaging>)fileManager
                        internalURLOpener:(id<FBSDKInternalURLOpener>)internalURLOpener
                          internalUtility:(id<FBSDKInternalUtility>)internalUtility
                          metadataIndexer:(id<FBSDKMetadataIndexing>)metadataIndexer
                             modelManager:(id<FBSDKEventProcessing, FBSDKIntegrityParametersProcessorProvider>)modelManager
                       notificationCenter:(id<FBSDKNotificationPosting, FBSDKNotificationObserving>)notificationCenter
                            profileSetter:(Class<FBSDKProfileProviding>)profileSetter
                     rulesFromKeyProvider:(id<FBSDKRulesFromKeyProvider>)rulesFromKeyProvider
                  sessionDataTaskProvider:(id<FBSDKSessionProviding>)sessionDataTaskProvider
                      skAdNetworkReporter:(nullable id <FBSDKAppEventsReporter, FBSKAdNetworkReporting>) skAdNetworkReporter
                   suggestedEventsIndexer:(id<FBSDKSuggestedEventsIndexer>)suggestedEventsIndexer
                                 swizzler:(Class<FBSDKSwizzling>)swizzler
                                urlHoster:(id<FBSDKURLHosting>)urlHoster
                           userIDProvider:(id<FBSDKUserIDProviding>)userIDProvider
                          webViewProvider:(id<FBSDKWebViewProviding>)webViewProvider
  // UNCRUSTIFY_FORMAT_ON
#endif
;

@end

NS_ASSUME_NONNULL_END
