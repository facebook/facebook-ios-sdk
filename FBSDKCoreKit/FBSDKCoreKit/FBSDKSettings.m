/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "FBSDKSettings+Internal.h"

#import <AdSupport/AdSupport.h>

#import <FBSDKCoreKit_Basics/FBSDKCoreKit_Basics.h>

#import "FBSDKAppEventsConfigurationProtocol.h"
#import "FBSDKAppEventsConfigurationProviding.h"
#import "FBSDKCoreKitVersions.h"
#import "FBSDKDataPersisting.h"
#import "FBSDKEventLogging.h"
#import "FBSDKInternalUtility+Internal.h"

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
    [self validateConfiguration];  \
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

static NSString *const FBSDKSettingsLimitEventAndDataUsage = @"com.facebook.sdk:FBSDKSettingsLimitEventAndDataUsage";
static NSString *const FBSDKSettingsBitmask = @"com.facebook.sdk:FBSDKSettingsBitmask";
static NSString *const FBSDKSettingsDataProcessingOptions = @"com.facebook.sdk:FBSDKSettingsDataProcessingOptions";
static NSString *const FBSDKSettingsAdvertisingTrackingStatus = @"com.facebook.sdk:FBSDKSettingsAdvertisingTrackingStatus";
static NSString *const FBSDKSettingsInstallTimestamp = @"com.facebook.sdk:FBSDKSettingsInstallTimestamp";
static NSString *const FBSDKSettingsSetAdvertiserTrackingEnabledTimestamp = @"com.facebook.sdk:FBSDKSettingsSetAdvertiserTrackingEnabledTimestamp";
static NSString *const FBSDKSettingsUseCachedValuesForExpensiveMetadata = @"com.facebook.sdk:FBSDKSettingsUseCachedValuesForExpensiveMetadata";
static NSString *const FBSDKSettingsUseTokenOptimizations = @"com.facebook.sdk.FBSDKSettingsUseTokenOptimizations";
static NSString *const FacebookSKAdNetworkReportEnabled = @"FacebookSKAdNetworkReportEnabled";

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
@property (nullable, nonatomic) id<FBSDKAppEventsConfigurationProviding> appEventsConfigurationProvider;
@property (nullable, nonatomic) id<FBSDKInfoDictionaryProviding> infoDictionaryProvider;
@property (nullable, nonatomic) id<FBSDKEventLogging> eventLogger;
@property (nullable, nonatomic) NSNumber *advertiserTrackingStatusBacking;
@property (nonatomic) BOOL isConfigured;
@property (nullable, nonatomic) NSDictionary<NSString *, id> *persistableDataProcessingOptions;
@end

@implementation FBSDKSettings
{
  FBSDKSETTINGS_PLIST_CONFIGURATION_SETTING_IVAR_DECL(NSString, appURLSchemeSuffix);
  FBSDKSETTINGS_PLIST_CONFIGURATION_SETTING_IVAR_DECL(NSString, clientToken);
  FBSDKSETTINGS_PLIST_CONFIGURATION_SETTING_IVAR_DECL(NSString, displayName);
  FBSDKSETTINGS_PLIST_CONFIGURATION_SETTING_IVAR_DECL(NSString, facebookDomainPart);
  FBSDKSETTINGS_PLIST_CONFIGURATION_SETTING_IVAR_DECL(NSNumber, _instrumentEnabled);
  FBSDKSETTINGS_PLIST_CONFIGURATION_SETTING_IVAR_DECL(NSNumber, _autoLogAppEventsEnabled);
  FBSDKSETTINGS_PLIST_CONFIGURATION_SETTING_IVAR_DECL(NSNumber, _advertiserIDCollectionEnabled);
  FBSDKSETTINGS_PLIST_CONFIGURATION_SETTING_IVAR_DECL(NSNumber, _codelessDebugLogEnabled);
  NSMutableSet<FBSDKLoggingBehavior> *_loggingBehaviors;
  NSNumber *_SKAdNetworkReportEnabled;
}

@synthesize userAgentSuffix = _userAgentSuffix;
@synthesize appID = _appID;
@synthesize JPEGCompressionQuality = _JPEGCompressionQuality;
@synthesize loggingBehaviors = _loggingBehaviors;
static dispatch_once_t sharedSettingsNonce;

- (instancetype)init
{
  if ((self = [super init])) {
    _isGraphErrorRecoveryEnabled = YES;
    _graphAPIVersion = [self defaultGraphAPIVersion];
  }

  return self;
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
  appEventsConfigurationProvider:(id<FBSDKAppEventsConfigurationProviding>)provider
          infoDictionaryProvider:(id<FBSDKInfoDictionaryProviding>)infoDictionaryProvider
                     eventLogger:(id<FBSDKEventLogging>)eventLogger
{
  self.store = store;
  self.appEventsConfigurationProvider = provider;
  self.infoDictionaryProvider = infoDictionaryProvider;
  self.eventLogger = eventLogger;

  self.isConfigured = YES;
}

+ (void)      configureWithStore:(id<FBSDKDataPersisting>)store
  appEventsConfigurationProvider:(id<FBSDKAppEventsConfigurationProviding>)provider
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

+ (id<FBSDKInfoDictionaryProviding>)infoDictionaryProvider
{
  return self.sharedSettings.infoDictionaryProvider;
}

+ (id<FBSDKEventLogging>)eventLogger
{
  return self.sharedSettings.eventLogger;
}

#pragma mark - Plist Configuration Settings

FBSDKSETTINGS_PLIST_CONFIGURATION_SETTING_IMPL(NSString, FacebookUrlSchemeSuffix, appURLSchemeSuffix, setAppURLSchemeSuffix, nil, NO);
FBSDKSETTINGS_PLIST_CONFIGURATION_SETTING_IMPL(NSString, FacebookClientToken, clientToken, setClientToken, nil, NO);
FBSDKSETTINGS_PLIST_CONFIGURATION_SETTING_IMPL(NSString, FacebookDisplayName, displayName, setDisplayName, nil, NO);
FBSDKSETTINGS_PLIST_CONFIGURATION_SETTING_IMPL(NSString, FacebookDomainPart, facebookDomainPart, setFacebookDomainPart, nil, NO);
FBSDKSETTINGS_PLIST_CONFIGURATION_SETTING_IMPL(NSNumber, FacebookInstrumentEnabled, _instrumentEnabled, _setInstrumentEnabled, @1, YES);
FBSDKSETTINGS_PLIST_CONFIGURATION_SETTING_IMPL(NSNumber, FacebookAutoLogAppEventsEnabled, _autoLogAppEventsEnabled, _setAutoLogAppEventsEnabled, @1, YES);
FBSDKSETTINGS_PLIST_CONFIGURATION_SETTING_IMPL(NSNumber, FacebookAdvertiserIDCollectionEnabled, _advertiserIDCollectionEnabled, _setAdvertiserIDCollectionEnabled, @1, YES);
FBSDKSETTINGS_PLIST_CONFIGURATION_SETTING_IMPL(
  NSNumber,
  FacebookCodelessDebugLogEnabled,
  _codelessDebugLogEnabled,
  _setCodelessDebugLogEnabled,
  @0,
  YES
);

- (NSString *)appID
{
  if (!_appID) {
    _appID = [[self.infoDictionaryProvider objectForInfoDictionaryKey:@"FacebookAppID"] copy] ?: nil;
  }
  return _appID;
}

- (void)setAppID:(NSString *)appID
{
  [self validateConfiguration];
  _appID = [appID copy];
  [self logIfSDKSettingsChanged];
}

- (CGFloat)JPEGCompressionQuality
{
  if (!_JPEGCompressionQuality) {
    NSNumber *compressionQuality = [self.infoDictionaryProvider objectForInfoDictionaryKey:@"FacebookJpegCompressionQuality"];
    _JPEGCompressionQuality = [self _validateJPEGCompressionQuality:compressionQuality.floatValue ?: 0.9];
  }
  return _JPEGCompressionQuality;
}

- (void)setJPEGCompressionQuality:(CGFloat)JPEGCompressionQuality
{
  [self validateConfiguration];

  _JPEGCompressionQuality = [self _validateJPEGCompressionQuality:JPEGCompressionQuality];
  [self logIfSDKSettingsChanged];
}

+ (NSString *)appID
{
  return self.sharedSettings.appID;
}

+ (void)setAppID:(NSString *)appID
{
  self.sharedSettings.appID = appID;
}

+ (BOOL)isGraphErrorRecoveryEnabled
{
  return self.sharedSettings.isGraphErrorRecoveryEnabled;
}

+ (void)setGraphErrorRecoveryEnabled:(BOOL)graphErrorRecoveryEnabled
{
  [self.sharedSettings setIsGraphErrorRecoveryEnabled:graphErrorRecoveryEnabled];
}

+ (CGFloat)JPEGCompressionQuality
{
  return self.sharedSettings.JPEGCompressionQuality;
}

+ (void)setJPEGCompressionQuality:(CGFloat)JPEGCompressionQuality
{
  [self.sharedSettings setJPEGCompressionQuality:JPEGCompressionQuality];
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

- (BOOL)isCodelessDebugLogEnabled
{
  return self._codelessDebugLogEnabled.boolValue;
}

+ (void)setCodelessDebugLogEnabled:(BOOL)codelessDebugLogEnabled
{
  [self.sharedSettings setCodelessDebugLogEnabled:codelessDebugLogEnabled];
}

- (void)setCodelessDebugLogEnabled:(BOOL)codelessDebugLogEnabled
{
  [self _setCodelessDebugLogEnabled:@(codelessDebugLogEnabled)];
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
  [self.sharedSettings setAutoLogAppEventsEnabled:autoLogAppEventsEnabled];
}

- (void)setAutoLogAppEventsEnabled:(BOOL)autoLogAppEventsEnabled
{
  [self _setAutoLogAppEventsEnabled:@(autoLogAppEventsEnabled)];
}

+ (BOOL)isAdvertiserIDCollectionEnabled
{
  return self.sharedSettings.isAdvertiserIDCollectionEnabled;
}

- (BOOL)isAdvertiserIDCollectionEnabled
{
  return self._advertiserIDCollectionEnabled.boolValue;
}

+ (void)setAdvertiserIDCollectionEnabled:(BOOL)advertiserIDCollectionEnabled
{
  [self.sharedSettings setAdvertiserIDCollectionEnabled:advertiserIDCollectionEnabled];
}

- (void)setAdvertiserIDCollectionEnabled:(BOOL)advertiserIDCollectionEnabled
{
  [self _setAdvertiserIDCollectionEnabled:@(advertiserIDCollectionEnabled)];
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
  if (@available(iOS 14.0, *)) {
    [self.sharedSettings setAdvertiserTrackingEnabled:enabled];
    return YES;
  } else {
    return NO;
  }
}

- (void)setAdvertiserTrackingEnabled:(BOOL)advertiserTrackingEnabled
{
  if (@available(iOS 14.0, *)) {
    [self setAdvertiserTrackingStatus:advertiserTrackingEnabled ? FBSDKAdvertisingTrackingAllowed : FBSDKAdvertisingTrackingDisallowed];
    [self recordSetAdvertiserTrackingEnabled];
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
  if (_SKAdNetworkReportEnabled == nil) {
    _SKAdNetworkReportEnabled = [[self.store objectForKey:FacebookSKAdNetworkReportEnabled] copy];
  }

  if (_SKAdNetworkReportEnabled == nil) {
    _SKAdNetworkReportEnabled = [[self.infoDictionaryProvider objectForInfoDictionaryKey:FacebookSKAdNetworkReportEnabled] copy] ?: @(1);
  }

  return _SKAdNetworkReportEnabled.boolValue;
}

- (void)setSkAdNetworkReportEnabled:(BOOL)skAdNetworkReportEnabled
{
  [self validateConfiguration];
  _SKAdNetworkReportEnabled = @(skAdNetworkReportEnabled);
  [self.store setObject:@(skAdNetworkReportEnabled) forKey:FacebookSKAdNetworkReportEnabled];
  [self logIfSDKSettingsChanged];
}

+ (void)setSKAdNetworkReportEnabled:(BOOL)SKAdNetworkReportEnabled
{
  [self.sharedSettings setSkAdNetworkReportEnabled:SKAdNetworkReportEnabled];
}

+ (BOOL)shouldLimitEventAndDataUsage
{
  return self.sharedSettings.isEventDataUsageLimited;
}

- (BOOL)isEventDataUsageLimited
{
  NSNumber *storedValue = [FBSDKSettings.store objectForKey:FBSDKSettingsLimitEventAndDataUsage];
  if (storedValue == nil) {
    return NO;
  }
  return storedValue.boolValue;
}

+ (void)setLimitEventAndDataUsage:(BOOL)limitEventAndDataUsage
{
  [self.sharedSettings setIsEventDataUsageLimited:limitEventAndDataUsage];
}

- (void)setIsEventDataUsageLimited:(BOOL)isEventDataUsageLimited
{
  [_store setObject:@(isEventDataUsageLimited) forKey:FBSDKSettingsLimitEventAndDataUsage];
}

+ (BOOL)shouldUseCachedValuesForExpensiveMetadata
{
  return [self.sharedSettings shouldUseCachedValuesForExpensiveMetadata];
}

+ (void)setShouldUseCachedValuesForExpensiveMetadata:(BOOL)shouldUseCachedValuesForExpensiveMetadata
{
  [self setShouldUseCachedValuesForExpensiveMetadata:shouldUseCachedValuesForExpensiveMetadata];
}

- (BOOL)shouldUseCachedValuesForExpensiveMetadata
{
  NSNumber *storedValue = [self.store objectForKey:FBSDKSettingsUseCachedValuesForExpensiveMetadata];
  if (storedValue == nil) {
    return NO;
  }
  return storedValue.boolValue;
}

- (void)setShouldUseCachedValuesForExpensiveMetadata:(BOOL)shouldUseCachedValuesForExpensiveMetadata
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
  return [self.sharedSettings loggingBehaviors];
}

+ (void)setLoggingBehaviors:(NSSet<FBSDKLoggingBehavior> *)loggingBehaviors
{
  [self.sharedSettings setLoggingBehaviors:loggingBehaviors];
}

- (void)setLoggingBehaviors:(NSSet<FBSDKLoggingBehavior> *)loggingBehaviors
{
  if (![_loggingBehaviors isEqualToSet:loggingBehaviors]) {
    _loggingBehaviors = [loggingBehaviors mutableCopy];

    [self updateGraphAPIDebugBehavior];
  }
}

- (NSSet<FBSDKLoggingBehavior> *)loggingBehaviors
{
  if (!_loggingBehaviors) {
    NSArray<FBSDKLoggingBehavior> *bundleLoggingBehaviors = [self.infoDictionaryProvider objectForInfoDictionaryKey:@"FacebookLoggingBehavior"];
    if (bundleLoggingBehaviors) {
      _loggingBehaviors = [[NSMutableSet alloc] initWithArray:bundleLoggingBehaviors];
    } else {
      // Establish set of default enabled logging behaviors.  You can completely disable logging by
      // specifying an empty array for FacebookLoggingBehavior in your Info.plist.
      _loggingBehaviors = [[NSMutableSet alloc] initWithObjects:FBSDKLoggingBehaviorDeveloperErrors, nil];
    }
  }
  return [_loggingBehaviors copy];
}

+ (void)setDataProcessingOptions:(nullable NSArray<NSString *> *)options
{
  [self.sharedSettings setDataProcessingOptions:options];
}

- (void)setDataProcessingOptions:(nullable NSArray<NSString *> *)options
{
  [self setDataProcessingOptions:options country:0 state:0];
}

+ (void)setDataProcessingOptions:(nullable NSArray<NSString *> *)options
                         country:(int)country
                           state:(int)state
{
  [self.sharedSettings setDataProcessingOptions:options country:country state:state];
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
- (void)setDataProcessingOptions:(nullable NSArray<NSString *> *)options
                         country:(int)country
                           state:(int)state
{
  NSDictionary<NSString *, id> *json = @{
    DATA_PROCESSING_OPTIONS : options ?: @[],
    DATA_PROCESSING_OPTIONS_COUNTRY : @(country),
    DATA_PROCESSING_OPTIONS_STATE : @(state),
  };
  self.persistableDataProcessingOptions = json;
  NSData *data = [NSKeyedArchiver archivedDataWithRootObject:json];
  if (data) {
    [self.store setObject:data
                   forKey:FBSDKSettingsDataProcessingOptions];
  }
}

#pragma clang diagnostic pop

+ (void)enableLoggingBehavior:(FBSDKLoggingBehavior)loggingBehavior
{
  [self.sharedSettings enableLoggingBehavior:loggingBehavior];
}

+ (void)disableLoggingBehavior:(FBSDKLoggingBehavior)loggingBehavior
{
  [self.sharedSettings disableLoggingBehavior:loggingBehavior];
}

- (void)enableLoggingBehavior:(FBSDKLoggingBehavior)loggingBehavior
{
  if (!self.loggingBehaviors) {
    [self loggingBehaviors];
  }
  [_loggingBehaviors addObject:loggingBehavior];
  [self updateGraphAPIDebugBehavior];
}

- (void)disableLoggingBehavior:(FBSDKLoggingBehavior)loggingBehavior
{
  if (!self.loggingBehaviors) {
    [self loggingBehaviors];
  }
  [_loggingBehaviors removeObject:loggingBehavior];
  [self updateGraphAPIDebugBehavior];
}

// MARK: - Helper methods

- (CGFloat)_validateJPEGCompressionQuality:(CGFloat)JPEGCompressionQuality
{
  return MIN(MAX(0, JPEGCompressionQuality), 1);
}

#pragma mark - Readonly Configuration Settings

- (NSString *)sdkVersion
{
  return FBSDK_VERSION_STRING;
}

+ (NSString *)sdkVersion
{
  return self.sharedSettings.sdkVersion;
}

#pragma mark - Configuration Validation

- (void)validateConfiguration
{
#if DEBUG
  if (!self.isConfigured) {
    static NSString *const reason = @"As of v9.0, you must initialize the SDK prior to calling any methods or setting any properties. "
    "You can do this by calling `FBSDKApplicationDelegate`'s `application:didFinishLaunchingWithOptions:` method."
    "Learn more: https://developers.facebook.com/docs/ios/getting-started"
    "If no `UIApplication` is available you can use `FBSDKApplicationDelegate`'s `initializeSDK` method.";
    @throw [NSException exceptionWithName:@"InvalidOperationException" reason:reason userInfo:nil];
  }
#endif
}

#pragma mark - Internal

+ (void)setGraphAPIVersion:(NSString *)version
{
  self.sharedSettings.graphAPIVersion = version ?: self.sharedSettings.defaultGraphAPIVersion;
}

+ (NSString *)defaultGraphAPIVersion
{
  return self.sharedSettings.defaultGraphAPIVersion;
}

- (NSString *)defaultGraphAPIVersion
{
  return FBSDK_DEFAULT_GRAPH_API_VERSION;
}

+ (NSString *)graphAPIVersion
{
  return self.sharedSettings.graphAPIVersion;
}

+ (NSNumber *)appEventSettingsForPlistKey:(NSString *)plistKey
                             defaultValue:(NSNumber *)defaultValue
{
  return [[NSBundle.mainBundle objectForInfoDictionaryKey:plistKey] copy] ?: defaultValue;
}

+ (NSNumber *)appEventSettingsForUserDefaultsKey:(NSString *)userDefaultsKey
                                    defaultValue:(NSNumber *)defaultValue
{
  NSData *data = [self.store objectForKey:userDefaultsKey];
  if ([data isKindOfClass:NSNumber.class]) {
    return (NSNumber *)data;
  }
  return defaultValue;
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
- (NSDictionary<NSString *, id> *)persistableDataProcessingOptions
{
  if (!_persistableDataProcessingOptions) {
    NSData *data = [self.store objectForKey:FBSDKSettingsDataProcessingOptions];
    if (data && [data isKindOfClass:NSData.class]) {
      if (@available(iOS 11.0, tvOS 11.0, *)) {
        _persistableDataProcessingOptions = [NSKeyedUnarchiver unarchivedObjectOfClasses:[NSSet setWithArray:@[NSString.class, NSNumber.class, NSArray.class, NSDictionary.class, NSSet.class]] fromData:data error:nil];
      } else {
        NSDictionary<NSString *, id> *persistableDataProcessingOptions = [NSKeyedUnarchiver unarchiveObjectWithData:data];
        if (persistableDataProcessingOptions && [persistableDataProcessingOptions isKindOfClass:[NSDictionary<NSString *, id> class]]) {
          _persistableDataProcessingOptions = persistableDataProcessingOptions;
        }
      }
    }
  }
  return _persistableDataProcessingOptions;
}

#pragma clang diagnostic pop

+ (BOOL)isDataProcessingRestricted
{
  return [self.sharedSettings isDataProcessingRestricted];
}

- (BOOL)isDataProcessingRestricted
{
  NSArray<NSString *> *options = [FBSDKTypeUtility dictionary:self.persistableDataProcessingOptions ?: @{}
                                                 objectForKey:DATA_PROCESSING_OPTIONS
                                                       ofType:NSArray.class];
  for (NSString *option in options) {
    if ([@"ldu" isEqualToString:[[FBSDKTypeUtility coercedToStringValue:option] lowercaseString]]) {
      return YES;
    }
  }
  return NO;
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

- (void)recordInstall
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

- (void)updateGraphAPIDebugBehavior
{
  // Enable Warnings everytime Info is enabled
  if ([self.loggingBehaviors containsObject:FBSDKLoggingBehaviorGraphAPIDebugInfo]
      && ![self.loggingBehaviors containsObject:FBSDKLoggingBehaviorGraphAPIDebugWarning]) {
    [_loggingBehaviors addObject:FBSDKLoggingBehaviorGraphAPIDebugWarning];
  }
}

+ (nullable NSString *)graphAPIDebugParamValue
{
  if ([[self.sharedSettings loggingBehaviors] containsObject:FBSDKLoggingBehaviorGraphAPIDebugInfo]) {
    return @"info";
  } else if ([[self.sharedSettings loggingBehaviors] containsObject:FBSDKLoggingBehaviorGraphAPIDebugWarning]) {
    return @"warning";
  }

  return nil;
}

- (NSString *)graphAPIDebugParamValue
{
  return [self.class graphAPIDebugParamValue];
}

#pragma mark - Testability

#if DEBUG && FBTEST

- (void)reset
{
  // Reset the nonce so that a new instance will be created.
  if (sharedSettingsNonce) {
    sharedSettingsNonce = 0;
  }
  _loggingBehaviors = nil;
  self.persistableDataProcessingOptions = nil;
}

+ (void)setInfoDictionaryProvider:(id<FBSDKInfoDictionaryProviding>)provider
{
  self.sharedSettings.infoDictionaryProvider = provider;
}

#endif

@end
