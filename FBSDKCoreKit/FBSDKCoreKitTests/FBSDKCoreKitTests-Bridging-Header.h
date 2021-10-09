// Copyright (c) 2014-present, Facebook, Inc. All rights reserved.
//
// You are hereby granted a non-exclusive, worldwide, royalty-free license to use,
// copy, modify, and distribute this software in source code or binary form for use
// in connection with the web services and APIs provided by Facebook.
//
// As with any software that integrates with the Facebook platform, your use of
// this software is subject to the Facebook Developer Principles and Policies
// [http://developers.facebook.com/policy/]. This copyright notice shall be
// included in all copies or substantial portions of the software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
// FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
// COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
// IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
// CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

#import <AdSupport/AdSupport.h>

#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <FBSDKCoreKit_Basics/FBSDKCoreKit_Basics.h>
#import <TestTools/TestTools.h>

#import "XCTestCase+Extensions.h"

#import "AppEventsAtePublisher+Testing.h"
#import "ApplicationDelegate+Testing.h"
#import "BackgroundEventLogger+Testing.h"
#import "Button+Testing.h"
#import "CodelessIndexer+Testing.h"
#import "FBSDKAccessToken+AccessTokenProtocols.h"
#import "FBSDKAccessToken+Internal.h"
#import "FBSDKAccessToken+Testing.h"
#import "FBSDKAccessTokenExpirer+Testing.h"
#import "FBSDKAccessTokenProtocols.h"
#import "FBSDKAdvertisingTrackingStatus.h"
#import "FBSDKAppEventName+Internal.h"
#import "FBSDKAppEvents+AppEventsConfiguring.h"
#import "FBSDKAppEvents+ApplicationActivating.h"
#import "FBSDKAppEvents+ApplicationLifecycleObserving.h"
#import "FBSDKAppEvents+ApplicationStateSetting.h"
#import "FBSDKAppEvents+EventLogging.h"
#import "FBSDKAppEvents+Testing.h"
#import "FBSDKAppEventsAtePublisher.h"
#import "FBSDKAppEventsConfiguration+AppEventsConfigurationProtocol.h"
#import "FBSDKAppEventsConfiguration+Testing.h"
#import "FBSDKAppEventsConfigurationManager.h"
#import "FBSDKAppEventsConfigurationManager+Testing.h"
#import "FBSDKAppEventsConfigurationProtocol.h"
#import "FBSDKAppEventsConfigurationProviding.h"
#import "FBSDKAppEventsConfiguring.h"
#import "FBSDKAppEventsFlushReason.h"
#import "FBSDKAppEventsNumberParser.h"
#import "FBSDKAppEventsParameterProcessing.h"
#import "FBSDKAppEventsReporter.h"
#import "FBSDKAppEventsState.h"
#import "FBSDKAppEventsStateManager.h"
#import "FBSDKAppEventsStatePersisting.h"
#import "FBSDKAppEventsStateProviding.h"
#import "FBSDKAppEventsUtility.h"
#import "FBSDKAppEventsUtility+Testing.h"
#import "FBSDKAppEventsUtilityTests.h"
#import "FBSDKAppLink+Testing.h"
#import "FBSDKAppLinkEventPosting.h"
#import "FBSDKAppLinkNavigation+Testing.h"
#import "FBSDKAppLinkResolver+Testing.h"
#import "FBSDKAppLinkResolverRequestBuilder+Protocols.h"
#import "FBSDKAppLinkResolverRequestBuilding.h"
#import "FBSDKAppLinkUtility+Internal.h"
#import "FBSDKAppLinkUtility+Testing.h"
#import "FBSDKAppStoreReceiptProviding.h"
#import "FBSDKAppURLSchemeProviding.h"
#import "FBSDKApplicationLifecycleNotifications.h"
#import "FBSDKAtePublisherCreating.h"
#import "FBSDKAtePublisherFactory.h"
#import "FBSDKAuthenticationStatusUtility+Testing.h"
#import "FBSDKAuthenticationToken.h"
#import "FBSDKAuthenticationToken+AuthenticationTokenProtocols.h"
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
#import "FBSDKClientTokenProviding.h"
#import "FBSDKCloseIcon.h"
#import "FBSDKCloseIcon+Testing.h"
#import "FBSDKConversionValueUpdating.h"
#import "FBSDKCrashHandler+Testing.h"
#import "FBSDKCrashObserver.h"
#import "FBSDKCrashObserver+Internal.h"
#import "FBSDKCrashShield.h"
#import "FBSDKDataPersisting.h"
#import "FBSDKDynamicFrameworkLoader.h"
#import "FBSDKDynamicFrameworkResolving.h"
#import "FBSDKError+Testing.h"
#import "FBSDKErrorConfiguration.h"
#import "FBSDKErrorConfigurationProvider.h"
#import "FBSDKErrorConfigurationProviding.h"
#import "FBSDKErrorRecoveryAttempter.h"
#import "FBSDKErrorReport.h"
#import "FBSDKErrorReport+Testing.h"
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
#import "FBSDKGraphRequest+Internal.h"
#import "FBSDKGraphRequest+Testing.h"
#import "FBSDKGraphRequestBody.h"
#import "FBSDKGraphRequestConnecting.h"
#import "FBSDKGraphRequestConnecting+Internal.h"
#import "FBSDKGraphRequestConnection+Testing.h"
#import "FBSDKGraphRequestConnectionFactory.h"
#import "FBSDKGraphRequestConnectionFactoryProtocol.h"
#import "FBSDKGraphRequestFactory.h"
#import "FBSDKGraphRequestFactoryProtocol.h"
#import "FBSDKGraphRequestMetadata.h"
#import "FBSDKGraphRequestPiggybackManager+Testing.h"
#import "FBSDKGraphRequestPiggybackManagerProvider.h"
#import "FBSDKGraphRequestPiggybackManagerProviding.h"
#import "FBSDKGraphRequestPiggybackManaging.h"
#import "FBSDKHumanSilhouetteIcon.h"
#import "FBSDKHybridAppEventsScriptMessageHandler+Testing.h"
#import "FBSDKInstrumentManager+Testing.h"
#import "FBSDKIntegrityManager+Testing.h"
#import "FBSDKInternalURLOpener.h"
#import "FBSDKInternalUtility+AppURLSchemeProviding.h"
#import "FBSDKInternalUtility+Internal.h"
#import "FBSDKInternalUtility+Testing.h"
#import "FBSDKLogger+Logging.h"
#import "FBSDKLoggerFactory.h"
#import "FBSDKLogging.h"
#import "FBSDKLoggingCreating.h"
#import "FBSDKLogo.h"
#import "FBSDKMath.h"
#import "FBSDKMetadataIndexer.h"
#import "FBSDKMetadataIndexing.h"
#import "FBSDKModelManager+IntegrityParametersProcessorProvider.h"
#import "FBSDKModelManager+RulesFromKeyProvider.h"
#import "FBSDKModelManager+Testing.h"
#import "FBSDKModelUtility.h"
#import "FBSDKNotificationProtocols.h"
#import "FBSDKPasteboard.h"
#import "FBSDKPaymentObserving.h"
#import "FBSDKPaymentProductRequestor.h"
#import "FBSDKProductRequestFactory.h"
#import "FBSDKProfile+Internal.h"
#import "FBSDKProfile+ProfileProtocols.h"
#import "FBSDKProfile+Testing.h"
#import "FBSDKProfilePictureView+Testing.h"
#import "FBSDKProfileProtocols.h"
#import "FBSDKRestrictiveData.h"
#import "FBSDKRestrictiveDataFilterManager.h"
#import "FBSDKSKAdNetworkConversionConfiguration.h"
#import "FBSDKSKAdNetworkEvent.h"
#import "FBSDKSKAdNetworkReporter.h"
#import "FBSDKSKAdNetworkReporter+Testing.h"
#import "FBSDKSKAdNetworkRule.h"
#import "FBSDKServerConfiguration.h"
#import "FBSDKServerConfiguration+Internal.h"
#import "FBSDKServerConfigurationLoading.h"
#import "FBSDKServerConfigurationManager.h"
#import "FBSDKServerConfigurationManager+Internal.h"
#import "FBSDKSettings+Internal.h"
#import "FBSDKSettings+Testing.h"
#import "FBSDKSettingsLogging.h"
#import "FBSDKSettingsProtocol.h"
#import "FBSDKShareDialogConfiguration+Testing.h"
#import "FBSDKSwizzler.h"
#import "FBSDKSwizzling.h"
#import "FBSDKTimeSpentData+Testing.h"
#import "FBSDKTimeSpentRecording.h"
#import "FBSDKTimeSpentRecordingCreating.h"
#import "FBSDKTimeSpentRecordingFactory.h"
#import "FBSDKTokenCache.h"
#import "FBSDKUserDataStore.h"
#import "FBSDKURLOpener.h"
#import "FBSDKURLSessionProxyFactory.h"
#import "FBSDKURLSessionProxyProviding.h"
#import "FBSDKViewHierarchy.h"
#import "FBSDKViewHierarchyMacros.h"
#import "FBSDKViewImpressionTracker+Testing.h"
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

@interface FBSDKRestrictiveDataFilterManager (Testing)
- (nullable NSString *)getMatchedDataTypeWithEventName:(NSString *)eventName
                                              paramKey:(NSString *)paramKey;
@end

@interface FBSDKCrashShield (Testing)
+ (void)configureWithSettings:(id<FBSDKSettings>)settings
              graphRequestFactory:(id<FBSDKGraphRequestFactory>)graphRequestFactory
              featureChecking:(id<FBSDKFeatureChecking, FBSDKFeatureDisabling>)featureChecking;
+ (nullable NSString *)_getFeature:(id)callstack; // Using id instead of NSArray<NSString *> * for testing in Swift
+ (nullable NSString *)_getClassName:(id)entry; // Using id instead of NSString for testing in Swift
+ (void)reset;
+ (FBSDKFeature)featureForString:(NSString *)featureName;
@end

@interface FBSDKServerConfigurationManager (Testing)
- (void)reset;
@end

NS_ASSUME_NONNULL_END
