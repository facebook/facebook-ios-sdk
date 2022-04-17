/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "FBSDKCoreKitComponents.h"

#import <FBSDKCoreKit/FBSDKCoreKit-Swift.h>

#import "FBSDKAEMNetworker.h"
#import "FBSDKATEPublisherFactory.h"
#import "FBSDKAccessTokenExpirer.h"
#import "FBSDKAppEvents+Internal.h"
#import "FBSDKAppEventsConfigurationManager.h"
#import "FBSDKAppEventsDeviceInfo.h"
#import "FBSDKAppEventsStateFactory.h"
#import "FBSDKAppEventsStateManager.h"
#import "FBSDKAppEventsUtility.h"
#import "FBSDKAppLinkFactory.h"
#import "FBSDKAppLinkTargetFactory.h"
#import "FBSDKAppLinkURLFactory.h"
#import "FBSDKBackgroundEventLogger.h"
#import "FBSDKCodelessIndexer.h"
#import "FBSDKCrashObserver.h"
#import "FBSDKDialogConfigurationMapBuilder.h"
#import "FBSDKErrorConfigurationProvider.h"
#import "FBSDKErrorFactory+Internal.h"
#import "FBSDKErrorReporter.h"
#import "FBSDKEventDeactivationManager.h"
#import "FBSDKFeatureExtractor.h"
#import "FBSDKFeatureManager.h"
#import "FBSDKGateKeeperManager.h"
#import "FBSDKGraphRequestPiggybackManager.h"
#import "FBSDKImpressionLoggerFactory.h"
#import "FBSDKLoggerFactory.h"
#import "FBSDKMeasurementEvent+Internal.h"
#import "FBSDKMetadataIndexer.h"
#import "FBSDKModelManager.h"
#import "FBSDKPaymentObserver.h"
#import "FBSDKPaymentProductRequestorFactory.h"
#import "FBSDKProductRequestFactory.h"
#import "FBSDKRestrictiveDataFilterManager.h"
#import "FBSDKSKAdNetworkReporter.h"
#import "FBSDKServerConfigurationManager.h"
#import "FBSDKSuggestedEventsIndexer.h"
#import "FBSDKSwizzler.h"
#import "FBSDKTimeSpentData.h"
#import "FBSDKTokenCache.h"
#import "FBSDKURLSessionProxyFactory.h"
#import "FBSDKUserDataStore.h"
#import "FBSDKWebViewFactory.h"
#import "NSNotificationCenter+Extensions.h"
#import "NSProcessInfo+Protocols.h"
#import "NSURLSession+Protocols.h"
#import "UIApplication+URLOpener.h"

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
    _capiReporter = capiReporter;

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

static FBSDKCoreKitComponents *_default;

+ (FBSDKCoreKitComponents *)defaultComponents
{
  @synchronized(self) {
    if (!_default) {
      id<FBSDKGraphRequestFactory> graphRequestFactory = [FBSDKGraphRequestFactory new];
      id<FBSDKATEPublisherCreating> atePublisherFactory = [[FBSDKATEPublisherFactory alloc] initWithDataStore:NSUserDefaults.standardUserDefaults
                                                                                          graphRequestFactory:graphRequestFactory
                                                                                                     settings:FBSDKSettings.sharedSettings
                                                                                    deviceInformationProvider:FBSDKAppEventsDeviceInfo.shared];
      id<FBSDKCrashObserving> crashObserver = [[FBSDKCrashObserver alloc] initWithFeatureChecker:FBSDKFeatureManager.shared
                                                                             graphRequestFactory:graphRequestFactory
                                                                                        settings:FBSDKSettings.sharedSettings
                                                                                    crashHandler:FBSDKCrashHandler.shared];
      id<FBSDKImpressionLoggerFactory> impressionLoggerFactory = [[FBSDKImpressionLoggerFactory alloc] initWithGraphRequestFactory:graphRequestFactory
                                                                                                                       eventLogger:FBSDKAppEvents.shared
                                                                                                                notificationCenter:NSNotificationCenter.defaultCenter
                                                                                                                 accessTokenWallet:FBSDKAccessToken.class];
      id<__FBSDKLoggerCreating> loggerFactory = [FBSDKLoggerFactory new];
      id<FBSDKPaymentProductRequestorCreating> paymentProductRequestorFactory = [[FBSDKPaymentProductRequestorFactory alloc] initWithSettings:FBSDKSettings.sharedSettings
                                                                                                                                  eventLogger:FBSDKAppEvents.shared
                                                                                                                            gateKeeperManager:FBSDKGateKeeperManager.class
                                                                                                                                        store:NSUserDefaults.standardUserDefaults
                                                                                                                                loggerFactory:loggerFactory
                                                                                                                       productsRequestFactory:[FBSDKProductRequestFactory new]
                                                                                                                      appStoreReceiptProvider:[NSBundle bundleForClass:FBSDKApplicationDelegate.class]];
      id<FBSDKPaymentObserving> paymentObserver = [[FBSDKPaymentObserver alloc] initWithPaymentQueue:SKPaymentQueue.defaultQueue
                                                                      paymentProductRequestorFactory:paymentProductRequestorFactory];
      id<FBSDKGraphRequestPiggybackManaging> piggybackManager = [[FBSDKGraphRequestPiggybackManager alloc] initWithTokenWallet:FBSDKAccessToken.class
                                                                                                                      settings:FBSDKSettings.sharedSettings
                                                                                                   serverConfigurationProvider:FBSDKServerConfigurationManager.shared
                                                                                                           graphRequestFactory:graphRequestFactory];
      id<FBSDKSourceApplicationTracking, FBSDKTimeSpentRecording> timeSpentRecorder;
      timeSpentRecorder = [[FBSDKTimeSpentData alloc] initWithEventLogger:FBSDKAppEvents.shared
                                              serverConfigurationProvider:FBSDKServerConfigurationManager.shared];

      id<FBSDKKeychainStoreProviding> keychainStoreFactory = [FBSDKKeychainStoreFactory new];
      NSString *keychainService = [NSString stringWithFormat:@"%@.%@", DefaultKeychainServicePrefix, NSBundle.mainBundle.bundleIdentifier];
      id<FBSDKKeychainStore> keychainStore = [keychainStoreFactory createKeychainStoreWithService:keychainService
                                                                                      accessGroup:nil];
      id<FBSDKTokenCaching> tokenCache = [[FBSDKTokenCache alloc] initWithSettings:FBSDKSettings.sharedSettings
                                                                     keychainStore:keychainStore];
      id<FBSDKUserDataPersisting> userDataStore = [FBSDKUserDataStore new];
      id<FBSDKCAPIReporter> capiReporter = FBSDKAppEventsCAPIManager.shared;

    #if !TARGET_OS_TV
      id<FBAEMNetworking> _Nullable aemNetworker;
      if (@available(iOS 14, *)) {
        aemNetworker = [FBSDKAEMNetworker new];
      }

      id<FBSDKAppEventsReporter, FBSKAdNetworkReporting> _Nullable skAdNetworkReporter;
      if (@available(iOS 11.3, *)) {
        skAdNetworkReporter = [[FBSDKSKAdNetworkReporter alloc] initWithGraphRequestFactory:graphRequestFactory
                                                                                  dataStore:NSUserDefaults.standardUserDefaults
                                                                     conversionValueUpdater:SKAdNetwork.class];
      }
      id<FBSDKMetadataIndexing> metaIndexer = [[FBSDKMetadataIndexer alloc] initWithUserDataStore:userDataStore
                                                                                         swizzler:FBSDKSwizzler.class];
      id<FBSDKSuggestedEventsIndexer> suggestedEventsIndexer = [[FBSDKSuggestedEventsIndexer alloc] initWithGraphRequestFactory:graphRequestFactory
                                                                                                    serverConfigurationProvider:FBSDKServerConfigurationManager.shared
                                                                                                                       swizzler:FBSDKSwizzler.class
                                                                                                                       settings:FBSDKSettings.sharedSettings
                                                                                                                    eventLogger:FBSDKAppEvents.shared
                                                                                                               featureExtractor:FBSDKFeatureExtractor.class
                                                                                                                 eventProcessor:FBSDKModelManager.shared];
      id<FBSDKBackgroundEventLogging> backgroundEventLogger = [[FBSDKBackgroundEventLogger alloc] initWithInfoDictionaryProvider:NSBundle.mainBundle
                                                                                                                     eventLogger:FBSDKAppEvents.shared];
    #endif

      _default = [FBSDKCoreKitComponents alloc];
      _default = [_default initWithAccessTokenExpirer:[[FBSDKAccessTokenExpirer alloc] initWithNotificationCenter:NSNotificationCenter.defaultCenter]
                                    accessTokenWallet:FBSDKAccessToken.class
                                 advertiserIDProvider:FBSDKAppEventsUtility.shared
                                            appEvents:FBSDKAppEvents.shared
                       appEventsConfigurationProvider:FBSDKAppEventsConfigurationManager.shared
                               appEventsStateProvider:[FBSDKAppEventsStateFactory new]
                                  appEventsStateStore:FBSDKAppEventsStateManager.shared
                                     appEventsUtility:FBSDKAppEventsUtility.shared
                                  atePublisherFactory:atePublisherFactory
                            authenticationTokenWallet:FBSDKAuthenticationToken.class
                                         crashHandler:FBSDKCrashHandler.shared
                                        crashObserver:crashObserver
                                     defaultDataStore:NSUserDefaults.standardUserDefaults
                            deviceInformationProvider:FBSDKAppEventsDeviceInfo.shared
                        dialogConfigurationMapBuilder:[FBSDKDialogConfigurationMapBuilder new]
                           errorConfigurationProvider:[FBSDKErrorConfigurationProvider new]
                                         errorFactory:[[FBSDKErrorFactory alloc] initWithReporter:FBSDKErrorReporter.shared]
                                        errorReporter:FBSDKErrorReporter.shared
                             eventDeactivationManager:[FBSDKEventDeactivationManager new]
                                          eventLogger:FBSDKAppEvents.shared
                                       featureChecker:FBSDKFeatureManager.shared
                                    gateKeeperManager:FBSDKGateKeeperManager.class
                     getApplicationActivationNotifier:^id (void) { return FBSDKApplicationDelegate.sharedInstance; }
                        graphRequestConnectionFactory:[FBSDKGraphRequestConnectionFactory new]
                                  graphRequestFactory:graphRequestFactory
                              impressionLoggerFactory:impressionLoggerFactory
                               infoDictionaryProvider:NSBundle.mainBundle
                                      internalUtility:FBSDKInternalUtility.sharedUtility
                                               logger:FBSDKLogger.class
                                        loggerFactory:loggerFactory
                              macCatalystDeterminator:NSProcessInfo.processInfo
                                   notificationCenter:NSNotificationCenter.defaultCenter
                       operatingSystemVersionComparer:NSProcessInfo.processInfo
                                      paymentObserver:paymentObserver
                                     piggybackManager:piggybackManager
                         restrictiveDataFilterManager:[[FBSDKRestrictiveDataFilterManager alloc] initWithServerConfigurationProvider:FBSDKServerConfigurationManager.shared]
                          serverConfigurationProvider:FBSDKServerConfigurationManager.shared
                                             settings:FBSDKSettings.sharedSettings
                                    timeSpentRecorder:timeSpentRecorder
                                           tokenCache:tokenCache
                               urlSessionProxyFactory:[FBSDKURLSessionProxyFactory new]
                                        userDataStore:userDataStore
                                         capiReporter:capiReporter
                #if !TARGET_OS_TV
                                         aemNetworker:aemNetworker
                                          aemReporter:FBAEMReporter.class
                          appEventParametersExtractor:FBSDKAppEventsUtility.shared
                              appEventsDropDeterminer:FBSDKAppEventsUtility.shared
                                   appLinkEventPoster:[FBSDKMeasurementEvent new]
                                       appLinkFactory:[FBSDKAppLinkFactory new]
                                      appLinkResolver:FBSDKWebViewAppLinkResolver.sharedInstance
                                 appLinkTargetFactory:[FBSDKAppLinkTargetFactory new]
                                    appLinkURLFactory:[FBSDKAppLinkURLFactory new]
                                backgroundEventLogger:backgroundEventLogger
                                      codelessIndexer:FBSDKCodelessIndexer.class
                                        dataExtractor:NSData.class
                                     featureExtractor:FBSDKFeatureExtractor.class
                                          fileManager:NSFileManager.defaultManager
                                    internalURLOpener:UIApplication.sharedApplication
                                      metadataIndexer:metaIndexer
                                         modelManager:FBSDKModelManager.shared
                                        profileSetter:FBSDKProfile.class
                                 rulesFromKeyProvider:FBSDKModelManager.shared
                              sessionDataTaskProvider:NSURLSession.sharedSession
                                  skAdNetworkReporter:skAdNetworkReporter
                               suggestedEventsIndexer:suggestedEventsIndexer
                                             swizzler:FBSDKSwizzler.class
                                            urlHoster:FBSDKInternalUtility.sharedUtility
                                       userIDProvider:FBSDKAppEvents.shared
                                      webViewProvider:[FBSDKWebViewFactory new]
                #endif
      ];
    }
  }

  return _default;
}

@end

NS_ASSUME_NONNULL_END
