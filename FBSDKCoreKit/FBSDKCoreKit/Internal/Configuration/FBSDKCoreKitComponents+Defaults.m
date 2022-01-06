/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "FBSDKCoreKitComponents+Defaults.h"

#import <Foundation/Foundation.h>

#import <FBAEMKit/FBAEMKit.h>
#import <FBSDKCoreKit_Basics/FBSDKCoreKit_Basics.h>

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

@implementation FBSDKCoreKitComponents (DefaultCoreKitComponents)

static FBSDKCoreKitComponents * _default;

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
                                     piggybackManager:FBSDKGraphRequestPiggybackManager.class
                         restrictiveDataFilterManager:[[FBSDKRestrictiveDataFilterManager alloc] initWithServerConfigurationProvider:FBSDKServerConfigurationManager.shared]
                          serverConfigurationProvider:FBSDKServerConfigurationManager.shared
                                             settings:FBSDKSettings.sharedSettings
                                    timeSpentRecorder:timeSpentRecorder
                                           tokenCache:tokenCache
                               urlSessionProxyFactory:[FBSDKURLSessionProxyFactory new]
                                        userDataStore:userDataStore
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
