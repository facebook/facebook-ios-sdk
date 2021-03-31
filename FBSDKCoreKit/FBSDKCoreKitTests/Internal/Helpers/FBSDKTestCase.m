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

// For mocking ASIdentifier
#import <AdSupport/AdSupport.h>

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
#import "FBSDKUIUtility.h"

@interface FBSDKAppEvents (Testing)
@property (nonatomic, assign) BOOL disableTimer;
+ (FBSDKAppEvents *)singleton;
@end

@interface FBSDKAppEventsConfigurationManager (Testing)
+ (void)loadAppEventsConfigurationWithBlock:(FBSDKAppEventsConfigurationManagerBlock)block;
@end

@interface FBSDKGraphRequestPiggybackManager (Testing)
+ (NSDate *)_lastRefreshTry;
@end

@interface FBSDKSettings (Testing)
+ (void)_logIfSDKSettingsChanged;
+ (void)reset;
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

  // Using timers with async unit tests is a recipe for unexpected behavior.
  // We need to create the UtilityMock and stub the timer method before we do
  // anything else since other partial mocks setup below this will create a timer
  [self setUpUtilityClassMock];
  [self stubStartGCDTimerWithInterval];

  [self setUpSettingsMock];
  [self setUpServerConfigurationManagerMock];
  [self setUpAppEventsUtilityMock];
  [self setUpFBApplicationDelegateMock];
  [self setUpGateKeeperManagerMock];
  [self setUpFeatureManagerMock];
  [self setUpAuthenticationTokenClassMock];
  [self setUpProfileMock];
  [self setUpSKAdNetworkMock];
  [self setUpMeasurementEventListenerMock];
  [self setUpTimeSpendDataMock];
  [self setUpInternalUtilityMock];
  [self setUpAdNetworkReporterMock];
  [self setUpGraphRequestMock];
  [self setUpModelManagerClassMock];
  [self setUpGraphRequestPiggybackManagerMock];
  [self setUpGraphRequestConnectionClassMock];
  [self setUpCrashShieldClassMock];
  [self setUpSharedApplicationMock];
  [self setUpLoggerClassMock];
  [self setUpTransitionCoordinatorMock];
  [self setUpBridgeApiClassMock];
  [self setUpCrashObserverClassMock];
  [self setUpErrorReportClassMock];
  [self setUpAppEventsConfigurationManagerClassMock];
  [self setUpASIdentifierClassMock];
  [self setUpAppEventsMock];
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

  [_authenticationTokenClassMock stopMocking];
  _authenticationTokenClassMock = nil;

  [_profileClassMock stopMocking];
  _profileClassMock = nil;

  [_skAdNetworkClassMock stopMocking];
  _skAdNetworkClassMock = nil;

  [_measurementEventListenerClassMock stopMocking];
  _measurementEventListenerClassMock = nil;

  [_timeSpentDataClassMock stopMocking];
  _timeSpentDataClassMock = nil;

  [_internalUtilityClassMock stopMocking];
  _internalUtilityClassMock = nil;

  [_adNetworkReporterClassMock stopMocking];
  _adNetworkReporterClassMock = nil;

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

  [_sharedApplicationMock stopMocking];
  _sharedApplicationMock = nil;

  [_loggerClassMock stopMocking];
  _loggerClassMock = nil;

  [_transitionCoordinatorMock stopMocking];
  _transitionCoordinatorMock = nil;

  [_bridgeApiResponseClassMock stopMocking];
  _bridgeApiResponseClassMock = nil;

  [_crashObserverClassMock stopMocking];
  _crashObserverClassMock = nil;

  [_errorReportClassMock stopMocking];
  _errorReportClassMock = nil;

  [_appEventsConfigurationManagerClassMock stopMocking];
  _appEventsConfigurationManagerClassMock = nil;

  [_utilityClassMock stopMocking];
  _utilityClassMock = nil;

  [_asIdentifierManagerClassMock stopMocking];
  _asIdentifierManagerClassMock = nil;
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
    // Partial mocks will try and fetch various configurations upon creation.
    // This is ham-fisted but preempts accidental network traffic.
    // We can get rid of this when we refactor to have an injectable dependency
    // for creating graph requests.
    [self stubAllocatingGraphRequestConnection];

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

- (void)setUpSharedApplicationMock
{
  self.sharedApplicationMock = OCMClassMock(UIApplication.class);
  OCMStub(ClassMethod([_sharedApplicationMock sharedApplication])).andReturn(_sharedApplicationMock);
}

- (void)setUpLoggerClassMock
{
  self.loggerClassMock = OCMClassMock(FBSDKLogger.class);
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

- (void)setUpAppEventsConfigurationManagerClassMock
{
  _appEventsConfigurationManagerClassMock = OCMClassMock(FBSDKAppEventsConfigurationManager.class);
}

- (void)setUpUtilityClassMock
{
  _utilityClassMock = OCMClassMock(FBSDKUtility.class);
}

- (void)setUpASIdentifierClassMock
{
  _asIdentifierManagerClassMock = OCMClassMock(ASIdentifierManager.class);
}

#pragma mark - Public Methods

- (void)stubAppID:(NSString *)appID
{
  [OCMStub(ClassMethod([_settingsClassMock appID])) andReturn:appID];
}

- (void)stubLoadingGateKeepers
{
  OCMStub(ClassMethod([_gatekeeperManagerClassMock loadGateKeepers:OCMArg.any]));
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

- (void)stubIsAutoLogAppEventsEnabled:(BOOL)isEnabled
{
  OCMStub(ClassMethod([_settingsClassMock isAutoLogAppEventsEnabled])).andReturn(isEnabled);
}

- (void)stubCachedProfileWith:(FBSDKProfile *__nullable)profile
{
  OCMStub(ClassMethod([_profileClassMock fetchCachedProfile])).andReturn(profile);
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
  OCMStub(ClassMethod([_settingsClassMock advertisingTrackingStatus])).andReturn(trackingStatus);
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

- (void)stubGraphRequestPiggybackManagerLastRefreshTryWith:(NSDate *)date
{
  OCMStub(ClassMethod([_graphRequestPiggybackManagerMock _lastRefreshTry])).andReturn(date);
}

- (void)stubAllocatingGraphRequestConnection
{
  OCMStub(ClassMethod([_graphRequestConnectionClassMock alloc]));
}

- (void)stubIsDataProcessingRestricted:(BOOL)isRestricted
{
  OCMStub(ClassMethod([_settingsClassMock isDataProcessingRestricted])).andReturn(isRestricted);
}

- (void)stubFacebookDomainPartWith:(NSString *)domainPart
{
  OCMStub(ClassMethod([_settingsClassMock facebookDomainPart])).andReturn(domainPart);
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

- (void)stubAppUrlSchemeWith:(nullable NSString *)scheme
{
  OCMStub([self.internalUtilityClassMock appURLScheme]).andReturn(scheme);
}

- (void)stubLoadingAppEventsConfiguration
{
  OCMStub([self.appEventsConfigurationManagerClassMock loadAppEventsConfigurationWithBlock:OCMArg.any]);
}

- (void)stubStartGCDTimerWithInterval
{
  // Note: the '5' is arbitrary and ignored but needs to be there for compilation.
  OCMStubIgnoringNonObjectArgs(ClassMethod([self.utilityClassMock startGCDTimerWithInterval:5 block:OCMArg.any]));
}

- (void)stubIsAdvertiserTrackingEnabledWith:(BOOL)isAdvertiserTrackingEnabled
{
  OCMStub([self.settingsClassMock isAdvertiserTrackingEnabled]).andReturn(isAdvertiserTrackingEnabled);
}

- (void)stubCachedAppEventsConfigurationWithConfiguration:(FBSDKAppEventsConfiguration *)configuration
{
  OCMStub(ClassMethod([self.appEventsConfigurationManagerClassMock cachedAppEventsConfiguration])).andReturn(configuration);
}

- (void)stubSharedAsIdentifierManagerWithAsIdentifierManager:(ASIdentifierManager *)identifierManager
{
  OCMStub([self.asIdentifierManagerClassMock sharedManager]).andReturn(identifierManager);
}

- (void)stubAdvertisingIdentifierWithIdentifier:(NSUUID *)uuid
{
  OCMStub([self.asIdentifierManagerClassMock advertisingIdentifier]).andReturn(uuid);
}

- (void)stubAdvertiserIdentifierWithIdentifierString:(NSString *)advertiserIdentifierString
{
  OCMStub([self.appEventsUtilityClassMock advertiserID]).andReturn(advertiserIdentifierString);
}

- (void)stubIsAdvertiserIDCollectionEnabledWith:(BOOL)isAdvertiserIDCollectionEnabled
{
  OCMStub([self.settingsClassMock isAdvertiserIDCollectionEnabled]).andReturn(isAdvertiserIDCollectionEnabled);
}

// MARK: - Helpers

- (id)nsNullIfNil:(id)nilValue
{
  id converted = nilValue;
  if (!nilValue) {
    converted = [NSNull null];
  }
  return converted;
}

@end
