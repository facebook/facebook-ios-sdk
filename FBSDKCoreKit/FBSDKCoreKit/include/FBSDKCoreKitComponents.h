/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <Foundation/Foundation.h>

#if !TARGET_OS_TV
 #import <FBAEMKit/FBAEMKit.h>
 #import <FBSDKCoreKit/FBSDKAEMReporterProtocol.h>
#endif

#import <FBSDKCoreKit_Basics/FBSDKCoreKit_Basics.h>

#import <FBSDKCoreKit/FBSDKAccessTokenProviding.h>
#import <FBSDKCoreKit/FBSDKAdvertiserIDProviding.h>
#import <FBSDKCoreKit/FBSDKAppEventDropDetermining.h>
#import <FBSDKCoreKit/FBSDKAppEventParametersExtracting.h>
#import <FBSDKCoreKit/FBSDKAppEventsConfigurationProviding.h>
#import <FBSDKCoreKit/FBSDKAppEventsConfiguring.h>
#import <FBSDKCoreKit/FBSDKAppEventsParameterProcessing.h>
#import <FBSDKCoreKit/FBSDKAppEventsReporter.h>
#import <FBSDKCoreKit/FBSDKAppEventsStatePersisting.h>
#import <FBSDKCoreKit/FBSDKAppEventsStateProviding.h>
#import <FBSDKCoreKit/FBSDKApplicationActivating.h>
#import <FBSDKCoreKit/FBSDKApplicationLifecycleObserving.h>
#import <FBSDKCoreKit/FBSDKApplicationStateSetting.h>
#import <FBSDKCoreKit/FBSDKAppLinkCreating.h>
#import <FBSDKCoreKit/FBSDKAppLinkEventPosting.h>
#import <FBSDKCoreKit/FBSDKAppLinkProtocol.h>
#import <FBSDKCoreKit/FBSDKAppLinkResolving.h>
#import <FBSDKCoreKit/FBSDKAppLinkTargetCreating.h>
#import <FBSDKCoreKit/FBSDKAppLinkURLCreating.h>
#import <FBSDKCoreKit/FBSDKATEPublisherCreating.h>
#import <FBSDKCoreKit/FBSDKAuthenticationTokenProviding.h>
#import <FBSDKCoreKit/FBSDKBackgroundEventLogging.h>
#import <FBSDKCoreKit/FBSDKCodelessIndexing.h>
#import <FBSDKCoreKit/FBSDKDeviceInformationProviding.h>
#import <FBSDKCoreKit/FBSDKDialogConfigurationMapBuilding.h>
#import <FBSDKCoreKit/FBSDKErrorConfigurationProviding.h>
#import <FBSDKCoreKit/FBSDKErrorCreating.h>
#import <FBSDKCoreKit/FBSDKErrorReporting.h>
#import <FBSDKCoreKit/FBSDKEventLogging.h>
#import <FBSDKCoreKit/FBSDKEventProcessing.h>
#import <FBSDKCoreKit/FBSDKEventsProcessing.h>
#import <FBSDKCoreKit/FBSDKFeatureDisabling.h>
#import <FBSDKCoreKit/FBSDKFeatureExtracting.h>
#import <FBSDKCoreKit/FBSDKGateKeeperManaging.h>
#import <FBSDKCoreKit/FBSDKGraphRequestConnectionFactoryProtocol.h>
#import <FBSDKCoreKit/FBSDKGraphRequestPiggybackManaging.h>
#import <FBSDKCoreKit/FBSDKImpressionLoggerFactoryProtocol.h>
#import <FBSDKCoreKit/FBSDKIntegrityParametersProcessorProvider.h>
#import <FBSDKCoreKit/FBSDKInternalURLOpener.h>
#import <FBSDKCoreKit/FBSDKMacCatalystDetermining.h>
#import <FBSDKCoreKit/FBSDKMetadataIndexing.h>
#import <FBSDKCoreKit/FBSDKOperatingSystemVersionComparing.h>
#import <FBSDKCoreKit/FBSDKPaymentObserving.h>
#import <FBSDKCoreKit/FBSDKProfileProtocols.h>
#import <FBSDKCoreKit/FBSDKRulesFromKeyProvider.h>
#import <FBSDKCoreKit/FBSDKServerConfigurationProviding.h>
#import <FBSDKCoreKit/FBSDKSettingsLogging.h>
#import <FBSDKCoreKit/FBSDKSourceApplicationTracking.h>
#import <FBSDKCoreKit/FBSDKSuggestedEventsIndexerProtocol.h>
#import <FBSDKCoreKit/FBSDKSwizzling.h>
#import <FBSDKCoreKit/FBSDKTimeSpentRecording.h>
#import <FBSDKCoreKit/FBSDKTokenStringProviding.h>
#import <FBSDKCoreKit/FBSDKURLHosting.h>
#import <FBSDKCoreKit/FBSDKURLSessionProxyProviding.h>
#import <FBSDKCoreKit/FBSDKUserDataPersisting.h>
#import <FBSDKCoreKit/FBSDKUserIDProviding.h>
#import <FBSDKCoreKit/FBSDKWebViewProviding.h>
#import <FBSDKCoreKit/_FBSDKNotificationPosting.h>
#import <FBSDKCoreKit/__FBSDKLoggerCreating.h>

@protocol FBSDKCAPIReporter;
@protocol _FBSDKAccessTokenExpiring;

NS_ASSUME_NONNULL_BEGIN

/**
 Internal type exposed to facilitate transition to Swift.
 API Subject to change or removal without warning. Do not use.

 @warning INTERNAL - DO NOT USE
 */
NS_SWIFT_NAME(_CoreKitComponents)
@interface FBSDKCoreKitComponents : NSObject

@property (class, nonatomic, readonly) FBSDKCoreKitComponents *defaultComponents
NS_SWIFT_NAME(default);

@property (nonatomic, readonly) id<_FBSDKAccessTokenExpiring> accessTokenExpirer;
@property (nonatomic, readonly) Class<FBSDKAccessTokenProviding, FBSDKTokenStringProviding> accessTokenWallet;
@property (nonatomic, readonly) id<FBSDKAdvertiserIDProviding> advertiserIDProvider;
@property (nonatomic, readonly) id<FBSDKSourceApplicationTracking, FBSDKAppEventsConfiguring, FBSDKApplicationLifecycleObserving, FBSDKApplicationActivating, FBSDKApplicationStateSetting, FBSDKEventLogging> appEvents;
@property (nonatomic, readonly) id<FBSDKAppEventsConfigurationProviding> appEventsConfigurationProvider;
@property (nonatomic, readonly) id<FBSDKAppEventsStateProviding> appEventsStateProvider;
@property (nonatomic, readonly) id<FBSDKAppEventsStatePersisting> appEventsStateStore;
@property (nullable, nonatomic) id<FBSDKAppEventDropDetermining, FBSDKAppEventParametersExtracting, FBSDKAppEventsUtility, FBSDKLoggingNotifying> appEventsUtility;
@property (nonatomic, readonly) id (^getApplicationActivationNotifier)(void);
@property (nonatomic, readonly) id<FBSDKATEPublisherCreating> atePublisherFactory;
@property (nonatomic, readonly) Class<FBSDKAuthenticationTokenProviding> authenticationTokenWallet;
@property (nonatomic, readonly) id<FBSDKCrashHandler> crashHandler;
@property (nonatomic, readonly) id<FBSDKCrashObserving> crashObserver;
@property (nonatomic, readonly) id<FBSDKDataPersisting> defaultDataStore;
@property (nonatomic, readonly) id<FBSDKDeviceInformationProviding> deviceInformationProvider;
@property (nonatomic, readonly) id<FBSDKErrorConfigurationProviding> errorConfigurationProvider;
@property (nonatomic, readonly) id<FBSDKErrorCreating> errorFactory;
@property (nonatomic, readonly) id<FBSDKErrorReporting> errorReporter;
@property (nonatomic, readonly) id<FBSDKAppEventsParameterProcessing, FBSDKEventsProcessing> eventDeactivationManager;
@property (nonatomic, readonly) id<FBSDKEventLogging> eventLogger;
@property (nonatomic, readonly) id<FBSDKDialogConfigurationMapBuilding> dialogConfigurationMapBuilder;
@property (nonatomic, readonly) id<FBSDKFeatureChecking, FBSDKFeatureDisabling> featureChecker;
@property (nonatomic, readonly) Class<FBSDKGateKeeperManaging> gateKeeperManager;
@property (nonatomic, readonly) id<FBSDKGraphRequestConnectionFactory> graphRequestConnectionFactory;
@property (nonatomic, readonly) id<FBSDKGraphRequestFactory> graphRequestFactory;
@property (nonatomic, readonly) id<FBSDKImpressionLoggerFactory> impressionLoggerFactory;
@property (nonatomic, readonly) id<FBSDKInfoDictionaryProviding> infoDictionaryProvider;
@property (nonatomic, readonly) id<FBSDKInternalUtility> internalUtility;
@property (nonatomic, readonly) Class<FBSDKLogging> logger;
@property (nonatomic, readonly) id<__FBSDKLoggerCreating> loggerFactory;
@property (nonatomic, readonly) id<FBSDKMacCatalystDetermining> macCatalystDeterminator;
@property (nonatomic, readonly) id<_FBSDKNotificationPosting, FBSDKNotificationDelivering> notificationCenter;
@property (nonatomic, readonly) id<FBSDKOperatingSystemVersionComparing> operatingSystemVersionComparer;
@property (nonatomic, readonly) id<FBSDKPaymentObserving> paymentObserver;
@property (nonatomic, readonly) id<FBSDKGraphRequestPiggybackManaging> piggybackManager;
@property (nonatomic, readonly) id<FBSDKAppEventsParameterProcessing, FBSDKEventsProcessing> restrictiveDataFilterManager;
@property (nonatomic, readonly) id<FBSDKServerConfigurationProviding> serverConfigurationProvider;
@property (nonatomic, readonly) id<FBSDKSettings, FBSDKSettingsLogging> settings;
@property (nonatomic, readonly) id<FBSDKSourceApplicationTracking, FBSDKTimeSpentRecording> timeSpentRecorder;
@property (nonatomic, readonly) id<FBSDKTokenCaching> tokenCache;
@property (nonatomic, readonly) id<FBSDKURLSessionProxyProviding> urlSessionProxyFactory;
@property (nonatomic, readonly) id<FBSDKUserDataPersisting> userDataStore;
@property (nonatomic, readonly) id<FBSDKCAPIReporter> capiReporter;

#if !TARGET_OS_TV

@property (nullable, nonatomic, readonly) id<FBAEMNetworking> aemNetworker;
@property (nonatomic, readonly) Class<FBSDKAEMReporter> aemReporter;
@property (nonatomic, readonly) id<FBSDKAppEventParametersExtracting> appEventParametersExtractor;
@property (nonatomic, readonly) id<FBSDKAppEventDropDetermining> appEventsDropDeterminer;
@property (nonatomic, readonly) id<FBSDKAppLinkEventPosting> appLinkEventPoster;
@property (nonatomic, readonly) id<FBSDKAppLinkCreating> appLinkFactory;
@property (nonatomic, readonly) id<FBSDKAppLinkResolving> appLinkResolver;
@property (nonatomic, readonly) id<FBSDKAppLinkTargetCreating> appLinkTargetFactory;
@property (nonatomic, readonly) id<FBSDKAppLinkURLCreating> appLinkURLFactory;
@property (nonatomic, readonly) id<FBSDKBackgroundEventLogging> backgroundEventLogger;
@property (nonatomic, readonly) Class<FBSDKCodelessIndexing> codelessIndexer;
@property (nonatomic, readonly) Class<FBSDKFileDataExtracting> dataExtractor;
@property (nonatomic, readonly) Class<FBSDKFeatureExtracting> featureExtractor;
@property (nonatomic, readonly) id<FBSDKFileManaging> fileManager;
@property (nonatomic, readonly) id<FBSDKInternalURLOpener> internalURLOpener;
@property (nonatomic, readonly) id<FBSDKMetadataIndexing> metadataIndexer;
@property (nonatomic, readonly) id<FBSDKEventProcessing, FBSDKIntegrityParametersProcessorProvider> modelManager;
@property (nonatomic, readonly) Class<FBSDKProfileProviding> profileSetter;
@property (nonatomic, readonly) id<FBSDKRulesFromKeyProvider> rulesFromKeyProvider;
@property (nonatomic, readonly) id<FBSDKURLSessionProviding> sessionDataTaskProvider;
@property (nullable, nonatomic, readonly) id<FBSDKAppEventsReporter, FBSKAdNetworkReporting> skAdNetworkReporter;
@property (nonatomic, readonly) id<FBSDKSuggestedEventsIndexer> suggestedEventsIndexer;
@property (nonatomic, readonly) Class<FBSDKSwizzling> swizzler;
@property (nonatomic, readonly) id<FBSDKURLHosting> urlHoster;
@property (nonatomic, readonly) id<FBSDKUserIDProviding> userIDProvider;
@property (nonatomic, readonly) id<FBSDKWebViewProviding> webViewProvider;

#endif

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

- (instancetype)initWithAccessTokenExpirer:(id<_FBSDKAccessTokenExpiring>)accessTokenExpirer
                         accessTokenWallet:(Class<FBSDKAccessTokenProviding, FBSDKTokenStringProviding>)accessTokenWallet
                      advertiserIDProvider:(id<FBSDKAdvertiserIDProviding>)advertiserIDProvider
                                 appEvents:(id<FBSDKSourceApplicationTracking, FBSDKAppEventsConfiguring, FBSDKApplicationLifecycleObserving, FBSDKApplicationActivating, FBSDKApplicationStateSetting, FBSDKEventLogging>)appEvents
            appEventsConfigurationProvider:(id<FBSDKAppEventsConfigurationProviding>)appEventsConfigurationProvider
                    appEventsStateProvider:(id<FBSDKAppEventsStateProviding>)appEventsStateProvider
                       appEventsStateStore:(id<FBSDKAppEventsStatePersisting>)appEventsStateStore
                          appEventsUtility:(id<FBSDKAppEventDropDetermining, FBSDKAppEventParametersExtracting, FBSDKAppEventsUtility, FBSDKLoggingNotifying>)appEventsUtility
                       atePublisherFactory:(id<FBSDKATEPublisherCreating>)atePublisherFactory
                 authenticationTokenWallet:(Class<FBSDKAuthenticationTokenProviding>)authenticationTokenWallet
                              crashHandler:(id<FBSDKCrashHandler>)crashHandler
                             crashObserver:(id<FBSDKCrashObserving>)crashObserver
                          defaultDataStore:(id<FBSDKDataPersisting>)defaultDataStore
                 deviceInformationProvider:(id<FBSDKDeviceInformationProviding>)deviceInformationProvider
             dialogConfigurationMapBuilder:(id<FBSDKDialogConfigurationMapBuilding>)dialogConfigurationMapBuilder
                errorConfigurationProvider:(id<FBSDKErrorConfigurationProviding>)errorConfigurationProvider
                              errorFactory:(id<FBSDKErrorCreating>)errorFactory
                             errorReporter:(id<FBSDKErrorReporting>)errorReporter
                  eventDeactivationManager:(id<FBSDKAppEventsParameterProcessing, FBSDKEventsProcessing>)eventDeactivationManager
                               eventLogger:(id<FBSDKEventLogging>)eventLogger
                            featureChecker:(id<FBSDKFeatureChecking, FBSDKFeatureDisabling>)featureChecker
                         gateKeeperManager:(Class<FBSDKGateKeeperManaging>)gateKeeperManager
          getApplicationActivationNotifier:(id (^)(void))getApplicationActivationNotifier
             graphRequestConnectionFactory:(id<FBSDKGraphRequestConnectionFactory>)graphRequestConnectionFactory
                       graphRequestFactory:(id<FBSDKGraphRequestFactory>)graphRequestFactory
                   impressionLoggerFactory:(id<FBSDKImpressionLoggerFactory>)impressionLoggerFactory
                    infoDictionaryProvider:(id<FBSDKInfoDictionaryProviding>)infoDictionaryProvider
                           internalUtility:(id<FBSDKInternalUtility>)internalUtility
                                    logger:(Class<FBSDKLogging>)logger
                             loggerFactory:(id<__FBSDKLoggerCreating>)loggerFactory
                   macCatalystDeterminator:(id<FBSDKMacCatalystDetermining>)macCatalystDeterminator
                        notificationCenter:(id<_FBSDKNotificationPosting, FBSDKNotificationDelivering>)notificationCenter
            operatingSystemVersionComparer:(id<FBSDKOperatingSystemVersionComparing>)operatingSystemVersionComparer
                           paymentObserver:(id<FBSDKPaymentObserving>)paymentObserver
                          piggybackManager:(id<FBSDKGraphRequestPiggybackManaging>)piggybackManager
              restrictiveDataFilterManager:(id<FBSDKAppEventsParameterProcessing, FBSDKEventsProcessing>)restrictiveDataFilterManager
               serverConfigurationProvider:(id<FBSDKServerConfigurationProviding>)serverConfigurationProvider
                                  settings:(id<FBSDKSettings, FBSDKSettingsLogging>)settings
                         timeSpentRecorder:(id<FBSDKSourceApplicationTracking, FBSDKTimeSpentRecording>)timeSpentRecorder
                                tokenCache:(id<FBSDKTokenCaching>)tokenCache
                    urlSessionProxyFactory:(id<FBSDKURLSessionProxyProviding>)urlSessionProxyFactory
                             userDataStore:(id<FBSDKUserDataPersisting>)userDataStore
                              capiReporter:(id<FBSDKCAPIReporter>)capiReporter
#if !TARGET_OS_TV
  // UNCRUSTIFY_FORMAT_OFF
                             aemNetworker:(nullable id<FBAEMNetworking>)aemNetworker
                              aemReporter:(Class<FBSDKAEMReporter>)aemReporter
              appEventParametersExtractor:(id<FBSDKAppEventParametersExtracting>)appEventParametersExtractor
                  appEventsDropDeterminer:(id<FBSDKAppEventDropDetermining>)appEventsDropDeterminer
                       appLinkEventPoster:(id<FBSDKAppLinkEventPosting>)appLinkEventPoster
                           appLinkFactory:(id<FBSDKAppLinkCreating>)appLinkFactory
                          appLinkResolver:(id<FBSDKAppLinkResolving>)appLinkResolver
                     appLinkTargetFactory:(id<FBSDKAppLinkTargetCreating>)appLinkTargetFactory
                        appLinkURLFactory:(id<FBSDKAppLinkURLCreating>)appLinkURLFactory
                     backgroundEventLogger:(id<FBSDKBackgroundEventLogging>)backgroundEventLogger
                          codelessIndexer:(Class<FBSDKCodelessIndexing>)codelessIndexer
                            dataExtractor:(Class<FBSDKFileDataExtracting>)dataExtractor
                         featureExtractor:(Class<FBSDKFeatureExtracting>)featureExtractor
                              fileManager:(id<FBSDKFileManaging>)fileManager
                        internalURLOpener:(id<FBSDKInternalURLOpener>)internalURLOpener
                          metadataIndexer:(id<FBSDKMetadataIndexing>)metadataIndexer
                             modelManager:(id<FBSDKEventProcessing, FBSDKIntegrityParametersProcessorProvider>)modelManager
                            profileSetter:(Class<FBSDKProfileProviding>)profileSetter
                     rulesFromKeyProvider:(id<FBSDKRulesFromKeyProvider>)rulesFromKeyProvider
                  sessionDataTaskProvider:(id<FBSDKURLSessionProviding>)sessionDataTaskProvider
                      skAdNetworkReporter:(nullable id<FBSDKAppEventsReporter, FBSKAdNetworkReporting>)skAdNetworkReporter
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
