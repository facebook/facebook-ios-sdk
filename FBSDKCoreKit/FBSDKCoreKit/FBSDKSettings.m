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

#import "FBSDKSettings+Internal.h"

#import <AdSupport/AdSupport.h>

#import "FBSDKAccessTokenExpirer.h"
#import "FBSDKAppEventsConfigurationProtocol.h"
#import "FBSDKAppEventsConfigurationProviding.h"
#import "FBSDKCoreKitBasicsImport.h"
#import "FBSDKDataPersisting.h"
#import "FBSDKEventLogging.h"
#import "FBSDKInternalUtility.h"

#define FBSDKSETTINGS_PLIST_CONFIGURATION_SETTING_IMPL(TYPE, PLIST_KEY, PROPERTY_NAME, SETTER, DEFAULT_VALUE, ENABLE_CACHE) \
  + (TYPE *)PROPERTY_NAME \
  { \
    return self.sharedSettings.PROPERTY_NAME; \
  } \
\
  + (void)SETTER:(TYPE *)value { \
    [self.sharedSettings SETTER:value]; \
  } \
  - (TYPE *)PROPERTY_NAME \
  { \
    if ((_ ## PROPERTY_NAME == nil) && ENABLE_CACHE) { \
      _ ## PROPERTY_NAME = [[self.store objectForKey:@#PLIST_KEY] copy]; \
    } \
    if (_ ## PROPERTY_NAME == nil) { \
      _ ## PROPERTY_NAME = [[self.infoDictionaryProvider objectForInfoDictionaryKey:@#PLIST_KEY] copy] ?: DEFAULT_VALUE; \
    } \
    return _ ## PROPERTY_NAME; \
  } \
  - (void)SETTER:(TYPE *)value { \
    _ ## PROPERTY_NAME = [value copy]; \
    if (ENABLE_CACHE) { \
      if (value != nil) { \
        [self.store setObject:value forKey:@#PLIST_KEY]; \
      } else { \
        [self.store removeObjectForKey:@#PLIST_KEY]; \
      } \
    } \
    [self logIfSDKSettingsChanged]; \
  }

#define FBSDKSETTINGS_PLIST_CONFIGURATION_SETTING_DECL(TYPE, PROPERTY_NAME, SETTER) \
  @property (nullable, nonatomic, getter = PROPERTY_NAME, setter = SETTER:, copy) TYPE *PROPERTY_NAME;

#define FBSDKSETTINGS_PLIST_CONFIGURATION_SETTING_IVAR_DECL(TYPE, PROPERTY_NAME) \
  TYPE *_ ## PROPERTY_NAME;

FBSDKLoggingBehavior FBSDKLoggingBehaviorAccessTokens = @"include_access_tokens";
FBSDKLoggingBehavior FBSDKLoggingBehaviorPerformanceCharacteristics = @"perf_characteristics";
FBSDKLoggingBehavior FBSDKLoggingBehaviorAppEvents = @"app_events";
FBSDKLoggingBehavior FBSDKLoggingBehaviorInformational = @"informational";
FBSDKLoggingBehavior FBSDKLoggingBehaviorCacheErrors = @"cache_errors";
FBSDKLoggingBehavior FBSDKLoggingBehaviorUIControlErrors = @"ui_control_errors";
FBSDKLoggingBehavior FBSDKLoggingBehaviorDeveloperErrors = @"developer_errors";
FBSDKLoggingBehavior FBSDKLoggingBehaviorGraphAPIDebugWarning = @"graph_api_debug_warning";
FBSDKLoggingBehavior FBSDKLoggingBehaviorGraphAPIDebugInfo = @"graph_api_debug_info";
FBSDKLoggingBehavior FBSDKLoggingBehaviorNetworkRequests = @"network_requests";

static NSMutableSet<FBSDKLoggingBehavior> *g_loggingBehaviors;
static NSString *const FBSDKSettingsLimitEventAndDataUsage = @"com.facebook.sdk:FBSDKSettingsLimitEventAndDataUsage";
static NSString *const FBSDKSettingsBitmask = @"com.facebook.sdk:FBSDKSettingsBitmask";
static NSString *const FBSDKSettingsDataProcessingOptions = @"com.facebook.sdk:FBSDKSettingsDataProcessingOptions";
static NSString *const FBSDKSettingsAdvertisingTrackingStatus = @"com.facebook.sdk:FBSDKSettingsAdvertisingTrackingStatus";
static NSString *const FBSDKSettingsInstallTimestamp = @"com.facebook.sdk:FBSDKSettingsInstallTimestamp";
static NSString *const FBSDKSettingsSetAdvertiserTrackingEnabledTimestamp = @"com.facebook.sdk:FBSDKSettingsSetAdvertiserTrackingEnabledTimestamp";
static NSString *const FBSDKSettingsUseCachedValuesForExpensiveMetadata = @"com.facebook.sdk:FBSDKSettingsUseCachedValuesForExpensiveMetadata";
static NSString *const FBSDKSettingsUseTokenOptimizations = @"com.facebook.sdk.FBSDKSettingsUseTokenOptimizations";
static BOOL g_disableErrorRecovery;
static NSString *g_userAgentSuffix;
static NSString *g_defaultGraphAPIVersion;
static FBSDKAccessTokenExpirer *g_accessTokenExpirer;
static NSDictionary<NSString *, id> *g_dataProcessingOptions = nil;

//
// Warning messages for App Event Flags
//

static NSString *const autoLogAppEventsEnabledNotSetWarning =
@"<Warning>: Please set a value for FacebookAutoLogAppEventsEnabled. Set the flag to TRUE if you want "
"to collect app install, app launch and in-app purchase events automatically. To request user consent "
"before collecting data, set the flag value to FALSE, then change to TRUE once user consent is received. "
"Learn more: https://developers.facebook.com/docs/app-events/getting-started-app-events-ios#disable-auto-events.";
static NSString *const advertiserIDCollectionEnabledNotSetWarning =
@"<Warning>: You haven't set a value for FacebookAdvertiserIDCollectionEnabled. Set the flag to TRUE if "
"you want to collect Advertiser ID for better advertising and analytics results.";
static NSString *const advertiserIDCollectionEnabledFalseWarning =
@"<Warning>: The value for FacebookAdvertiserIDCollectionEnabled is currently set to FALSE so you're sending app "
"events without collecting Advertiser ID. This can affect the quality of your advertising and analytics results.";

@interface FBSDKSettings ()

@property (nullable, nonatomic) id<FBSDKDataPersisting> store;
@property (nullable, nonatomic) Class<FBSDKAppEventsConfigurationProviding> appEventsConfigurationProvider;
@property (nullable, nonatomic) id<FBSDKInfoDictionaryProviding> infoDictionaryProvider;
@property (nullable, nonatomic) id<FBSDKEventLogging> eventLogger;
@property (nullable, nonatomic) NSNumber *advertiserTrackingStatusBacking;

FBSDKSETTINGS_PLIST_CONFIGURATION_SETTING_DECL(NSString, appID, setAppID);
FBSDKSETTINGS_PLIST_CONFIGURATION_SETTING_DECL(NSString, appURLSchemeSuffix, setAppURLSchemeSuffix);
FBSDKSETTINGS_PLIST_CONFIGURATION_SETTING_DECL(NSString, clientToken, setClientToken);
FBSDKSETTINGS_PLIST_CONFIGURATION_SETTING_DECL(NSString, displayName, setDisplayName);
FBSDKSETTINGS_PLIST_CONFIGURATION_SETTING_DECL(NSString, facebookDomainPart, setFacebookDomainPart);
FBSDKSETTINGS_PLIST_CONFIGURATION_SETTING_DECL(NSNumber, _JPEGCompressionQualityNumber, _setJPEGCompressionQualityNumber);
FBSDKSETTINGS_PLIST_CONFIGURATION_SETTING_DECL(NSNumber, _instrumentEnabled, _setInstrumentEnabled);
FBSDKSETTINGS_PLIST_CONFIGURATION_SETTING_DECL(NSNumber, _autoLogAppEventsEnabled, _setAutoLogAppEventsEnabled);
FBSDKSETTINGS_PLIST_CONFIGURATION_SETTING_DECL(NSNumber, _advertiserIDCollectionEnabled, _setAdvertiserIDCollectionEnabled);
FBSDKSETTINGS_PLIST_CONFIGURATION_SETTING_DECL(NSNumber, _SKAdNetworkReportEnabled, _setSKAdNetworkReportEnabled);
FBSDKSETTINGS_PLIST_CONFIGURATION_SETTING_DECL(NSNumber, _codelessDebugLogEnabled, _setCodelessDebugLogEnabled);

@end

@implementation FBSDKSettings
{
  FBSDKSETTINGS_PLIST_CONFIGURATION_SETTING_IVAR_DECL(NSString, appID);
  FBSDKSETTINGS_PLIST_CONFIGURATION_SETTING_IVAR_DECL(NSString, appURLSchemeSuffix);
  FBSDKSETTINGS_PLIST_CONFIGURATION_SETTING_IVAR_DECL(NSString, clientToken);
  FBSDKSETTINGS_PLIST_CONFIGURATION_SETTING_IVAR_DECL(NSString, displayName);
  FBSDKSETTINGS_PLIST_CONFIGURATION_SETTING_IVAR_DECL(NSString, facebookDomainPart);
  FBSDKSETTINGS_PLIST_CONFIGURATION_SETTING_IVAR_DECL(NSNumber, _JPEGCompressionQualityNumber);
  FBSDKSETTINGS_PLIST_CONFIGURATION_SETTING_IVAR_DECL(NSNumber, _instrumentEnabled);
  FBSDKSETTINGS_PLIST_CONFIGURATION_SETTING_IVAR_DECL(NSNumber, _autoLogAppEventsEnabled);
  FBSDKSETTINGS_PLIST_CONFIGURATION_SETTING_IVAR_DECL(NSNumber, _advertiserIDCollectionEnabled);
  FBSDKSETTINGS_PLIST_CONFIGURATION_SETTING_IVAR_DECL(NSNumber, _SKAdNetworkReportEnabled);
  FBSDKSETTINGS_PLIST_CONFIGURATION_SETTING_IVAR_DECL(NSNumber, _codelessDebugLogEnabled);
}

static dispatch_once_t sharedSettingsNonce;

+ (void)initialize
{
  if (self == [FBSDKSettings class]) {
    // This should be moved to ApplicationDelegate and its initialization
    // should be separated from its storage and notification observing
    g_accessTokenExpirer = [FBSDKAccessTokenExpirer new];
  }
}

// Transitional singleton introduced as a way to change the usage semantics
// from a type-based interface to an instance-based interface.
// Once that is complete then types that use `+[FBSDKSettings foo]` can take an
// injectable instance of a `FBSDKSettings` until they no longer directly
// reference a settings type of any kind and instead refer to an injectable
// dependency for their actual use cases.
// The move will be:
// ClassWithoutUnderlyingInstance -> ClassRelyingOnUnderlyingInstance -> Instance
+ (instancetype)sharedSettings
{
  static id instance;
  dispatch_once(&sharedSettingsNonce, ^{
    instance = [self new];
  });
  return instance;
}

- (void)      configureWithStore:(id<FBSDKDataPersisting>)store
  appEventsConfigurationProvider:(Class<FBSDKAppEventsConfigurationProviding>)provider
          infoDictionaryProvider:(id<FBSDKInfoDictionaryProviding>)infoDictionaryProvider
                     eventLogger:(id<FBSDKEventLogging>)eventLogger
{
  self.store = store;
  self.appEventsConfigurationProvider = provider;
  self.infoDictionaryProvider = infoDictionaryProvider;
  self.eventLogger = eventLogger;
}

+ (void)      configureWithStore:(id<FBSDKDataPersisting>)store
  appEventsConfigurationProvider:(Class<FBSDKAppEventsConfigurationProviding>)provider
          infoDictionaryProvider:(id<FBSDKInfoDictionaryProviding>)infoDictionaryProvider
                     eventLogger:(id<FBSDKEventLogging>)eventLogger
{
  [self.sharedSettings configureWithStore:store
           appEventsConfigurationProvider:provider
                   infoDictionaryProvider:infoDictionaryProvider
                              eventLogger:eventLogger];
}

+ (id<FBSDKDataPersisting>)store
{
  return self.sharedSettings.store;
}

+ (Class<FBSDKAppEventsConfigurationProviding>)appEventsConfigurationProvider
{
  return self.sharedSettings.appEventsConfigurationProvider;
}

+ (id<FBSDKInfoDictionaryProviding>)infoDictionaryProvider
{
  return self.sharedSettings.infoDictionaryProvider;
}

+ (id<FBSDKEventLogging>)eventLogger
{
  return self.sharedSettings.eventLogger;
}

#pragma mark - Plist Configuration Settings

FBSDKSETTINGS_PLIST_CONFIGURATION_SETTING_IMPL(NSString, FacebookAppID, appID, setAppID, nil, NO);
FBSDKSETTINGS_PLIST_CONFIGURATION_SETTING_IMPL(NSString, FacebookUrlSchemeSuffix, appURLSchemeSuffix, setAppURLSchemeSuffix, nil, NO);
FBSDKSETTINGS_PLIST_CONFIGURATION_SETTING_IMPL(NSString, FacebookClientToken, clientToken, setClientToken, nil, NO);
FBSDKSETTINGS_PLIST_CONFIGURATION_SETTING_IMPL(NSString, FacebookDisplayName, displayName, setDisplayName, nil, NO);
FBSDKSETTINGS_PLIST_CONFIGURATION_SETTING_IMPL(NSString, FacebookDomainPart, facebookDomainPart, setFacebookDomainPart, nil, NO);
FBSDKSETTINGS_PLIST_CONFIGURATION_SETTING_IMPL(NSNumber, FacebookJpegCompressionQuality, _JPEGCompressionQualityNumber, _setJPEGCompressionQualityNumber, @0.9, NO);
FBSDKSETTINGS_PLIST_CONFIGURATION_SETTING_IMPL(NSNumber, FacebookInstrumentEnabled, _instrumentEnabled, _setInstrumentEnabled, @1, YES);
FBSDKSETTINGS_PLIST_CONFIGURATION_SETTING_IMPL(NSNumber, FacebookAutoLogAppEventsEnabled, _autoLogAppEventsEnabled, _setAutoLogAppEventsEnabled, @1, YES);
FBSDKSETTINGS_PLIST_CONFIGURATION_SETTING_IMPL(NSNumber, FacebookAdvertiserIDCollectionEnabled, _advertiserIDCollectionEnabled, _setAdvertiserIDCollectionEnabled, @1, YES);
FBSDKSETTINGS_PLIST_CONFIGURATION_SETTING_IMPL(NSNumber, FacebookSKAdNetworkReportEnabled, _SKAdNetworkReportEnabled, _setSKAdNetworkReportEnabled, @1, YES);
FBSDKSETTINGS_PLIST_CONFIGURATION_SETTING_IMPL(
  NSNumber,
  FacebookCodelessDebugLogEnabled,
  _codelessDebugLogEnabled,
  _setCodelessDebugLogEnabled,
  @0,
  YES
);

+ (BOOL)isGraphErrorRecoveryEnabled
{
  return !g_disableErrorRecovery;
}

+ (void)setGraphErrorRecoveryEnabled:(BOOL)graphErrorRecoveryEnabled
{
  g_disableErrorRecovery = !graphErrorRecoveryEnabled;
}

+ (CGFloat)JPEGCompressionQuality
{
  return self.sharedSettings._JPEGCompressionQualityNumber.floatValue;
}

+ (void)setJPEGCompressionQuality:(CGFloat)JPEGCompressionQuality
{
  [self.sharedSettings _setJPEGCompressionQualityNumber:@(JPEGCompressionQuality)];
}

+ (BOOL)isInstrumentEnabled
{
  return self.sharedSettings._instrumentEnabled.boolValue;
}

+ (void)setInstrumentEnabled:(BOOL)instrumentEnabled
{
  [self.sharedSettings _setInstrumentEnabled:@(instrumentEnabled)];
}

+ (BOOL)isCodelessDebugLogEnabled
{
  return self.sharedSettings._codelessDebugLogEnabled.boolValue;
}

+ (void)setCodelessDebugLogEnabled:(BOOL)codelessDebugLogEnabled
{
  [self.sharedSettings _setCodelessDebugLogEnabled:@(codelessDebugLogEnabled)];
}

+ (BOOL)isAutoLogAppEventsEnabled
{
  return [self.sharedSettings isAutoLogAppEventsEnabled];
}

- (BOOL)isAutoLogAppEventsEnabled
{
  return self._autoLogAppEventsEnabled.boolValue;
}

+ (void)setAutoLogAppEventsEnabled:(BOOL)autoLogAppEventsEnabled
{
  [self.sharedSettings _setAutoLogAppEventsEnabled:@(autoLogAppEventsEnabled)];
}

+ (BOOL)isAdvertiserIDCollectionEnabled
{
  return self.sharedSettings._advertiserIDCollectionEnabled.boolValue;
}

+ (void)setAdvertiserIDCollectionEnabled:(BOOL)advertiserIDCollectionEnabled
{
  [self.sharedSettings _setAdvertiserIDCollectionEnabled:@(advertiserIDCollectionEnabled)];
}

+ (BOOL)isAdvertiserTrackingEnabled
{
  return self.sharedSettings.isAdvertiserTrackingEnabled;
}

- (BOOL)isAdvertiserTrackingEnabled
{
  return self.advertisingTrackingStatus == FBSDKAdvertisingTrackingAllowed;
}

+ (BOOL)setAdvertiserTrackingEnabled:(BOOL)enabled;
{
  return [self.sharedSettings setAdvertiserTrackingEnabled:enabled];
}

- (BOOL)setAdvertiserTrackingEnabled:(BOOL)enabled;
{
  if (@available(iOS 14.0, *)) {
    [self setAdvertiserTrackingStatus:enabled ? FBSDKAdvertisingTrackingAllowed : FBSDKAdvertisingTrackingDisallowed];
    [self recordSetAdvertiserTrackingEnabled];
    return YES;
  } else {
    return NO;
  }
}

+ (FBSDKAdvertisingTrackingStatus)advertisingTrackingStatus
{
  return [self.sharedSettings advertisingTrackingStatus];
}

- (FBSDKAdvertisingTrackingStatus)advertisingTrackingStatus
{
  if (@available(iOS 14.0, *)) {
    if (self.advertiserTrackingStatusBacking == nil) {
      self.advertiserTrackingStatusBacking = [self.store objectForKey:FBSDKSettingsAdvertisingTrackingStatus];
      if (self.advertiserTrackingStatusBacking == nil) {
        return [[self.appEventsConfigurationProvider cachedAppEventsConfiguration] defaultATEStatus];
      }
    }
    return self.advertiserTrackingStatusBacking.unsignedIntegerValue;
  } else {
    // @lint-ignore CLANGTIDY
    return ASIdentifierManager.sharedManager.advertisingTrackingEnabled ? FBSDKAdvertisingTrackingAllowed : FBSDKAdvertisingTrackingDisallowed;
  }
}

+ (void)setAdvertiserTrackingStatus:(FBSDKAdvertisingTrackingStatus)status
{
  [self.sharedSettings setAdvertiserTrackingStatus:status];
}

- (void)setAdvertiserTrackingStatus:(FBSDKAdvertisingTrackingStatus)status
{
  self.advertiserTrackingStatusBacking = @(status);
  [self.store setObject:self.advertiserTrackingStatusBacking forKey:FBSDKSettingsAdvertisingTrackingStatus];
}

+ (BOOL)isSKAdNetworkReportEnabled
{
  return self.sharedSettings.isSKAdNetworkReportEnabled;
}

- (BOOL)isSKAdNetworkReportEnabled
{
  return [self _SKAdNetworkReportEnabled].boolValue;
}

+ (void)setSKAdNetworkReportEnabled:(BOOL)SKAdNetworkReportEnabled
{
  [self _setSKAdNetworkReportEnabled:@(SKAdNetworkReportEnabled)];
}

+ (BOOL)shouldLimitEventAndDataUsage
{
  return self.sharedSettings.shouldLimitEventAndDataUsage;
}

- (BOOL)shouldLimitEventAndDataUsage
{
  NSNumber *storedValue = [FBSDKSettings.store objectForKey:FBSDKSettingsLimitEventAndDataUsage];
  if (storedValue == nil) {
    return NO;
  }
  return storedValue.boolValue;
}

+ (void)setLimitEventAndDataUsage:(BOOL)limitEventAndDataUsage
{
  [self.sharedSettings setLimitEventAndDataUsage:limitEventAndDataUsage];
}

- (void)setLimitEventAndDataUsage:(BOOL)limitEventAndDataUsage
{
  [_store setObject:@(limitEventAndDataUsage) forKey:FBSDKSettingsLimitEventAndDataUsage];
}

+ (BOOL)shouldUseCachedValuesForExpensiveMetadata
{
  NSNumber *storedValue = [self.store objectForKey:FBSDKSettingsUseCachedValuesForExpensiveMetadata];
  if (storedValue == nil) {
    return NO;
  }
  return storedValue.boolValue;
}

+ (void)setShouldUseCachedValuesForExpensiveMetadata:(BOOL)shouldUseCachedValuesForExpensiveMetadata
{
  [self.store setObject:@(shouldUseCachedValuesForExpensiveMetadata) forKey:FBSDKSettingsUseCachedValuesForExpensiveMetadata];
}

- (BOOL)shouldUseTokenOptimizations
{
  NSNumber *storedValue = [self.store objectForKey:FBSDKSettingsUseTokenOptimizations];
  if (storedValue == nil) {
    return YES;
  }
  return storedValue.boolValue;
}

- (void)setShouldUseTokenOptimizations:(BOOL)shouldUseTokenOptimizations
{
  [self.store setObject:@(shouldUseTokenOptimizations) forKey:FBSDKSettingsUseTokenOptimizations];
}

+ (NSSet<FBSDKLoggingBehavior> *)loggingBehaviors
{
  if (!g_loggingBehaviors) {
    NSArray<FBSDKLoggingBehavior> *bundleLoggingBehaviors = [self.sharedSettings.infoDictionaryProvider objectForInfoDictionaryKey:@"FacebookLoggingBehavior"];
    if (bundleLoggingBehaviors) {
      g_loggingBehaviors = [[NSMutableSet alloc] initWithArray:bundleLoggingBehaviors];
    } else {
      // Establish set of default enabled logging behaviors.  You can completely disable logging by
      // specifying an empty array for FacebookLoggingBehavior in your Info.plist.
      g_loggingBehaviors = [[NSMutableSet alloc] initWithObjects:FBSDKLoggingBehaviorDeveloperErrors, nil];
    }
  }
  return [g_loggingBehaviors copy];
}

- (NSSet<FBSDKLoggingBehavior> *)loggingBehaviors
{
  return [self.class loggingBehaviors];
}

+ (void)setDataProcessingOptions:(nullable NSArray<NSString *> *)options
{
  [FBSDKSettings setDataProcessingOptions:options country:0 state:0];
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
+ (void)setDataProcessingOptions:(nullable NSArray<NSString *> *)options
                         country:(int)country
                           state:(int)state
{
  NSDictionary<NSString *, id> *json = @{
    DATA_PROCESSING_OPTIONS : options ?: @[],
    DATA_PROCESSING_OPTIONS_COUNTRY : @(country),
    DATA_PROCESSING_OPTIONS_STATE : @(state),
  };
  g_dataProcessingOptions = json;
  NSData *data = [NSKeyedArchiver archivedDataWithRootObject:g_dataProcessingOptions];
  if (data) {
    [self.store setObject:data
                   forKey:FBSDKSettingsDataProcessingOptions];
  }
}

#pragma clang diagnostic pop

+ (void)setLoggingBehaviors:(NSSet<FBSDKLoggingBehavior> *)loggingBehaviors
{
  if (![g_loggingBehaviors isEqualToSet:loggingBehaviors]) {
    g_loggingBehaviors = [loggingBehaviors mutableCopy];

    [self updateGraphAPIDebugBehavior];
  }
}

+ (void)enableLoggingBehavior:(FBSDKLoggingBehavior)loggingBehavior
{
  if (!g_loggingBehaviors) {
    [self loggingBehaviors];
  }
  [g_loggingBehaviors addObject:loggingBehavior];
  [self updateGraphAPIDebugBehavior];
}

+ (void)disableLoggingBehavior:(FBSDKLoggingBehavior)loggingBehavior
{
  if (!g_loggingBehaviors) {
    [self loggingBehaviors];
  }
  [g_loggingBehaviors removeObject:loggingBehavior];
  [self updateGraphAPIDebugBehavior];
}

#pragma mark - Readonly Configuration Settings

+ (NSString *)sdkVersion
{
  return FBSDK_VERSION_STRING;
}

#pragma mark - Internal

+ (NSString *)userAgentSuffix
{
  return g_userAgentSuffix;
}

+ (void)setUserAgentSuffix:(NSString *)suffix
{
  if (![g_userAgentSuffix isEqualToString:suffix]) {
    g_userAgentSuffix = suffix;
  }
}

+ (void)setGraphAPIVersion:(NSString *)version
{
  if (![g_defaultGraphAPIVersion isEqualToString:version]) {
    g_defaultGraphAPIVersion = version;
  }
}

+ (NSString *)defaultGraphAPIVersion
{
  return FBSDK_TARGET_PLATFORM_VERSION;
}

+ (NSString *)graphAPIVersion
{
  return g_defaultGraphAPIVersion ?: self.defaultGraphAPIVersion;
}

+ (NSNumber *)appEventSettingsForPlistKey:(NSString *)plistKey
                             defaultValue:(NSNumber *)defaultValue
{
  return [[[NSBundle mainBundle] objectForInfoDictionaryKey:plistKey] copy] ?: defaultValue;
}

+ (NSNumber *)appEventSettingsForUserDefaultsKey:(NSString *)userDefaultsKey
                                    defaultValue:(NSNumber *)defaultValue
{
  NSData *data = [self.store objectForKey:userDefaultsKey];
  if ([data isKindOfClass:[NSNumber class]]) {
    return (NSNumber *)data;
  }
  return defaultValue;
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
+ (NSDictionary<NSString *, id> *)dataProcessingOptions
{
  if (!g_dataProcessingOptions) {
    NSData *data = [self.store objectForKey:FBSDKSettingsDataProcessingOptions];
    if ([data isKindOfClass:[NSData class]]) {
      NSDictionary<NSString *, id> *dataProcessingOptions = [NSKeyedUnarchiver unarchiveObjectWithData:data];
      if (dataProcessingOptions && [dataProcessingOptions isKindOfClass:[NSDictionary class]]) {
        g_dataProcessingOptions = dataProcessingOptions;
      }
    }
  }
  return g_dataProcessingOptions;
}

#pragma clang diagnostic pop

+ (BOOL)isDataProcessingRestricted
{
  return [self.sharedSettings isDataProcessingRestricted];
}

- (BOOL)isDataProcessingRestricted
{
  NSArray<NSString *> *options = [FBSDKTypeUtility dictionary:[FBSDKSettings dataProcessingOptions]
                                                 objectForKey:DATA_PROCESSING_OPTIONS
                                                       ofType:NSArray.class];
  for (NSString *option in options) {
    if ([@"ldu" isEqualToString:[[FBSDKTypeUtility coercedToStringValue:option] lowercaseString]]) {
      return YES;
    }
  }
  return NO;
}

+ (void)logWarnings
{
  [self.sharedSettings logWarnings];
}

- (void)logWarnings
{
  // Log warnings for App Event Flags
  if (![self.infoDictionaryProvider objectForInfoDictionaryKey:@"FacebookAutoLogAppEventsEnabled"]) {
    NSLog(autoLogAppEventsEnabledNotSetWarning);
  }
  if (![self.infoDictionaryProvider objectForInfoDictionaryKey:@"FacebookAdvertiserIDCollectionEnabled"]) {
    NSLog(advertiserIDCollectionEnabledNotSetWarning);
  }
  if (!self._advertiserIDCollectionEnabled.boolValue) {
    NSLog(advertiserIDCollectionEnabledFalseWarning);
  }
}

+ (void)logIfSDKSettingsChanged
{
  [self.sharedSettings logIfSDKSettingsChanged];
}

- (void)logIfSDKSettingsChanged
{
  NSInteger bitmask = 0;
  // Starting at 1 to maintain the meaning of the bits since the autoInit flag was removed.
  NSInteger bit = 1;
  bitmask |= (self._autoLogAppEventsEnabled.boolValue ? 1 : 0) << bit++;
  bitmask |= (self._advertiserIDCollectionEnabled.boolValue ? 1 : 0) << bit++;

  NSInteger previousBitmask = [self.store integerForKey:FBSDKSettingsBitmask];
  if (previousBitmask != bitmask) {
    [self.store setInteger:bitmask forKey:FBSDKSettingsBitmask];

    NSArray<NSString *> *keys = @[@"FacebookAutoLogAppEventsEnabled",
                                  @"FacebookAdvertiserIDCollectionEnabled"];
    NSArray<NSNumber *> *defaultValues = @[@YES, @YES];
    NSInteger initialBitmask = 0;
    NSInteger usageBitmask = 0;
    for (int i = 0; i < keys.count; i++) {
      NSNumber *plistValue = [self.infoDictionaryProvider objectForInfoDictionaryKey:[FBSDKTypeUtility array:keys objectAtIndex:i]];
      BOOL initialValue = [(plistValue ?: [FBSDKTypeUtility array:defaultValues objectAtIndex:i]) boolValue];
      initialBitmask |= (initialValue ? 1 : 0) << i;
      usageBitmask |= (plistValue != nil ? 1 : 0) << i;
    }
    [self.eventLogger logInternalEvent:@"fb_sdk_settings_changed"
                            parameters:@{@"usage" : @(usageBitmask),
                                         @"initial" : @(initialBitmask),
                                         @"previous" : @(previousBitmask),
                                         @"current" : @(bitmask)}
                    isImplicitlyLogged:YES];
  }
}

+ (void)recordInstall
{
  if (![self.store objectForKey:FBSDKSettingsInstallTimestamp]) {
    [self.store setObject:[NSDate date] forKey:FBSDKSettingsInstallTimestamp];
  }
}

+ (void)recordSetAdvertiserTrackingEnabled
{
  [self.sharedSettings recordSetAdvertiserTrackingEnabled];
}

- (void)recordSetAdvertiserTrackingEnabled
{
  [self.store setObject:[NSDate date] forKey:FBSDKSettingsSetAdvertiserTrackingEnabledTimestamp];
}

+ (BOOL)isEventDelayTimerExpired
{
  NSDate *timestamp = [self.store objectForKey:FBSDKSettingsInstallTimestamp];
  if (timestamp) {
    return [[NSDate date] timeIntervalSinceDate:timestamp] > 86400;
  }
  return NO;
}

+ (BOOL)isSetATETimeExceedsInstallTime
{
  return [self.sharedSettings isSetATETimeExceedsInstallTime];
}

- (BOOL)isSetATETimeExceedsInstallTime
{
  NSDate *installTimestamp = [self installTimestamp];
  NSDate *setATETimestamp = [self advertiserTrackingEnabledTimestamp];
  if (installTimestamp && setATETimestamp) {
    return [setATETimestamp timeIntervalSinceDate:installTimestamp] > 86400;
  }
  return NO;
}

+ (NSDate *_Nullable)getInstallTimestamp
{
  return self.sharedSettings.installTimestamp;
}

- (NSDate *_Nullable)installTimestamp
{
  return [self.store objectForKey:FBSDKSettingsInstallTimestamp];
}

+ (NSDate *_Nullable)getSetAdvertiserTrackingEnabledTimestamp
{
  return [self.sharedSettings advertiserTrackingEnabledTimestamp];
}

- (NSDate *_Nullable)advertiserTrackingEnabledTimestamp
{
  return [self.store objectForKey:FBSDKSettingsSetAdvertiserTrackingEnabledTimestamp];
}

#pragma mark - Internal - Graph API Debug

+ (void)updateGraphAPIDebugBehavior
{
  // Enable Warnings everytime Info is enabled
  if ([g_loggingBehaviors containsObject:FBSDKLoggingBehaviorGraphAPIDebugInfo]
      && ![g_loggingBehaviors containsObject:FBSDKLoggingBehaviorGraphAPIDebugWarning]) {
    [g_loggingBehaviors addObject:FBSDKLoggingBehaviorGraphAPIDebugWarning];
  }
}

+ (NSString *)graphAPIDebugParamValue
{
  if ([[self loggingBehaviors] containsObject:FBSDKLoggingBehaviorGraphAPIDebugInfo]) {
    return @"info";
  } else if ([[self loggingBehaviors] containsObject:FBSDKLoggingBehaviorGraphAPIDebugWarning]) {
    return @"warning";
  }

  return nil;
}

#pragma mark - Testability

#if DEBUG
 #if FBSDKTEST

+ (void)reset
{
  [self.sharedSettings reset];

  g_loggingBehaviors = nil;
  g_userAgentSuffix = nil;
  g_dataProcessingOptions = nil;
}

- (void)reset
{
  // Reset the nonce so that a new instance will be created.
  if (sharedSettingsNonce) {
    sharedSettingsNonce = 0;
  }
}

+ (void)setInfoDictionaryProvider:(id<FBSDKInfoDictionaryProviding>)provider
{
  self.sharedSettings.infoDictionaryProvider = provider;
}

 #endif
#endif

@end
