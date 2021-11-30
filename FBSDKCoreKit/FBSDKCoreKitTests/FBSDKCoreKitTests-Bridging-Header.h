/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <AdSupport/AdSupport.h>

#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <FBSDKCoreKit_Basics/FBSDKCoreKit_Basics.h>
#import <TestTools/TestTools.h>

#import "XCTestCase+Extensions.h"

#import "AppEventsATEPublisher+Testing.h"
#import "ApplicationDelegate+Testing.h"
#import "BackgroundEventLogger+Testing.h"
#import "CodelessIndexer+Testing.h"
#import "FBSDKAEMReporterProtocol.h"
#import "FBSDKATEPublisherCreating.h"
#import "FBSDKATEPublisherFactory.h"
#import "FBSDKAccessToken+Internal.h"
#import "FBSDKAccessToken+Testing.h"
#import "FBSDKAccessTokenExpirer+Testing.h"
#import "FBSDKAccessTokenProtocols.h"
#import "FBSDKAdvertisingTrackingStatus.h"
#import "FBSDKAppEventName+Internal.h"
#import "FBSDKAppEventParameterName+Internal.h"
#import "FBSDKAppEvents+Testing.h"
#import "FBSDKAppEventsATEPublisher.h"
#import "FBSDKAppEventsConfiguration+Testing.h"
#import "FBSDKAppEventsConfigurationManager+Testing.h"
#import "FBSDKAppEventsConfigurationProtocol.h"
#import "FBSDKAppEventsConfigurationProviding.h"
#import "FBSDKAppEventsConfiguring.h"
#import "FBSDKAppEventsDeviceInfo+Testing.h"
#import "FBSDKAppEventsFlushReason.h"
#import "FBSDKAppEventsNumberParser.h"
#import "FBSDKAppEventsParameterProcessing.h"
#import "FBSDKAppEventsReporter.h"
#import "FBSDKAppEventsState.h"
#import "FBSDKAppEventsStateFactory.h"
#import "FBSDKAppEventsStateManager.h"
#import "FBSDKAppEventsStatePersisting.h"
#import "FBSDKAppEventsStateProviding.h"
#import "FBSDKAppEventsUtility.h"
#import "FBSDKAppEventsUtility+Testing.h"
#import "FBSDKAppLink+Internal.h"
#import "FBSDKAppLinkEventPosting.h"
#import "FBSDKAppLinkFactory.h"
#import "FBSDKAppLinkNavigation+Testing.h"
#import "FBSDKAppLinkResolver+Testing.h"
#import "FBSDKAppLinkResolverRequestBuilder+Internal.h"
#import "FBSDKAppLinkResolverRequestBuilding.h"
#import "FBSDKAppLinkTarget+Internal.h"
#import "FBSDKAppLinkTargetFactory.h"
#import "FBSDKAppLinkURLCreating.h"
#import "FBSDKAppLinkURLFactory.h"
#import "FBSDKAppLinkUtility+Testing.h"
#import "FBSDKAppStoreReceiptProviding.h"
#import "FBSDKAppURLSchemeProviding.h"
#import "FBSDKApplicationLifecycleNotifications.h"
#import "FBSDKAuthenticationStatusUtility+Testing.h"
#import "FBSDKAuthenticationToken.h"
#import "FBSDKAuthenticationToken+Internal.h"
#import "FBSDKAuthenticationTokenClaims+Testing.h"
#import "FBSDKAuthenticationTokenProtocols.h"
#import "FBSDKBridgeAPI+Testing.h"
#import "FBSDKBridgeAPIProtocolNativeV1.h"
#import "FBSDKBridgeAPIProtocolWebV1.h"
#import "FBSDKBridgeAPIProtocolWebV2+Testing.h"
#import "FBSDKBridgeAPIRequest+Testing.h"
#import "FBSDKBridgeAPIRequestFactory.h"
#import "FBSDKBridgeAPIResponseCreating.h"
#import "FBSDKBridgeAPIResponseFactory.h"
#import "FBSDKButton+Internal.h"
#import "FBSDKButtonImpressionLogging.h"
#import "FBSDKClientTokenProviding.h"
#import "FBSDKCloseIcon.h"
#import "FBSDKCloseIcon+Testing.h"
#import "FBSDKConversionValueUpdating.h"
#import "FBSDKCoreKitConfigurator.h"
#import "FBSDKCrashHandler+Testing.h"
#import "FBSDKCrashObserver.h"
#import "FBSDKCrashObserver+Internal.h"
#import "FBSDKCrashShield.h"
#import "FBSDKCrashShield+Testing.h"
#import "FBSDKDataPersisting.h"
#import "FBSDKDynamicFrameworkLoader.h"
#import "FBSDKDynamicFrameworkResolving.h"
#import "FBSDKError+Testing.h"
#import "FBSDKErrorConfiguration.h"
#import "FBSDKErrorConfigurationProvider.h"
#import "FBSDKErrorConfigurationProviding.h"
#import "FBSDKErrorCreating.h"
#import "FBSDKErrorFactory.h"
#import "FBSDKErrorRecoveryAttempter.h"
#import "FBSDKErrorReport+Testing.h"
#import "FBSDKErrorReporter.h"
#import "FBSDKEventBinding+Testing.h"
#import "FBSDKEventBindingManager+Testing.h"
#import "FBSDKEventDeactivationManager.h"
#import "FBSDKEventDeactivationManager+Testing.h"
#import "FBSDKFeature.h"
#import "FBSDKFeatureChecking.h"
#import "FBSDKFeatureDisabling.h"
#import "FBSDKFeatureExtracting.h"
#import "FBSDKFeatureExtractor+Testing.h"
#import "FBSDKFeatureManager.h"
#import "FBSDKGateKeeperManager+Testing.h"
#import "FBSDKGraphErrorRecoveryProcessor.h"
#import "FBSDKGraphRequest+Testing.h"
#import "FBSDKGraphRequestBody.h"
#import "FBSDKGraphRequestConnecting.h"
#import "FBSDKGraphRequestConnecting+Internal.h"
#import "FBSDKGraphRequestConnection+Internal.h"
#import "FBSDKGraphRequestConnection+Testing.h"
#import "FBSDKGraphRequestConnectionFactory.h"
#import "FBSDKGraphRequestConnectionFactoryProtocol.h"
#import "FBSDKGraphRequestFactory.h"
#import "FBSDKGraphRequestFactoryProtocol.h"
#import "FBSDKGraphRequestMetadata.h"
#import "FBSDKGraphRequestPiggybackManager+Internal.h"
#import "FBSDKHumanSilhouetteIcon.h"
#import "FBSDKHybridAppEventsScriptMessageHandler+Testing.h"
#import "FBSDKImpressionLoggerFactory.h"
#import "FBSDKImpressionLoggerFactoryProtocol.h"
#import "FBSDKImpressionLoggingButton+Internal.h"
#import "FBSDKInstrumentManager+Testing.h"
#import "FBSDKIntegrityManager+Testing.h"
#import "FBSDKInternalURLOpener.h"
#import "FBSDKInternalUtility+Testing.h"
#import "FBSDKLogger+Internal.h"
#import "FBSDKLoggerFactory.h"
#import "FBSDKLogging.h"
#import "FBSDKLogo.h"
#import "FBSDKMath.h"
#import "FBSDKMeasurementEvent+Internal.h"
#import "FBSDKMeasurementEventNames.h"
#import "FBSDKMetadataIndexer.h"
#import "FBSDKMetadataIndexer+Testing.h"
#import "FBSDKMetadataIndexing.h"
#import "FBSDKModelManager+Testing.h"
#import "FBSDKModelUtility.h"
#import "FBSDKNetworkErrorChecker.h"
#import "FBSDKNetworkErrorChecking.h"
#import "FBSDKNotificationProtocols.h"
#import "FBSDKPasteboard.h"
#import "FBSDKPaymentObserving.h"
#import "FBSDKPaymentProductRequestor.h"
#import "FBSDKProductRequestFactory.h"
#import "FBSDKProfile+Testing.h"
#import "FBSDKProfileCodingKey.h"
#import "FBSDKProfilePictureView+Testing.h"
#import "FBSDKProfileProtocols.h"
#import "FBSDKRestrictiveData.h"
#import "FBSDKRestrictiveDataFilterManager.h"
#import "FBSDKRestrictiveDataFilterManager+Testing.h"
#import "FBSDKSKAdNetworkConversionConfiguration.h"
#import "FBSDKSKAdNetworkEvent.h"
#import "FBSDKSKAdNetworkReporter.h"
#import "FBSDKSKAdNetworkReporter+Testing.h"
#import "FBSDKSKAdNetworkRule.h"
#import "FBSDKServerConfiguration+Internal.h"
#import "FBSDKServerConfigurationManager.h"
#import "FBSDKServerConfigurationManager+Testing.h"
#import "FBSDKSettings+Internal.h"
#import "FBSDKSettings+Testing.h"
#import "FBSDKSettingsLogging.h"
#import "FBSDKSettingsProtocol.h"
#import "FBSDKShareDialogConfiguration+Testing.h"
#import "FBSDKSharedDependencies.h"
#import "FBSDKSwizzler.h"
#import "FBSDKSwizzling.h"
#import "FBSDKTimeSpentData+Testing.h"
#import "FBSDKTimeSpentRecording.h"
#import "FBSDKTokenCache.h"
#import "FBSDKURL+Internal.h"
#import "FBSDKURLOpener.h"
#import "FBSDKURLSessionProxyFactory.h"
#import "FBSDKURLSessionProxyProviding.h"
#import "FBSDKURLSessionProxying.h"
#import "FBSDKUserDataStore.h"
#import "FBSDKViewHierarchy.h"
#import "FBSDKViewHierarchyMacros.h"
#import "FBSDKViewImpressionLogger+Testing.h"
#import "FBSDKWebDialog+Testing.h"
#import "FBSDKWebDialogView+Testing.h"
#import "FBSDKWindowFinding.h"
#import "FeatureManager+Testing.h"
#import "ImageDownloader+Testing.h"
#import "NSNotificationCenter+Extensions.h"
#import "NSUserDefaults+FBSDKDataPersisting.h"
#import "PaymentObserver+Testing.h"
#import "PaymentProductRequestor+Testing.h"
#import "PaymentProductRequestorFactory+Testing.h"
#import "SuggestedEventsIndexer+Testing.h"
#import "UIApplication+URLOpener.h"
#import "WebViewAppLinkResolver+Testing.h"

NS_ASSUME_NONNULL_BEGIN

// Categories needed to expose private methods to Swift

NS_SWIFT_NAME(FBProfilePictureViewState)
@interface FBSDKProfilePictureViewState
@end

// Needed to expose this private method to AppLinkResolverRequestBuilderTests
@interface FBSDKAppLinkResolverRequestBuilder (FBSDKAppLinkResolverTests)
- (instancetype)initWithUserInterfaceIdiom:(UIUserInterfaceIdiom)userInterfaceIdiom;
@end

// Needed to expose private methods to the ServerConfigurationFixtures class
@interface FBSDKServerConfiguration (ServerConfigurationFixtures)
- (nullable NSDictionary<NSString *, id> *)dialogConfigurations;
- (nullable NSDictionary<NSString *, id> *)dialogFlows;
@end

// Defined in FBSDKViewHierarchy and needed in ViewHierarchyTests.swift
id getVariableFromInstance(NSObject *_Nullable instance, NSString *_Nullable variableName);

// Adding ObjCTestObject interface directly since ObjCTestObject.h doesn't get picked up
// from within Internal dir with BUCK due to error: 'ObjCTestObject.h' file not found
@interface ObjCTestObject : NSObject
@end

@interface FBSDKSKAdNetworkConversionConfiguration ()

+ (nullable NSArray<FBSDKSKAdNetworkRule *> *)parseRules:(nullable NSArray<id> *)rules;

@end

@interface FBSDKSKAdNetworkConversionConfigurationTests : XCTestCase
@end

NS_ASSUME_NONNULL_END
