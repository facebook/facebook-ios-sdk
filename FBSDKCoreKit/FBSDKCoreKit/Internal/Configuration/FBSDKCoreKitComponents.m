/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "FBSDKCoreKitComponents.h"

NS_ASSUME_NONNULL_BEGIN

@implementation FBSDKCoreKitComponents

- (instancetype)initWithAccessTokenExpirer:(id<FBSDKAccessTokenExpiring>)accessTokenExpirer
                         accessTokenWallet:(Class<FBSDKAccessTokenProviding, FBSDKAccessTokenSetting, FBSDKTokenStringProviding>)accessTokenWallet
                      advertiserIDProvider:(id<FBSDKAdvertiserIDProviding>)advertiserIDProvider
                                 appEvents:(id<FBSDKSourceApplicationTracking, FBSDKAppEventsConfiguring, FBSDKApplicationLifecycleObserving, FBSDKApplicationActivating, FBSDKApplicationStateSetting, FBSDKEventLogging>)appEvents
            appEventsConfigurationProvider:(id<FBSDKAppEventsConfigurationProviding>)appEventsConfigurationProvider
                    appEventsStateProvider:(id<FBSDKAppEventsStateProviding>)appEventsStateProvider
                       appEventsStateStore:(id<FBSDKAppEventsStatePersisting>)appEventsStateStore
                          appEventsUtility:(id<FBSDKAppEventDropDetermining, FBSDKAppEventParametersExtracting, FBSDKAppEventsUtility, FBSDKLoggingNotifying>)appEventsUtility
                       atePublisherFactory:(id<FBSDKATEPublisherCreating>)atePublisherFactory
                 authenticationTokenWallet:(Class<FBSDKAuthenticationTokenProviding, FBSDKAuthenticationTokenSetting>)authenticationTokenWallet
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
                        notificationCenter:(id<FBSDKNotificationPosting, FBSDKNotificationObserving>)notificationCenter
            operatingSystemVersionComparer:(id<FBSDKOperatingSystemVersionComparing>)operatingSystemVersionComparer
                           paymentObserver:(id<FBSDKPaymentObserving>)paymentObserver
                          piggybackManager:(Class<FBSDKGraphRequestPiggybackManaging>)piggybackManager
              restrictiveDataFilterManager:(id<FBSDKAppEventsParameterProcessing, FBSDKEventsProcessing>)restrictiveDataFilterManager
               serverConfigurationProvider:(id<FBSDKServerConfigurationProviding>)serverConfigurationProvider
                                  settings:(id<FBSDKSettings, FBSDKSettingsLogging>)settings
                         timeSpentRecorder:(id<FBSDKSourceApplicationTracking, FBSDKTimeSpentRecording>)timeSpentRecorder
                                tokenCache:(id<FBSDKTokenCaching>)tokenCache
                    urlSessionProxyFactory:(id<FBSDKURLSessionProxyProviding>)urlSessionProxyFactory
                             userDataStore:(id<FBSDKUserDataPersisting>)userDataStore
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
                  sessionDataTaskProvider:(id<FBSDKSessionProviding>)sessionDataTaskProvider
                      skAdNetworkReporter:(nullable id<FBSDKAppEventsReporter, FBSKAdNetworkReporting>)skAdNetworkReporter
                   suggestedEventsIndexer:(id<FBSDKSuggestedEventsIndexer>)suggestedEventsIndexer
                                 swizzler:(Class<FBSDKSwizzling>)swizzler
                                urlHoster:(id<FBSDKURLHosting>)urlHoster
                           userIDProvider:(id<FBSDKUserIDProviding>)userIDProvider
                          webViewProvider:(id<FBSDKWebViewProviding>)webViewProvider
  // UNCRUSTIFY_FORMAT_ON
#endif
{
  if ((self = [super init])) {
    _accessTokenExpirer = accessTokenExpirer;
    _accessTokenWallet = accessTokenWallet;
    _advertiserIDProvider = advertiserIDProvider;
    _appEvents = appEvents;
    _appEventsConfigurationProvider = appEventsConfigurationProvider;
    _appEventsStateProvider = appEventsStateProvider;
    _appEventsStateStore = appEventsStateStore;
    _appEventsUtility = appEventsUtility;
    _atePublisherFactory = atePublisherFactory;
    _authenticationTokenWallet = authenticationTokenWallet;
    _crashHandler = crashHandler;
    _crashObserver = crashObserver;
    _defaultDataStore = defaultDataStore;
    _deviceInformationProvider = deviceInformationProvider;
    _dialogConfigurationMapBuilder = dialogConfigurationMapBuilder;
    _errorConfigurationProvider = errorConfigurationProvider;
    _errorFactory = errorFactory;
    _errorReporter = errorReporter;
    _eventDeactivationManager = eventDeactivationManager;
    _eventLogger = eventLogger;
    _featureChecker = featureChecker;
    _gateKeeperManager = gateKeeperManager;
    _getApplicationActivationNotifier = getApplicationActivationNotifier;
    _graphRequestConnectionFactory = graphRequestConnectionFactory;
    _graphRequestFactory = graphRequestFactory;
    _impressionLoggerFactory = impressionLoggerFactory;
    _infoDictionaryProvider = infoDictionaryProvider;
    _internalUtility = internalUtility;
    _logger = logger;
    _loggerFactory = loggerFactory;
    _macCatalystDeterminator = macCatalystDeterminator;
    _notificationCenter = notificationCenter;
    _operatingSystemVersionComparer = operatingSystemVersionComparer;
    _paymentObserver = paymentObserver;
    _piggybackManager = piggybackManager;
    _restrictiveDataFilterManager = restrictiveDataFilterManager;
    _serverConfigurationProvider = serverConfigurationProvider;
    _settings = settings;
    _timeSpentRecorder = timeSpentRecorder;
    _tokenCache = tokenCache;
    _urlSessionProxyFactory = urlSessionProxyFactory;
    _userDataStore = userDataStore;

  #if !TARGET_OS_TV
    _aemNetworker = aemNetworker;
    _aemReporter = aemReporter;
    _appEventParametersExtractor = appEventParametersExtractor;
    _appEventsDropDeterminer = appEventsDropDeterminer;
    _appLinkEventPoster = appLinkEventPoster;
    _appLinkFactory = appLinkFactory;
    _appLinkResolver = appLinkResolver;
    _appLinkTargetFactory = appLinkTargetFactory;
    _appLinkURLFactory = appLinkURLFactory;
    _backgroundEventLogger = backgroundEventLogger;
    _codelessIndexer = codelessIndexer;
    _dataExtractor = dataExtractor;
    _featureExtractor = featureExtractor;
    _fileManager = fileManager;
    _internalURLOpener = internalURLOpener;
    _metadataIndexer = metadataIndexer;
    _modelManager = modelManager;
    _profileSetter = profileSetter;
    _rulesFromKeyProvider = rulesFromKeyProvider;
    _sessionDataTaskProvider = sessionDataTaskProvider;
    _skAdNetworkReporter = skAdNetworkReporter;
    _suggestedEventsIndexer = suggestedEventsIndexer;
    _swizzler = swizzler;
    _urlHoster = urlHoster;
    _userIDProvider = userIDProvider;
    _webViewProvider = webViewProvider;
  #endif
  }

  return self;
}

@end

NS_ASSUME_NONNULL_END
