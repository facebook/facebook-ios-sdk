// Copyright (c) 2014-present, Facebook, Inc. All rights reserved.
//
// You are hereby granted a non-exclusive, worldwide, royalty-free license to use,
// copy, modify, and distribute this software in source code or binary form for use
// in connection with the web ser`vices and APIs provided by Facebook.
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

#import "FBSDKTestCase.h"

#import <OCMock/OCMock.h>

// For mocking SKAdNetwork
#import <StoreKit/StoreKit.h>

#import "FBSDKAppEvents.h"
#import "FBSDKAppEvents+Internal.h"
#import "FBSDKAppEventsState.h"
#import "FBSDKApplicationDelegate+Internal.h"
#import "FBSDKCoreKit+Internal.h"
#import "FBSDKCoreKitTestUtility.h"
#import "FBSDKCrashObserver.h"
#import "FBSDKCrashShield.h"
#import "FBSDKErrorReport.h"
#import "FBSDKFeatureManager.h"
#import "FBSDKGraphRequestPiggybackManager.h"
#import "FBSDKInternalUtility.h"
#import "FBSDKKeychainStore.h"
#import "FBSDKModelManager.h"
#import "FBSDKSKAdNetworkReporter.h"
#import "FBSDKSettings.h"
#import "FBSDKTimeSpentData.h"

@interface FBSDKAppEvents (Testing)
+ (FBSDKAppEvents *)singleton;
@end

@interface FBSDKGraphRequestPiggybackManager (Testing)
+ (NSDate *)_lastRefreshTry;
@end

@interface FBSDKSettings (Testing)
+ (void)_logIfSDKSettingsChanged;
+ (void)resetLoggingBehaviorsCache;
+ (void)resetFacebookAppIDCache;
+ (void)resetFacebookUrlSchemeSuffixCache;
+ (void)resetFacebookClientTokenCache;
+ (void)resetFacebookDisplayNameCache;
+ (void)resetFacebookDomainPartCache;
+ (void)resetFacebookJpegCompressionQualityCache;
+ (void)resetFacebookInstrumentEnabledCache;
+ (void)resetFacebookAutoLogAppEventsEnabledCache;
+ (void)resetFacebookAdvertiserIDCollectionEnabledCache;
+ (void)resetAdvertiserTrackingStatusCache;
+ (void)resetUserAgentSuffixCache;
+ (void)resetFacebookCodelessDebugLogEnabledCache;
+ (void)resetDataProcessingOptionsCache;
@end

typedef void (^FBSDKSKAdNetworkReporterBlock)(void);
@interface FBSDKSKAdNetworkReporter (Testing)
+ (void)_loadConfigurationWithBlock:(FBSDKSKAdNetworkReporterBlock)block;
@end

@implementation FBSDKTestCase

- (void)setUp
{
  [super setUp];

  _appID = @"appid";

  [self setUpNSBundleMock];
  [self setUpSettingsMock];
  [self setUpServerConfigurationManagerMock];
  [self setUpAppEventsMock];
  [self setUpAppEventsUtilityMock];
  [self setUpFBApplicationDelegateMock];
  [self setUpGateKeeperManagerMock];
  [self setUpFeatureManagerMock];
  [self setUpNSUserDefaultsMock];
  [self setUpAccessTokenMock];
  [self setUpAuthenticationTokenClassMock];
  [self setUpProfileMock];
  [self setUpSKAdNetworkMock];
  [self setUpNSNotificationCenterMock];
  [self setUpMeasurementEventListenerMock];
  [self setUpTimeSpendDataMock];
  [self setUpInternalUtilityMock];
  [self setUpAdNetworkReporterMock];
  [self setUpAppLinkResolverRequestBuilderMock];
  [self setUpGraphRequestMock];
  [self setUpModelManagerClassMock];
  [self setUpGraphRequestPiggybackManagerMock];
  [self setUpGraphRequestConnectionClassMock];
  [self setUpCrashShieldClassMock];
  [self setUpNSDateClassMock];
  [self setUpSharedApplicationMock];
  [self setUpLoggerClassMock];
  [self setUpProcessInfoMock];
  [self setUpTransitionCoordinatorMock];
  [self setUpBridgeApiClassMock];
  [self setUpCrashObserverClassMock];
  [self setUpErrorReportClassMock];
}

- (void)tearDown
{
  [super tearDown];

  [_appEventsMock stopMocking];
  _appEventsMock = nil;

  [_appEventStatesMock stopMocking];
  _appEventStatesMock = nil;

  [_appEventsUtilityClassMock stopMocking];
  _appEventsUtilityClassMock = nil;

  [_fbApplicationDelegateClassMock stopMocking];
  _fbApplicationDelegateClassMock = nil;

  [_featureManagerClassMock stopMocking];
  _featureManagerClassMock = nil;

  [_gatekeeperManagerClassMock stopMocking];
  _gatekeeperManagerClassMock = nil;

  [_serverConfigurationManagerClassMock stopMocking];
  _serverConfigurationManagerClassMock = nil;

  [_settingsClassMock stopMocking];
  _settingsClassMock = nil;

  [_nsBundleClassMock stopMocking];
  _nsBundleClassMock = nil;

  [_nsUserDefaultsClassMock stopMocking];
  _nsUserDefaultsClassMock = nil;

  [_accessTokenClassMock stopMocking];
  _accessTokenClassMock = nil;

  [_authenticationTokenClassMock stopMocking];
  _authenticationTokenClassMock = nil;

  [_profileClassMock stopMocking];
  _profileClassMock = nil;

  [_skAdNetworkClassMock stopMocking];
  _skAdNetworkClassMock = nil;

  [_nsNotificationCenterClassMock stopMocking];
  _nsNotificationCenterClassMock = nil;

  [_measurementEventListenerClassMock stopMocking];
  _measurementEventListenerClassMock = nil;

  [_timeSpentDataClassMock stopMocking];
  _timeSpentDataClassMock = nil;

  [_internalUtilityClassMock stopMocking];
  _internalUtilityClassMock = nil;

  [_adNetworkReporterClassMock stopMocking];
  _adNetworkReporterClassMock = nil;

  [_appLinkResolverRequestBuilderMock stopMocking];
  _appLinkResolverRequestBuilderMock = nil;

  [_graphRequestMock stopMocking];
  _graphRequestMock = nil;

  [_modelManagerClassMock stopMocking];
  _modelManagerClassMock = nil;

  [_graphRequestPiggybackManagerMock stopMocking];
  _graphRequestPiggybackManagerMock = nil;

  [_graphRequestConnectionClassMock stopMocking];
  _graphRequestConnectionClassMock = nil;

  [_crashShieldClassMock stopMocking];
  _crashShieldClassMock = nil;

  [_nsDateClassMock stopMocking];
  _nsDateClassMock = nil;

  [_sharedApplicationMock stopMocking];
  _sharedApplicationMock = nil;

  [_loggerClassMock stopMocking];
  _loggerClassMock = nil;

  [_processInfoMock stopMocking];
  _processInfoMock = nil;

  [_transitionCoordinatorMock stopMocking];
  _transitionCoordinatorMock = nil;

  [_bridgeApiResponseClassMock stopMocking];
  _bridgeApiResponseClassMock = nil;

  [_crashObserverClassMock stopMocking];
  _crashObserverClassMock = nil;

  [_errorReportClassMock stopMocking];
  _errorReportClassMock = nil;
}

- (void)setUpSettingsMock
{
  _settingsClassMock = OCMStrictClassMock(FBSDKSettings.class);
}

- (void)setUpFBApplicationDelegateMock
{
  _fbApplicationDelegateClassMock = OCMStrictClassMock(FBSDKApplicationDelegate.class);
}

- (void)setUpGateKeeperManagerMock
{
  _gatekeeperManagerClassMock = OCMClassMock(FBSDKGateKeeperManager.class);
}

- (void)setUpFeatureManagerMock
{
  _featureManagerClassMock = [OCMockObject niceMockForClass:[FBSDKFeatureManager class]];
}

- (void)setUpServerConfigurationManagerMock
{
  self.serverConfigurationManagerClassMock = OCMStrictClassMock(FBSDKServerConfigurationManager.class);
}

- (void)setUpAppEventsMock
{
  if (self.shouldAppEventsMockBePartial) {
    // Since the `init` method is marked unavailable but just as a measure to prevent creating multiple
    // instances and enforce the singleton pattern, we will circumvent that by casting to a plain `NSObject`
    // after `alloc` in order to call `init`.
    _appEventsMock = OCMPartialMock([(NSObject *)[FBSDKAppEvents alloc] init]);
  } else {
    _appEventsMock = OCMClassMock([FBSDKAppEvents class]);
  }

  // Since numerous areas in FBSDK can end up calling `[FBSDKAppEvents singleton]`,
  // we will stub the singleton accessor out for our mock instance.
  OCMStub([_appEventsMock singleton]).andReturn(_appEventsMock);

  _appEventStatesMock = OCMClassMock([FBSDKAppEventsState class]);
  OCMStub([_appEventStatesMock alloc]).andReturn(_appEventStatesMock);
  OCMStub([_appEventStatesMock initWithToken:[OCMArg any] appID:[OCMArg any]]).andReturn(_appEventStatesMock);
}

- (void)setUpAppEventsUtilityMock
{
  _appEventsUtilityClassMock = OCMStrictClassMock(FBSDKAppEventsUtility.class);
}

- (void)setUpNSBundleMock
{
  self.nsBundleClassMock = OCMStrictClassMock(NSBundle.class);
}

- (void)setUpNSUserDefaultsMock
{
  self.nsUserDefaultsClassMock = OCMStrictClassMock(NSUserDefaults.class);
}

- (void)setUpAccessTokenMock
{
  self.accessTokenClassMock = OCMStrictClassMock(FBSDKAccessToken.class);
}

- (void)setUpAuthenticationTokenClassMock
{
  self.authenticationTokenClassMock = OCMStrictClassMock(FBSDKAuthenticationToken.class);
}

- (void)setUpProfileMock
{
  self.profileClassMock = OCMStrictClassMock(FBSDKProfile.class);
}

- (void)setUpSKAdNetworkMock
{
  if (@available(iOS 11.3, *)) {
    self.skAdNetworkClassMock = OCMStrictClassMock(SKAdNetwork.class);
  }
}

- (void)setUpNSNotificationCenterMock
{
  self.nsNotificationCenterClassMock = OCMClassMock(NSNotificationCenter.class);
}

- (void)setUpMeasurementEventListenerMock
{
  self.measurementEventListenerClassMock = OCMStrictClassMock(FBSDKMeasurementEventListener.class);
}

- (void)setUpTimeSpendDataMock
{
  self.timeSpentDataClassMock = OCMStrictClassMock(FBSDKTimeSpentData.class);
}

- (void)setUpInternalUtilityMock
{
  self.internalUtilityClassMock = OCMStrictClassMock(FBSDKInternalUtility.class);
}

- (void)setUpAdNetworkReporterMock
{
  self.adNetworkReporterClassMock = OCMClassMock(FBSDKSKAdNetworkReporter.class);
}

- (void)setUpAppLinkResolverRequestBuilderMock
{
  _appLinkResolverRequestBuilderMock = OCMStrictClassMock(FBSDKAppLinkResolverRequestBuilder.class);
}

- (void)setUpGraphRequestMock
{
  _graphRequestMock = OCMStrictClassMock(FBSDKGraphRequest.class);
}

- (void)setUpModelManagerClassMock
{
  self.modelManagerClassMock = OCMClassMock(FBSDKModelManager.class);
}

- (void)setUpGraphRequestPiggybackManagerMock
{
  self.graphRequestPiggybackManagerMock = OCMClassMock(FBSDKGraphRequestPiggybackManager.class);
}

- (void)setUpGraphRequestConnectionClassMock
{
  self.graphRequestConnectionClassMock = OCMClassMock(FBSDKGraphRequestConnection.class);
}

- (void)setUpCrashShieldClassMock
{
  self.crashShieldClassMock = OCMClassMock(FBSDKCrashShield.class);
}

- (void)setUpNSDateClassMock
{
  self.nsDateClassMock = OCMClassMock(NSDate.class);
}

- (void)setUpSharedApplicationMock
{
  self.sharedApplicationMock = OCMClassMock(UIApplication.class);
  OCMStub(ClassMethod([_sharedApplicationMock sharedApplication])).andReturn(_sharedApplicationMock);
}

- (void)setUpLoggerClassMock
{
  self.loggerClassMock = OCMClassMock(FBSDKLogger.class);
}

- (void)setUpProcessInfoMock
{
  self.processInfoMock = OCMClassMock(NSProcessInfo.class);
  OCMStub(ClassMethod([_processInfoMock processInfo])).andReturn(_processInfoMock);
}

- (void)setUpTransitionCoordinatorMock
{
  self.transitionCoordinatorMock = [OCMockObject
                                    mockForProtocol:@protocol(UIViewControllerTransitionCoordinator)];
}

- (void)setUpBridgeApiClassMock
{
  _bridgeApiResponseClassMock = OCMClassMock(FBSDKBridgeAPIResponse.class);
}

- (void)setUpCrashObserverClassMock
{
  _crashObserverClassMock = OCMClassMock(FBSDKCrashObserver.class);
}

- (void)setUpErrorReportClassMock
{
  _errorReportClassMock = OCMClassMock(FBSDKErrorReport.class);
}

#pragma mark - Public Methods

- (void)stubAppID:(NSString *)appID
{
  [OCMStub(ClassMethod([_settingsClassMock appID])) andReturn:appID];
}

- (void)stubIsSDKInitialized:(BOOL)initialized
{
  [OCMStub(ClassMethod([_fbApplicationDelegateClassMock isSDKInitialized])) andReturnValue:OCMOCK_VALUE(initialized)];
}

- (void)stubLoadingGateKeepers
{
  OCMStub(ClassMethod([_gatekeeperManagerClassMock loadGateKeepers:OCMArg.any]));
}

- (void)stubCheckingFeatures
{
  OCMStubIgnoringNonObjectArgs([_featureManagerClassMock checkFeature:FBSDKFeatureInstrument completionBlock:OCMArg.any]);
}

- (void)stubFetchingCachedServerConfiguration
{
  FBSDKServerConfiguration *configuration = [FBSDKServerConfiguration defaultServerConfigurationForAppID:_appID];
  OCMStub(ClassMethod([_serverConfigurationManagerClassMock cachedServerConfiguration])).andReturn(configuration);
}

- (void)stubCachedServerConfigurationWithServerConfiguration:(FBSDKServerConfiguration *)serverConfiguration
{
  OCMStub(ClassMethod([_serverConfigurationManagerClassMock cachedServerConfiguration])).andReturn(serverConfiguration);
}

- (void)stubMainBundleWith:(NSBundle *)bundle
{
  OCMStub(ClassMethod([_nsBundleClassMock mainBundle])).andReturn(bundle);
}

- (void)stubUserDefaultsWith:(NSUserDefaults *)defaults
{
  OCMStub(ClassMethod([_nsUserDefaultsClassMock standardUserDefaults])).andReturn(defaults);
}

- (void)stubInitializeSDKWith:(NSDictionary<UIApplicationLaunchOptionsKey, id> *)launchOptions
{
  OCMStub(ClassMethod([_fbApplicationDelegateClassMock initializeSDK:OCMArg.any]));
}

- (void)stubLoggingIfUserSettingsChanged
{
  OCMStub(ClassMethod([_settingsClassMock _logIfSDKSettingsChanged]));
}

- (void)stubTokenCacheWith:(FakeTokenCache *)cache
{
  OCMStub(ClassMethod([_settingsClassMock tokenCache])).andReturn(cache);
}

- (void)stubIsAutoLogAppEventsEnabled:(BOOL)isEnabled
{
  OCMStub(ClassMethod([_settingsClassMock isAutoLogAppEventsEnabled])).andReturn(isEnabled);
}

- (void)stubCachedProfileWith:(FBSDKProfile *__nullable)profile
{
  OCMStub(ClassMethod([_profileClassMock fetchCachedProfile])).andReturn(profile);
}

- (void)stubFBApplicationDelegateSharedInstanceWith:(FBSDKApplicationDelegate *)delegate
{
  OCMStub(ClassMethod([_fbApplicationDelegateClassMock sharedInstance])).andReturn(delegate);
}

- (void)stubRegisterAppForAdNetworkAttribution
{
  if (@available(iOS 11.3, *)) {
    OCMStub(ClassMethod([_skAdNetworkClassMock registerAppForAdNetworkAttribution]));
  }
}

- (void)stubDefaultNotificationCenterWith:(NSNotificationCenter *)notificationCenter
{
  OCMStub(ClassMethod([_nsNotificationCenterClassMock defaultCenter])).andReturn(notificationCenter);
}

- (void)stubDefaultMeasurementEventListenerWith:(FBSDKMeasurementEventListener *)eventListener
{
  OCMStub([_measurementEventListenerClassMock defaultListener]).andReturn(eventListener);
}

- (void)stubCurrentAccessTokenWith:(FBSDKAccessToken *)token
{
  OCMStub(ClassMethod([_accessTokenClassMock currentAccessToken])).andReturn(token);
}

- (void)stubCurrentAuthenticationTokenWith:(FBSDKAuthenticationToken *)token
{
  OCMStub(ClassMethod([_authenticationTokenClassMock currentAuthenticationToken])).andReturn(token);
}

- (void)stubGraphAPIVersionWith:(NSString *)version
{
  OCMStub(ClassMethod([_settingsClassMock graphAPIVersion])).andReturn(version);
}

- (void)stubClientTokenWith:(nullable NSString *)token
{
  OCMStub(ClassMethod([_settingsClassMock clientToken])).andReturn(token);
}

- (void)stubAppEventsUtilityShouldDropAppEventWith:(BOOL)shouldDropEvent
{
  OCMStub(ClassMethod([_appEventsUtilityClassMock shouldDropAppEvent])).andReturn(shouldDropEvent);
}

- (void)stubAdvertisingTrackingStatusWith:(FBSDKAdvertisingTrackingStatus)trackingStatus
{
  OCMStub(ClassMethod([_settingsClassMock getAdvertisingTrackingStatus])).andReturn(trackingStatus);
}

- (void)stubLoadingAdNetworkReporterConfiguration
{
  OCMStub(ClassMethod([_adNetworkReporterClassMock _loadConfigurationWithBlock:OCMArg.any]));
}

- (void)stubSettingsShouldLimitEventAndDataUsageWith:(BOOL)shouldLimit
{
  OCMStub(ClassMethod([_settingsClassMock shouldLimitEventAndDataUsage])).andReturn(shouldLimit);
}

- (void)stubAppEventsUtilityAdvertiserIDWith:(nullable NSString *)identifier
{
  OCMStub(ClassMethod([_appEventsUtilityClassMock advertiserID])).andReturn(identifier);
}

- (void)stubAppEventsUtilityTokenStringToUseForTokenWith:(NSString *)tokenString
{
  OCMStub(ClassMethod([_appEventsUtilityClassMock tokenStringToUseFor:OCMArg.any])).andReturn(tokenString);
}

- (void)stubServerConfigurationFetchingWithConfiguration:(nullable FBSDKServerConfiguration *)configuration error:(nullable NSError *)error
{
  OCMStub(ClassMethod([_serverConfigurationManagerClassMock loadServerConfigurationWithCompletionBlock:OCMArg.isNotNil])).andDo(^(NSInvocation *invocation) {
    void (^completion)(FBSDKServerConfiguration *serverConfiguration, NSError *error);
    [invocation getArgument:&completion atIndex:2];
    completion(configuration, error);
  });
  OCMStub(ClassMethod([_serverConfigurationManagerClassMock loadServerConfigurationWithCompletionBlock:OCMArg.isNil]));
}

- (void)stubGraphRequestWithResult:(id)result error:(nullable NSError *)error connection:(nullable FBSDKGraphRequestConnection *)connection
{
  OCMStub([_graphRequestMock startWithCompletionHandler:([OCMArg invokeBlockWithArgs:[self nsNullIfNil:connection], [self nsNullIfNil:result], [self nsNullIfNil:error], nil])]);
}

- (void)stubAppLinkResolverRequestBuilderWithIdiomSpecificField:(nullable NSString *)field
{
  OCMStub([_appLinkResolverRequestBuilderMock getIdiomSpecificField]).andReturn(field);
}

- (void)stubGraphRequestPiggybackManagerLastRefreshTryWith:(NSDate *)date
{
  OCMStub(ClassMethod([_graphRequestPiggybackManagerMock _lastRefreshTry])).andReturn(date);
}

- (void)stubAllocatingGraphRequestConnection
{
  OCMStub(ClassMethod([_graphRequestConnectionClassMock alloc]));
}

- (void)stubDisableFeature:(NSString *)feature
{
  OCMStub(ClassMethod([_featureManagerClassMock disableFeature:feature]));
}

- (void)stubIsDataProcessingRestricted:(BOOL)isRestricted
{
  OCMStub(ClassMethod([_settingsClassMock isDataProcessingRestricted])).andReturn(isRestricted);
}

- (void)stubFacebookDomainPartWith:(NSString *)domainPart
{
  OCMStub(ClassMethod([_settingsClassMock facebookDomainPart])).andReturn(domainPart);
}

- (void)stubCanOpenURLWith:(BOOL)canOpenURL
{
  OCMStub([_sharedApplicationMock canOpenURL:OCMArg.any]).andReturn(canOpenURL);
}

- (void)stubOpenURLWith:(BOOL)openURL
{
  OCMStub([_sharedApplicationMock openURL:OCMArg.any]).andReturn(openURL);
}

- (void)stubOpenUrlOptionsCompletionHandlerWithPerformCompletion:(BOOL)performCompletion
                                               completionSuccess:(BOOL)completionSuccess
{
  if (performCompletion) {
    OCMStub([_sharedApplicationMock openURL:OCMArg.any options:OCMArg.any completionHandler:([OCMArg invokeBlockWithArgs:@(completionSuccess), nil])]);
  } else {
    OCMStub([_sharedApplicationMock openURL:OCMArg.any options:OCMArg.any completionHandler:OCMArg.any]);
  }
}

- (void)stubAppUrlSchemeSuffixWith:(NSString *)suffix
{
  OCMStub(ClassMethod([_settingsClassMock appURLSchemeSuffix])).andReturn(suffix);
}

- (void)stubUserAgentSuffixWith:(nullable NSString *)suffix
{
  OCMStub(ClassMethod([self.settingsClassMock userAgentSuffix])).andReturn(suffix);
}

- (void)stubIsOperatingSystemVersionAtLeast:(NSOperatingSystemVersion)version with:(BOOL)returnValue
{
  OCMStub([self.processInfoMock isOperatingSystemAtLeastVersion:version]).andReturn(returnValue);
}

- (void)stubAppUrlSchemeWith:(nullable NSString *)scheme
{
  OCMStub([self.internalUtilityClassMock appURLScheme]).andReturn(scheme);
}

// MARK: - Helpers

- (void)resetCachedSettings
{
  [FBSDKSettings resetLoggingBehaviorsCache];
  [FBSDKSettings resetFacebookAppIDCache];
  [FBSDKSettings resetFacebookUrlSchemeSuffixCache];
  [FBSDKSettings resetFacebookClientTokenCache];
  [FBSDKSettings resetFacebookDisplayNameCache];
  [FBSDKSettings resetFacebookDomainPartCache];
  [FBSDKSettings resetFacebookJpegCompressionQualityCache];
  [FBSDKSettings resetFacebookInstrumentEnabledCache];
  [FBSDKSettings resetFacebookAutoLogAppEventsEnabledCache];
  [FBSDKSettings resetFacebookAdvertiserIDCollectionEnabledCache];
  [FBSDKSettings resetAdvertiserTrackingStatusCache];
  [FBSDKSettings resetUserAgentSuffixCache];
  [FBSDKSettings resetFacebookCodelessDebugLogEnabledCache];
  [FBSDKSettings resetDataProcessingOptionsCache];
}

- (id)nsNullIfNil:(id)nilValue
{
  id converted = nilValue;
  if (!nilValue) {
    converted = [NSNull null];
  }
  return converted;
}

@end
