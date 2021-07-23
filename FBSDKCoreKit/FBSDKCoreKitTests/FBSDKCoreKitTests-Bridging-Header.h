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
#import "FBSDKHybridAppEventsScriptMessageHandler+Testing.h"
#import "FBSDKBridgeAPIProtocolWebV1.h"
#import "FBSDKBridgeAPIProtocolWebV2+Testing.h"
#import "FBSDKBridgeAPIProtocolNativeV1.h"
#import "FBSDKBridgeAPIResponseCreating.h"
#import "FBSDKBridgeAPIResponseFactory.h"
#import "FBSDKAdvertiserIDProviding.h"
#import "FBSDKAppLinkEventPosting.h"
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

NS_ASSUME_NONNULL_BEGIN

// Interfaces for Swift extensions on Objective-C Test classes
@interface FBSDKAppEventsUtilityTests : XCTestCase
@end

// Categories needed to expose private methods to Swift
@interface FBSDKAppEventsUtility (Testing)

@property (nullable, class, nonatomic) ASIdentifierManager *cachedAdvertiserIdentifierManager;

- (ASIdentifierManager *)_asIdentifierManagerWithShouldUseCachedManager:(BOOL)useCachedManagerIfAvailable
                                               dynamicFrameworkResolver:(id<FBSDKDynamicFrameworkResolving>)dynamicFrameworkResolver
NS_SWIFT_NAME(asIdentifierManager(shouldUseCachedManager:dynamicFrameworkResolver:));

@end

@interface FBSDKAppEventsConfigurationManager (Testing)

@property (class, nonatomic) FBSDKAppEventsConfigurationManager *shared;
@property (nonatomic, nullable) id<FBSDKDataPersisting> store;
@property (nullable, nonatomic) id<FBSDKSettings> settings;
@property (nullable, nonatomic) id<FBSDKGraphRequestProviding> requestFactory;
@property (nullable, nonatomic) id<FBSDKGraphRequestConnectionProviding> connectionFactory;
@property (nonatomic) BOOL hasRequeryFinishedForAppStart;
@property (nullable, nonatomic) NSDate *timestamp;

+ (void)_processResponse:(id)response error:(nullable NSError *)error;
+ (void)reset;

@end

@interface FBSDKCloseIcon (Testing)

- (nullable UIImage *)imageWithSize:(CGSize)size
                       primaryColor:(UIColor *)primaryColor
                     secondaryColor:(UIColor *)secondaryColor
                              scale:(CGFloat)scale;

@end

NS_SWIFT_NAME(FBProfilePictureViewState)
@interface FBSDKProfilePictureViewState
@end

@interface FBSDKProfilePictureView (Testing)

- (void)_accessTokenDidChangeNotification:(NSNotification *)notification;
- (void)_profileDidChangeNotification:(NSNotification *)notification;
- (void)_updateImageWithProfile;
- (void)_updateImageWithAccessToken;
- (void)_updateImage;
- (void)_fetchAndSetImageWithURL:(NSURL *)imageURL state:(FBSDKProfilePictureViewState *)state;
- (nullable FBSDKProfilePictureViewState *)lastState;

@end

@interface FBSDKAccessToken (Testing)

+ (void)setCurrentAccessToken:(nullable FBSDKAccessToken *)token
          shouldDispatchNotif:(BOOL)shouldDispatchNotif;

@end

@interface FBSDKProfile (Testing)

@property (class, nonatomic, nullable) id<FBSDKDataPersisting> store;
@property (class, nonatomic, nullable) Class<FBSDKAccessTokenProviding> accessTokenProvider;
@property (class, nonatomic, nullable) id<FBSDKNotificationPosting, FBSDKNotificationObserving> notificationCenter;


+ (void)setCurrentProfile:(nullable FBSDKProfile *)profile
   shouldPostNotification:(BOOL)shouldPostNotification;

+ (void)reset;

@end

@interface FBSDKAuthenticationToken (Testing)

- (instancetype)initWithTokenString:(NSString *)tokenString
                              nonce:(NSString *)nonce;

+ (void)setCurrentAuthenticationToken:(nullable FBSDKAuthenticationToken *)token
               shouldPostNotification:(BOOL)shouldPostNotification;

@end

@interface FBSDKGateKeeperManager (Testing)

@property (class, nonatomic, readonly) BOOL canLoadGateKeepers;
@property (class, nonatomic, nullable) FBSDKLogger *logger;
@property (class, nonatomic, nullable) Class<FBSDKSettings> settings;
@property (class, nonatomic, nullable) id<FBSDKGraphRequestProviding> requestProvider;
@property (class, nonatomic, nullable) id<FBSDKGraphRequestConnectionProviding> connectionProvider;
@property (class, nonatomic, nullable) id<FBSDKDataPersisting> store;

@property (class, nonatomic, nullable) NSDictionary *gateKeepers;
@property (class, nonatomic) BOOL requeryFinishedForAppStart;
@property (class, nonatomic, nullable) NSDate *timestamp;
@property (class, nonatomic) BOOL isLoadingGateKeepers;

+ (void)configureWithSettings:(Class<FBSDKSettings>)settings
              requestProvider:(id<FBSDKGraphRequestProviding>)requestProvider
           connectionProvider:(nonnull id<FBSDKGraphRequestConnectionProviding>)connectionProvider
                        store:(id<FBSDKDataPersisting>)store
NS_SWIFT_NAME(configure(settings:requestProvider:connectionProvider:store:));
+ (id<FBSDKGraphRequest>)requestToLoadGateKeepers;
+ (void)processLoadRequestResponse:(nullable id)result error:(nullable NSError *)error
NS_SWIFT_NAME(parse(result:error:));
+ (BOOL)_gateKeeperIsValid;
+ (void)reset;
+ (id<FBSDKGraphRequestProviding>)requestProvider;

@end

@interface FBSDKSettings (Testing)

@property (class, nonatomic, nullable, readonly) id<FBSDKDataPersisting> store;
@property (class, nonatomic, nullable, readonly) id<FBSDKAppEventsConfigurationProviding> appEventsConfigurationProvider;
@property (class, nonatomic, nullable) id<FBSDKInfoDictionaryProviding> infoDictionaryProvider;
@property (class, nonatomic, nullable) id<FBSDKEventLogging> eventLogger;

+ (void)configureWithStore:(id<FBSDKDataPersisting>)store
appEventsConfigurationProvider:(Class<FBSDKAppEventsConfigurationProviding>)provider
    infoDictionaryProvider:(id<FBSDKInfoDictionaryProviding>)infoDictionaryProvider
               eventLogger:(id<FBSDKEventLogging>)eventLogger
NS_SWIFT_NAME(configure(store:appEventsConfigurationProvider:infoDictionaryProvider:eventLogger:));

+ (void)reset;

@end

@interface FBSDKCrashObserver (Testing)

@property (nonatomic, nullable) id<FBSDKSettings> settings;

- (instancetype)initWithFeatureChecker:(id<FBSDKFeatureChecking, FBSDKFeatureDisabling>)featureChecker
                  graphRequestProvider:(id<FBSDKGraphRequestProviding>)requestProvider
                              settings:(id<FBSDKSettings>)settings;

- (instancetype)init;

@end

@interface FBSDKGraphRequestPiggybackManager (Testing)

@property (class, nonatomic, nullable) Class<FBSDKAccessTokenProviding, FBSDKAccessTokenSetting> tokenWallet;
+ (id<FBSDKSettings>)settings;
+ (Class<FBSDKServerConfigurationProviding>)serverConfiguration;
+ (id<FBSDKGraphRequestProviding>)requestProvider;

@end

@interface FBSDKAppEvents (Testing)

+ (void)reset;

@end

@interface FBSDKAppEventsConfiguration (Testing)

+ (FBSDKAppEventsConfiguration *)defaultConfiguration;

- (instancetype)initWithDefaultATEStatus:(FBSDKAdvertisingTrackingStatus)defaultATEStatus
           advertiserIDCollectionEnabled:(BOOL)advertiserIDCollectionEnabled
                  eventCollectionEnabled:(BOOL)eventCollectionEnabled
NS_SWIFT_NAME(init(defaultATEStatus:advertiserIDCollectionEnabled:eventCollectionEnabled:));

@end

@interface FBSDKAppLink (Testing)

+ (instancetype)appLinkWithSourceURL:(nullable NSURL *)sourceURL
                             targets:(nullable NSArray<FBSDKAppLinkTarget *> *)targets
                              webURL:(nullable NSURL *)webURL
                    isBackToReferrer:(BOOL)isBackToReferrer;

@end

@interface FBSDKAppLinkNavigation (Testing)

+ (void)reset;

- (nullable NSURL *)appLinkURLWithTargetURL:(NSURL *)targetUrl error:(NSError **)error;
- (void)postAppLinkNavigateEventNotificationWithTargetURL:(nullable NSURL *)outputURL
                                                    error:(nullable NSError *)error
                                                     type:(FBSDKAppLinkNavigationType)type
                                              eventPoster:(id<FBSDKAppLinkEventPosting>)eventPoster;
- (FBSDKAppLinkNavigationType)navigationTypeForTargets:(NSArray<FBSDKAppLinkTarget *> *)targets
                                             urlOpener:(id<FBSDKURLOpener>)urlOpener;
- (FBSDKAppLinkNavigationType)navigateWithUrlOpener:(id<FBSDKURLOpener>)urlOpener
                                        eventPoster:(id<FBSDKAppLinkEventPosting>)eventPoster
                                              error:(NSError **)error
NS_SWIFT_NAME(navigate(urlOpener:eventPoster:error:));

@end

@interface FBSDKViewImpressionTracker(Testing)

@property (nonatomic, assign) id<FBSDKGraphRequestProviding> graphRequestProvider;
@property (nonatomic, assign) id<FBSDKEventLogging> eventLogger;
@property (nonatomic, strong) id<FBSDKNotificationObserving> notificationObserver;
@property (nonatomic, strong) Class<FBSDKAccessTokenProviding> tokenWallet;

+ (void)reset;
- (NSSet *)trackedImpressions;
- (void)_applicationDidEnterBackgroundNotification:(NSNotification *)notification;

@end

@interface FBSDKAppLinkResolver (Testing)

@property (nonatomic, strong) NSMutableDictionary<NSURL *, FBSDKAppLink *> *cachedFBSDKAppLinks
NS_SWIFT_NAME(cachedAppLinks);
@property (nonatomic, strong) id<FBSDKAppLinkResolverRequestBuilding> requestBuilder;
@property (nonatomic, strong) id<FBSDKClientTokenProviding> clientTokenProvider;
@property (nonatomic, strong) Class<FBSDKAccessTokenProviding> accessTokenProvider;

- (instancetype)initWithUserInterfaceIdiom:(UIUserInterfaceIdiom)userInterfaceIdiom;

- (instancetype)initWithUserInterfaceIdiom:(UIUserInterfaceIdiom)userInterfaceIdiom
                            requestBuilder:(id<FBSDKAppLinkResolverRequestBuilding>)builder
                       clientTokenProvider:(id<FBSDKClientTokenProviding>)clientTokenProvider
                       accessTokenProvider:(Class<FBSDKAccessTokenProviding>)accessTokenProvider;

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

NS_ASSUME_NONNULL_END
