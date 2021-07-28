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

#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <AdSupport/AdSupport.h>

#import "FBSDKAdvertisingTrackingStatus.h"
#import "ApplicationDelegate+Testing.h"
#import "AppEventsAtePublisher+Testing.h"
#import "BackgroundEventLogger+Testing.h"
#import "Button+Testing.h"
#import "CodelessIndexer+Testing.h"
#import "FBSDKAccessTokenExpirer+Testing.h"
#import "FBSDKAccessToken+Internal.h"
#import "FBSDKAppStoreReceiptProviding.h"
#import "FBSDKAppEventsAtePublisher.h"
#import "FBSDKAppEventsConfiguring.h"
#import "FBSDKAppEventsFlushReason.h"
#import "FBSDKAppEventsNumberParser.h"
#import "FBSDKAppEventsUtility.h"
#import "FBSDKAppEventsUtility+AdvertiserIDProviding.h"
#import "FBSDKAppEvents+AppEventsConfiguring.h"
#import "FBSDKAppEvents+ApplicationActivating.h"
#import "FBSDKAppEvents+ApplicationLifecycleObserving.h"
#import "FBSDKAppEvents+ApplicationStateSetting.h"
#import "FBSDKApplicationLifecycleNotifications.h"
#import "FBSDKAppLinkUtility+Testing.h"
#import "FBSDKAppURLSchemeProviding.h"
#import "FBSDKInternalUtility+AppURLSchemeProviding.h"
#import "FBSDKInternalUtility+Testing.h"
#import "FBSDKAtePublisherCreating.h"
#import "FBSDKAtePublisherFactory.h"
#import "FBSDKAuthenticationStatusUtility.h"
#import "FBSDKAuthenticationToken+Internal.h"
#import "FBSDKHybridAppEventsScriptMessageHandler+Testing.h"
#import "FBSDKBridgeAPIProtocolWebV1.h"
#import "FBSDKBridgeAPIProtocolWebV2+Testing.h"
#import "FBSDKBridgeAPIProtocolNativeV1.h"
#import "FBSDKBridgeAPIResponseCreating.h"
#import "FBSDKBridgeAPIResponseFactory.h"
#import "FBSDKAdvertiserIDProviding.h"
#import "FBSDKAppLinkEventPosting.h"
#import "FBSDKAppEvents+Testing.h"
#import "FBSDKBridgeAPI+Testing.h"
#import "FBSDKCloseIcon.h"
#import "FBSDKCoreKitBasicsImport.h"
#import "FBSDKCrashObserver.h"
#import "FBSDKCrashObserver+Internal.h"
#import "FBSDKError+Testing.h"
#import "FBSDKEventDeactivationManager.h"
#import "FBSDKEventBinding+Testing.h"
#import "FBSDKEventBindingManager+Testing.h"
#import "FBSDKEventDeactivationManager+Testing.h"
#import "FBSDKErrorReport.h"
#import "FBSDKErrorReport+Testing.h"
#import "FBSDKFeatureExtracting.h"
#import "FBSDKGraphRequestConnecting+Internal.h"
#import "FBSDKGraphRequestMetadata.h"
#import "FBSDKHumanSilhouetteIcon.h"
#import "FBSDKInstrumentManager+Testing.h"
#import "FBSDKIntegrityManager+Testing.h"
#import "FBSDKModelManager+IntegrityParametersProcessorProvider.h"
#import "FBSDKMath.h"
#import "FBSDKModelManager+Testing.h"
#import "FBSDKModelUtility.h"
#import "FBSDKModelManager+RulesFromKeyProvider.h"
#import "FBSDKPasteboard.h"
#import "FBSDKSKAdNetworkEvent.h"
#import "FBSDKSKAdNetworkRule.h"
#import "FBSDKSKAdNetworkReporter.h"
#import "FBSDKTestCoder.h"
#import "FBSDKURLOpener.h"
#import "FBSDKViewHierarchy.h"
#import "FBSDKWebDialog+Testing.h"
#import "FBSDKWebDialogView+Testing.h"
#import "FBSDKWindowFinding.h"
#import "ImageDownloader+Testing.h"
#import "FeatureManager+Testing.h"
#import "FBSDKCrashHandler+Testing.h"
#import "FBSDKSKAdNetworkConversionConfiguration.h"
#import "PaymentObserver+Testing.h"
#import "FBSDKPaymentProductRequestor.h"
#import "PaymentProductRequestor+Testing.h"
#import "PaymentProductRequestorFactory+Testing.h"
#import "FBSDKProductRequestFactory.h"
#import "SuggestedEventsIndexer+Testing.h"
#import "UIApplication+URLOpener.h"
#import "WebViewAppLinkResolver+Testing.h"
#import "FBSDKConversionValueUpdating.h"
#import "XCTestCase+Extensions.h"
// URLSession Abstraction
#import "FBSDKURLSessionProxyProviding.h"
#import "FBSDKURLSessionProxyFactory.h"
// GraphRequestConnection Abstraction
#import "FBSDKGraphRequestConnecting.h"
#import "FBSDKGraphRequestConnectionFactory.h"
#import "FBSDKGraphRequestConnectionProviding.h"
// ErrorConfiguration Abstractions
#import "FBSDKErrorConfigurationProviding.h"
#import "FBSDKErrorConfigurationProvider.h"
#import "FBSDKServerConfigurationLoading.h"
// GraphRequestPiggybackManager Abstractions
#import "FBSDKGraphRequestPiggybackManaging.h"
#import "FBSDKGraphRequestPiggybackManagerProviding.h"
#import "FBSDKGraphRequestPiggybackManagerProvider.h"
// AppEvents Abstractions
#import "FBSDKAppEvents+EventLogging.h"
// GraphRequest Abstraction
#import "FBSDKGraphRequestProviding.h"
#import "FBSDKGraphRequestFactory.h"
// Data Persistance
#import "FBSDKDataPersisting.h"
#import "NSUserDefaults+FBSDKDataPersisting.h"
// Swizzling
#import "FBSDKSwizzling.h"
// AppLinkUtility method
#import "FBSDKAppLinkUtility+Internal.h"
// AppEventsConfiguration
#import "FBSDKAppEventsConfigurationManager.h"
#import "FBSDKAppEventsConfigurationProtocol.h"
#import "FBSDKAppEventsConfigurationProviding.h"
#import "FBSDKAppEventsConfiguration+AppEventsConfigurationProtocol.h"
// AppEventsStateManager Abstraction
#import "FBSDKAppEventsState.h"
#import "FBSDKAppEventsStateManager.h"
#import "FBSDKAppEventsStatePersisting.h"
#import "FBSDKAppEventsStateProviding.h"
// NotificationCenter
#import "FBSDKNotificationProtocols.h"
#import "NSNotificationCenter+Extensions.h"
// AccessToken
#import "FBSDKAccessTokenProtocols.h"
#import "FBSDKAccessToken+AccessTokenProtocols.h"
// AuthenticationToken
#import "FBSDKAuthenticationTokenProtocols.h"
#import "FBSDKAuthenticationToken+AuthenticationTokenProtocols.h"
// Settings
#import "FBSDKSettingsLogging.h"
#import "FBSDKSettingsProtocol.h"
#import "FBSDKSettings+SettingsProtocols.h"
// FeatureManager abstraction
#import "FBSDKFeatureChecking.h"
#import "FBSDKFeatureManager.h"
#import "FBSDKFeatureDisabling.h"
// AppLinkResolver
#import "FBSDKAppLinkResolverRequestBuilding.h"
#import "FBSDKAppLinkResolverRequestBuilder+Protocols.h"
#import "FBSDKClientTokenProviding.h"
// PaymentObserver
#import "FBSDKPaymentObserving.h"
// TimeSpentData abstraction
#import "FBSDKTimeSpentData+Testing.h"
#import "FBSDKTimeSpentRecording.h"
#import "FBSDKTimeSpentRecordingCreating.h"
#import "FBSDKTimeSpentRecordingFactory.h"
// Logging
#import "FBSDKLogging.h"
#import "FBSDKLogger+Logging.h"
#import "FBSDKLoggerFactory.h"
#import "FBSDKLoggingCreating.h"
// MetadataIndexer abstraction
#import "FBSDKMetadataIndexing.h"
// Parameter processors
#import "FBSDKAppEventsParameterProcessing.h"
// Profile
#import "FBSDKProfileProtocols.h"
#import "FBSDKProfile+ProfileProtocols.h"
// AppEvents Reporter
#import "FBSDKAppEventsReporter.h"
// Testing
#import "FBSDKAccessToken+Testing.h"
#import "FBSDKAppEventsConfiguration+Testing.h"
#import "FBSDKAppEventsConfigurationManager+Testing.h"
#import "FBSDKAppEventsUtility+Testing.h"
#import "FBSDKAppLink+Testing.h"
#import "FBSDKAppLinkNavigation+Testing.h"
#import "FBSDKAppLinkResolver+Testing.h"
#import "FBSDKAuthenticationToken+Testing.h"
#import "FBSDKCloseIcon+Testing.h"
#import "FBSDKCrashObserver+Testing.h"
#import "FBSDKGateKeeperManager+Testing.h"
#import "FBSDKGraphRequestPiggybackManager+Testing.h"
#import "FBSDKProfile+Testing.h"
#import "FBSDKProfilePictureView+Testing.h"
#import "FBSDKSettings+Testing.h"
#import "FBSDKViewImpressionTracker+Testing.h"

NS_ASSUME_NONNULL_BEGIN

// Interfaces for Swift extensions on Objective-C Test classes
@interface FBSDKAppEventsUtilityTests : XCTestCase
@end

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
- (nullable NSDictionary *)dialogConfigurations;
- (nullable NSDictionary *)dialogFlows;
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
