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

#import <XCTest/XCTest.h>

#import "FBSDKAccessToken.h"
#import "FBSDKAppEvents.h"
#import "FBSDKAppEventsUtility.h"
#import "FBSDKApplicationDelegate.h"
#import "FBSDKGraphRequestConnection.h"
#import "FBSDKKeychainStore.h"
#import "FBSDKMeasurementEventListener.h"
#import "FBSDKProfile+Internal.h"
#import "FBSDKServerConfiguration.h"
#import "FBSDKServerConfigurationManager.h"
#import "FakeAccessTokenCache.h"

NS_ASSUME_NONNULL_BEGIN

/**
 This shared test case class is intended to provide commonly mocked objects and methods for stubbing out common side effects such as
 fetching from the network when objects are missing from a given cache. Additionally this class will handle stopping mocking and invalidating
 mock objects to avoid potential shared global state between tests.

 In general there are three broad use cases for mocks. These include:

 1) stubbing out a method in order to avoid calling it or to provide a known return value.

 2) stubbing out a method (usually an initializer or a singleton) to replace an object with a test object.

 3) stubbing out a method on the object you're testing. ie. use the real implementation for method a but stub out the implementation for method b.

 4) verifying behavior - something was called or something was not called etc...

Before you write a new class mock. Check to see if there's already an implementation in this class.
Also, to get a better understanding of mocking, please read the documentation at https://ocmock.org/
*/
@interface FBSDKTestCase : XCTestCase

/// Used for sharing an `FBSDKAccessToken` class mock between tests
@property (nullable, assign) id accessTokenClassMock;

/// Used for sharing a common app identifier between tests. This is not a valid FB App ID
@property (nullable, assign) NSString *appID;

/// Used for sharing an `FBSDKAppEvents` mock between tests
@property (nullable, assign) id appEventsMock;

/// Used for mocking `FBSDKAppEventState` between tests
@property (nullable, assign) id appEventStatesMock;

/// Used for sharing a `FBSDKAppEventsUtility` class  mock between tests
@property (nullable, nonatomic, assign) id appEventsUtilityClassMock;

/// Used for sharing an `FBSDKAppLinkResolverRequestBuilder` class mock between tests
@property (nullable, assign) id appLinkResolverRequestBuilderMock;

/// Used for sharing an `FBSDKApplicationDelegate` class mock between tests
@property (nullable, assign) id fbApplicationDelegateClassMock;

/// Used for sharing an `FBSDKFeatureManager` class mock between tests
@property (nullable, assign) id featureManagerClassMock;

/// Used for sharing an `FBSDKGatekeeperManager` class mock between tests
@property (nullable, assign) id gatekeeperManagerClassMock;

/// Used for sharing an `FBSDKGraphRequest` class mock between tests
@property (nullable, assign) id graphRequestMock;

/// Used for sharing an `NSBundle` class mock between tests
@property (nullable, assign) id nsBundleClassMock;

/// Used for sharing an `NSUserDefaults` class mock between tests
@property (nullable, assign) id nsUserDefaultsClassMock;

/// Used for sharing an `FBSDKProfile` class mock between tests
@property (nullable, assign) id profileClassMock;

/// Used for sharing an `FBSDKServerConfigurationManager` class mock between tests
@property (nullable, assign) id serverConfigurationManagerClassMock;

/// Used for sharing an `FBSDKSettings` class mock between tests
@property (nullable, assign) id settingsClassMock;

/// Used for sharing an `SKAdNetwork` class mock between tests
@property (nullable, nonatomic, assign) id skAdNetworkClassMock;

/// Used for sharing an `NSNotificationCenter` class mock between tests
@property (nullable, nonatomic, assign) id nsNotificationCenterClassMock;

/// Used for sharing an `FBSDKMeasurementEventListener` class mock between tests
@property (nullable, nonatomic, assign) id measurementEventListenerClassMock;

/// Used for sharing a `FBSDKTimeSpentData` class mock between tests
@property (nullable, nonatomic, assign) id timeSpentDataClassMock;

/// Used for sharing a `FBSDKInternalUtility` class mock between tests
@property (nullable, nonatomic, assign) id internalUtilityClassMock;

/// Used for sharing a `FBSDKSKAdNetworkReporter` class mock between tests
@property (nullable, nonatomic, assign) id adNetworkReporterClassMock;

/// Used for sharing a `FBSDKModelManager` class mock between tests
@property (nullable, nonatomic, assign) id modelManagerClassMock;

/// Used for sharing a `FBSDKGraphRequestPiggybackManager` class mock between tests
@property (nullable, nonatomic, assign) id graphRequestPiggybackManagerMock;

/// Used for sharing a `FBSDKGraphRequestConnection` class mock between tests
@property (nullable, nonatomic, assign) id graphRequestConnectionClassMock;

/// Used for sharing a `FBSDKCrashShield` class mock between tests
@property (nullable, nonatomic, assign) id crashShieldClassMock;

/// Used for sharing a `NSDate` class mock between tests
@property (nullable, nonatomic, assign) id nsDateClassMock;

/// Used for sharing a `UIApplication.sharedApplication` mock between tests
@property (nullable, nonatomic, assign) id sharedApplicationMock;

/// Stubs `FBSDKSettings.appID` and return the provided value
- (void)stubAppID:(nullable NSString *)appID;

/// Stubs `FBSDKSettings.isSDKInitialized` and return the provided value
- (void)stubIsSDKInitialized:(BOOL)initialized;

/// Stubs `FBSDKSettings.isAutoInitEnabled` and return the provided value
- (void)stubIsAutoInitEnabled:(BOOL)isEnabled;

/// Stubs `FBSDKSettings.isAutoLogAppEventsEnabled` and return the provided value
- (void)stubIsAutoLogAppEventsEnabled:(BOOL)isEnabled;

/// Stubs `FBSDKGateKeeperManager.loadGateKeepers:` to avoid the side effect of a network fetch
- (void)stubLoadingGateKeepers;

/// Stubs `FBSDKFeatureManager.checkFeature:` for any feature requested by FeatureManager.
- (void)stubCheckingFeatures;

/// Stubs `FBSDKServerConfigurationManager.cachedServerConfiguration` and returns the default server configuration.
/// Use this when you don't care what the actual configuration is and want to avoid a network call.
- (void)stubFetchingCachedServerConfiguration;

/// Stubs `FBSDKServerConfigurationManager.cachedServerConfiguration` with a specific configuration
- (void)stubCachedServerConfigurationWithServerConfiguration:(FBSDKServerConfiguration *)serverConfiguration;

/// Stubs `FBSDKServerConfiguratinManager.loadServerConfigurationWithCompletionBlock:` with arguments to invoke the completion with.
/// If the completion is nil then this will ignore any arguments passed to it.
- (void)stubServerConfigurationFetchingWithConfiguration:(nullable FBSDKServerConfiguration *)configuration
                                                   error:(nullable NSError *)error;

/// Stubs `NSBundle.mainBundle` with the provided NSBundle
- (void)stubMainBundleWith:(NSBundle *)bundle;

/// Stubs `NSUserDefaults.standardUserDefaults` with the provided NSUserDefaults
- (void)stubUserDefaultsWith:(NSUserDefaults *)defaults;

/// Stubs `FBSDKApplicationDelegate.initializeSDK` with a dictionary of launch options
- (void)stubInitializeSDKWith:(NSDictionary<UIApplicationLaunchOptionsKey, id> *)launchOptions;

/// Prevents logging on changes to Settings properties
- (void)stubLoggingIfUserSettingsChanged;

/// Stubs `FBSDKSettings.accessTokenCache`
- (void)stubAccessTokenCacheWith:(FakeAccessTokenCache *)cache;

/// Stubs `FBSDKProfile.fetchCachedProfile`
- (void)stubCachedProfileWith:(FBSDKProfile *__nullable)profile;

/// Stubs `FBSDKApplicationDelegate.sharedInstance`
- (void)stubFBApplicationDelegateSharedInstanceWith:(FBSDKApplicationDelegate *)delegate;

/// Stubs `SKAdNetwork.registerAppForAdNetworkAttribution`
- (void)stubRegisterAppForAdNetworkAttribution;

/// Stubs `NSNotificationCenter.defaultCenter` and returns the provided notification center
- (void)stubDefaultNotificationCenterWith:(NSNotificationCenter *)notificationCenter;

/// Stubs `AppEvents.singleton` and return the provided app events instance
- (void)stubAppEventsSingletonWith:(FBSDKAppEvents *)appEventsInstance;

/// Stubs `MeasurementEventListener.defaultListener` and returns the provided listener.
- (void)stubDefaultMeasurementEventListenerWith:(FBSDKMeasurementEventListener *)eventListener;

/// Stubs `FBSDKSettings.graphAPIVersion` with the provided version string
- (void)stubGraphAPIVersionWith:(NSString *)version;

/// Stubs `FBSDKAccessToken.currentAccessToken` with the provided token
- (void)stubCurrentAccessTokenWith:(nullable FBSDKAccessToken *)token;

/// Stubs `FBSDKSettings.clientToken` with the provided token string
- (void)stubClientTokenWith:(nullable NSString *)token;

/// Stubs `FBSDKSettings.getAdvertisingTrackingStatus` with the provided value
- (void)stubAdvertisingTrackingStatusWith:(FBSDKAdvertisingTrackingStatus)trackingStatus;

/// Stubs `FBSDKSKAdNetworkReporter._loadConfigurationWithBlock`
- (void)stubLoadingAdNetworkReporterConfiguration;

/// Stubs `FBSDKAppEventsUtility.shouldDropAppEvent` with the provided value
- (void)stubAppEventsUtilityShouldDropAppEventWith:(BOOL)shouldDropEvent;

/// Stubs `FBSDKSettings.shouldLimitEventAndDataUsage` with the provided value
- (void)stubSettingsShouldLimitEventAndDataUsageWith:(BOOL)shouldLimit;

/// Stubs `FBSDKAppEventsUtility.advertiserID` with the provided value
- (void)stubAppEventsUtilityAdvertiserIDWith:(nullable NSString *)identifier;

/// Stubs `FBSDKAppEventsUtility.tokenStringToUseFor:` and returns the provided string
- (void)stubAppEventsUtilityTokenStringToUseForTokenWith:(NSString *)tokenString;

/// Stubs `FBSDKGraphRequest.startWithCompletionHandler:` and returns the provided result, error and connection
- (void)stubGraphRequestWithResult:(id)result error:(nullable NSError *)error connection:(nullable FBSDKGraphRequestConnection *)connection;

/// Stubs `FBSDKGraphRequest.startWithCompletionHandler:` and returns the provided result, error and connection
- (void)stubAppLinkResolverRequestBuilderWithIdiomSpecificField:(nullable NSString *)field;

/// Stubs `FBSDKGraphRequestPiggybackManager._lastRefreshTry` and returns the provided `NSDate`
- (void)stubGraphRequestPiggybackManagerLastRefreshTryWith:(NSDate *)date;

/// Disables creation of graph request connections so that they cannot be started.
/// This is the nuclear option. It should be removed as soon as possible so that we can test important things
/// like whether or not a given method actually started a graph request.
/// This should be used only as needed as a stopgap to keep tests
/// from hitting the network while proper mocks are being written.
- (void)stubAllocatingGraphRequestConnection;

/// Stubs `FBSDKFeatureManager.disableFeature:` for the provided feature
- (void)stubDisableFeature:(NSString *)feature;

/// Stubs `FBSDKSettings.isDataProcessingRestricted` and returns the provided value
- (void)stubIsDataProcessingRestricted:(BOOL)isRestricted;

/// Stubs `NSDate`'s `date` method to return the shared date mock
- (void)stubDate;

/// Stubs `NSDate`'s `timeIntervalSince1970` method and returns the provided time interval
- (void)stubTimeIntervalSince1970WithTimeInterval:(NSTimeInterval)interval;

/// Stubs `FBSDKSettings.facebookDomainPart` with the provided value
- (void)stubFacebookDomainPartWith:(NSString *)domainPart;

/// Stubs `UIApplication.sharedApplication`'s `canOpenURL:` method with the value
- (void)stubCanOpenURLWith:(BOOL)canOpenURL;

/// Stubs `FBSDKSettings.appURLSchemeSuffix` and return the provided value
- (void)stubAppUrlSchemeSuffixWith:(nullable NSString *)suffix;

/// Resets cached properties in `FBSDKSettings`
- (void)resetCachedSettings;

@end

NS_ASSUME_NONNULL_END
