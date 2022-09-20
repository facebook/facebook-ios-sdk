/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <AdSupport/AdSupport.h>

#import <FBAEMKit/FBAEMKit.h>
#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <FBSDKCoreKit_Basics/FBSDKCoreKit_Basics.h>
#import <TestTools/TestTools.h>

#import "XCTestCase+Extensions.h"

#import "AppEventsATEPublisher+Testing.h"
#import "BackgroundEventLogger+Testing.h"
#import "CodelessIndexer+Testing.h"
#import "FBAEMReporter+Testing.h"
#import "FBSDKAccessToken+Internal.h"
#import "FBSDKAccessToken+Testing.h"
#import "FBSDKAdvertisingTrackingStatus.h"
#import "FBSDKAppEventName+Internal.h"
#import "FBSDKAppEventParameterName+Internal.h"
#import "FBSDKAppEvents+Testing.h"
#import "FBSDKAppEventsATEPublisher.h"
#import "FBSDKAppEventsConfiguration+Testing.h"
#import "FBSDKAppEventsConfigurationManager+Testing.h"
#import "FBSDKAppEventsConfigurationProtocol.h"
#import "FBSDKAppEventsNumberParser.h"
#import "FBSDKAppEventsUtility+Testing.h"
#import "FBSDKAppLink+Internal.h"
#import "FBSDKAppLinkNavigation+Testing.h"
#import "FBSDKAppLinkResolverRequestBuilder.h"
#import "FBSDKAppLinkUtility+Testing.h"
#import "FBSDKAppURLSchemeProviding.h"
#import "FBSDKApplicationLifecycleNotifications.h"
#import "FBSDKAuthenticationStatusUtility+Testing.h"
#import "FBSDKAuthenticationToken.h"
#import "FBSDKAuthenticationToken+Internal.h"
#import "FBSDKBridgeAPI+Testing.h"
#import "FBSDKBridgeAPIProtocolNativeV1.h"
#import "FBSDKBridgeAPIProtocolWebV1.h"
#import "FBSDKBridgeAPIProtocolWebV2+Testing.h"
#import "FBSDKBridgeAPIRequest+Testing.h"
#import "FBSDKBridgeAPIResponseCreating.h"
#import "FBSDKBridgeAPIResponseFactory.h"
#import "FBSDKButton+Internal.h"
#import "FBSDKButtonImpressionLogging.h"
#import "FBSDKClientTokenProviding.h"
#import "FBSDKCrashHandler+Testing.h"
#import "FBSDKCrashObserver+Internal.h"
#import "FBSDKCrashShield+Testing.h"
#import "FBSDKDynamicFrameworkLoader.h"
#import "FBSDKDynamicFrameworkResolving.h"
#import "FBSDKErrorConfiguration.h"
#import "FBSDKErrorFactory+Internal.h"
#import "FBSDKErrorRecoveryAttempter.h"
#import "FBSDKErrorReport+Testing.h"
#import "FBSDKErrorReporter.h"
#import "FBSDKEventBinding+Testing.h"
#import "FBSDKEventBindingManager+Testing.h"
#import "FBSDKFeature.h"
#import "FBSDKFeatureChecking.h"
#import "FBSDKFeatureExtractor+Testing.h"
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
#import "FBSDKHybridAppEventsScriptMessageHandler+Testing.h"
#import "FBSDKImpressionLoggingButton+Internal.h"
#import "FBSDKInstrumentManager+Testing.h"
#import "FBSDKIntegrityManager+Testing.h"
#import "FBSDKInternalUtility+Testing.h"
#import "FBSDKLogger+Internal.h"
#import "FBSDKLogging.h"
#import "FBSDKMath.h"
#import "FBSDKMeasurementEventNames.h"
#import "FBSDKMetadataIndexer+Testing.h"
#import "FBSDKModelManager+Testing.h"
#import "FBSDKModelUtility.h"
#import "FBSDKPasteboard.h"
#import "FBSDKPaymentProductRequestor.h"
#import "FBSDKProfile+Testing.h"
#import "FBSDKProfileCodingKey.h"
#import "FBSDKProfileProtocols.h"
#import "FBSDKRestrictiveDataFilterManager+Testing.h"
#import "FBSDKSKAdNetworkConversionConfiguration.h"
#import "FBSDKSKAdNetworkReporter.h"
#import "FBSDKSKAdNetworkReporter+Testing.h"
#import "FBSDKSKAdNetworkRule.h"
#import "FBSDKServerConfiguration+Internal.h"
#import "FBSDKServerConfigurationManager+Testing.h"
#import "FBSDKSettings+Internal.h"
#import "FBSDKSettings+Testing.h"
#import "FBSDKSettingsLogging.h"
#import "FBSDKSettingsProtocol.h"
#import "FBSDKTimeSpentData+Testing.h"
#import "FBSDKURL+Internal.h"
#import "FBSDKURLOpener.h"
#import "FBSDKURLSessionProxying.h"
#import "FBSDKViewHierarchy.h"
#import "FBSDKViewHierarchy+Testing.h"
#import "FBSDKViewHierarchyMacros.h"
#import "FBSDKWebDialogView+Testing.h"
#import "ImageDownloader+Testing.h"
#import "PaymentProductRequestor+Testing.h"
#import "SuggestedEventsIndexer+Testing.h"
#import "UIApplication+URLOpener.h"
#import "WebViewAppLinkResolver+Testing.h"

NS_ASSUME_NONNULL_BEGIN

// Categories needed to expose private methods to Swift

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
