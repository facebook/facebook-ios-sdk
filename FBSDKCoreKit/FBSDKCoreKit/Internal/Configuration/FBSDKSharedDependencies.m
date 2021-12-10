/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "FBSDKSharedDependencies.h"

NS_ASSUME_NONNULL_BEGIN

@implementation FBSDKSharedDependencies

- (instancetype)initWithAccessTokenWallet:(Class<FBSDKAccessTokenProviding, FBSDKAccessTokenSetting, FBSDKTokenStringProviding>)accessTokenWallet
           appEventsConfigurationProvider:(id<FBSDKAppEventsConfigurationProviding>)appEventsConfigurationProvider
            applicationActivationNotifier:(id)applicationActivationNotifier
                      atePublisherFactory:(id<FBSDKAtePublisherCreating>)atePublisherFactory
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
                            loggerFactory:(id<__FBSDKLoggerCreating>)loggerFactory
                  macCatalystDeterminator:(id<FBSDKMacCatalystDetermining>)macCatalystDeterminator
           operatingSystemVersionComparer:(id<FBSDKOperatingSystemVersionComparing>)operatingSystemVersionComparer
                 piggybackManagerProvider:(id<FBSDKGraphRequestPiggybackManagerProviding>)piggybackManagerProvider
             restrictiveDataFilterManager:(id<FBSDKAppEventsParameterProcessing, FBSDKEventsProcessing>)restrictiveDataFilterManager
              serverConfigurationProvider:(id<FBSDKServerConfigurationProviding>)serverConfigurationProvider
                                 settings:(id<FBSDKSettings>)settings
                timeSpentRecordingFactory:(id<FBSDKTimeSpentRecordingCreating>)timeSpentRecordingFactory
                               tokenCache:(id<FBSDKTokenCaching>)tokenCache
                   urlSessionProxyFactory:(id<FBSDKURLSessionProxyProviding>)urlSessionProxyFactory
                            userDataStore:(id<FBSDKUserDataPersisting>)userDataStore
#if !TARGET_OS_TV
                     advertiserIDProvider:(id<FBSDKAdvertiserIDProviding>)advertiserIDProvider
                             aemNetworker:(nullable id<FBAEMNetworking>)aemNetworker
              appEventParametersExtractor:(id<FBSDKAppEventParametersExtracting>)appEventParametersExtractor
                  appEventsDropDeterminer:(id<FBSDKAppEventDropDetermining>)appEventsDropDeterminer
                           appLinkFactory:(id<FBSDKAppLinkCreating>)appLinkFactory
                     appLinkTargetFactory:(id<FBSDKAppLinkTargetCreating>)appLinkTargetFactory
                        appLinkURLFactory:(id<FBSDKAppLinkURLCreating>)appLinkURLFactory
                          codelessIndexer:(Class<FBSDKCodelessIndexing>)codelessIndexer
                            dataExtractor:(Class<FBSDKFileDataExtracting>)dataExtractor
                         featureExtractor:(Class<FBSDKFeatureExtracting>)featureExtractor
                              fileManager:(id<FBSDKFileManaging>)fileManager
                        internalURLOpener:(id<FBSDKInternalURLOpener>)internalURLOpener
                          internalUtility:(id<FBSDKInternalUtility>)internalUtility
                          metadataIndexer:(id<FBSDKMetadataIndexing>)metadataIndexer
                             modelManager:(id <FBSDKEventProcessing, FBSDKIntegrityParametersProcessorProvider>) modelManager
                       notificationCenter:(id <FBSDKNotificationPosting, FBSDKNotificationObserving>) notificationCenter
                            profileSetter:(Class<FBSDKProfileProviding>)profileSetter
                     rulesFromKeyProvider:(id<FBSDKRulesFromKeyProvider>)rulesFromKeyProvider
                  sessionDataTaskProvider:(id<FBSDKSessionProviding>)sessionDataTaskProvider
                      skadNetworkReporter:(nullable id<FBSKAdNetworkReporting>)skadNetworkReporter
                   suggestedEventsIndexer:(id<FBSDKSuggestedEventsIndexer>)suggestedEventsIndexer
                                 swizzler:(Class<FBSDKSwizzling>)swizzler
                                urlHoster:(id<FBSDKURLHosting>)urlHoster
                           userIDProvider:(id<FBSDKUserIDProviding>)userIDProvider
                          webViewProvider:(id<FBSDKWebViewProviding>)webViewProvider
#endif
{
  if ((self = [super init])) {
    _accessTokenWallet = accessTokenWallet;
    _appEventsConfigurationProvider = appEventsConfigurationProvider;
    _applicationActivationNotifier = applicationActivationNotifier;
    _atePublisherFactory = atePublisherFactory;
    _authenticationTokenWallet = authenticationTokenWallet;
    _crashHandler = crashHandler;
    _crashObserver = crashObserver;
    _defaultDataStore = defaultDataStore;
    _deviceInformationProvider = deviceInformationProvider;
    _errorConfigurationProvider = errorConfigurationProvider;
    _errorFactory = errorFactory;
    _errorReporter = errorReporter;
    _eventDeactivationManager = eventDeactivationManager;
    _eventLogger = eventLogger;
    _featureChecker = featureChecker;
    _gateKeeperManager = gateKeeperManager;
    _graphRequestConnectionFactory = graphRequestConnectionFactory;
    _graphRequestFactory = graphRequestFactory;
    _infoDictionaryProvider = infoDictionaryProvider;
    _loggerFactory = loggerFactory;
    _macCatalystDeterminator = macCatalystDeterminator;
    _operatingSystemVersionComparer = operatingSystemVersionComparer;
    _piggybackManagerProvider = piggybackManagerProvider;
    _restrictiveDataFilterManager = restrictiveDataFilterManager;
    _serverConfigurationProvider = serverConfigurationProvider;
    _settings = settings;
    _timeSpentRecordingFactory = timeSpentRecordingFactory;
    _tokenCache = tokenCache;
    _urlSessionProxyFactory = urlSessionProxyFactory;
    _userDataStore = userDataStore;

  #if !TARGET_OS_TV
    _advertiserIDProvider = advertiserIDProvider;
    _aemNetworker = aemNetworker;
    _appEventParametersExtractor = appEventParametersExtractor;
    _appEventsDropDeterminer = appEventsDropDeterminer;
    _appLinkFactory = appLinkFactory;
    _appLinkTargetFactory = appLinkTargetFactory;
    _appLinkURLFactory = appLinkURLFactory;
    _codelessIndexer = codelessIndexer;
    _dataExtractor = dataExtractor;
    _featureExtractor = featureExtractor;
    _fileManager = fileManager;
    _internalURLOpener = internalURLOpener;
    _internalUtility = internalUtility;
    _metadataIndexer = metadataIndexer;
    _modelManager = modelManager;
    _notificationCenter = notificationCenter;
    _profileSetter = profileSetter;
    _rulesFromKeyProvider = rulesFromKeyProvider;
    _sessionDataTaskProvider = sessionDataTaskProvider;
    _skadNetworkReporter = skadNetworkReporter;
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
