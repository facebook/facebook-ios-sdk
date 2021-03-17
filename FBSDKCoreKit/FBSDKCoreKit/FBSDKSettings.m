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
#import "FBSDKDataPersisting.h"
#import "FBSDKInternalUtility.h"

#define FBSDKSETTINGS_PLIST_CONFIGURATION_SETTING_IMPL(TYPE, PLIST_KEY, GETTER, SETTER, DEFAULT_VALUE, ENABLE_CACHE) \
  static TYPE *g_ ## PLIST_KEY = nil; \
  + (TYPE *)GETTER \
  { \
    if ((g_ ## PLIST_KEY == nil) && ENABLE_CACHE) { \
      g_ ## PLIST_KEY = [[_store objectForKey:@#PLIST_KEY] copy]; \
    } \
    if (g_ ## PLIST_KEY == nil) { \
      g_ ## PLIST_KEY = [[[NSBundle mainBundle] objectForInfoDictionaryKey:@#PLIST_KEY] copy] ?: DEFAULT_VALUE; \
    } \
    return g_ ## PLIST_KEY; \
  } \
  + (void)SETTER:(TYPE *)value { \
    g_ ## PLIST_KEY = [value copy]; \
    if (ENABLE_CACHE) { \
      if (value != nil) { \
        [_store setObject:value forKey:@#PLIST_KEY]; \
      } else { \
        [_store removeObjectForKey:@#PLIST_KEY]; \
      } \
    } \
    [FBSDKSettings _logIfSDKSettingsChanged]; \
  }

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
static BOOL g_disableErrorRecovery;
static NSString *g_userAgentSuffix;
static NSString *g_defaultGraphAPIVersion;
static FBSDKAccessTokenExpirer *g_accessTokenExpirer;
static NSDictionary<NSString *, id> *g_dataProcessingOptions = nil;
static NSNumber *g_advertiserTrackingStatus = nil;
static id<FBSDKDataPersisting> _store = nil;
static Class<FBSDKAppEventsConfigurationProviding> _appEventsConfigurationProvider = nil;

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

@implementation FBSDKSettings

+ (void)initialize
{
  if (self == [FBSDKSettings class]) {
    g_accessTokenExpirer = [[FBSDKAccessTokenExpirer alloc] init];

    [FBSDKSettings _logWarnings];
    [FBSDKSettings _logIfSDKSettingsChanged];
  }
}

+ (void)      configureWithStore:(id<FBSDKDataPersisting>)store
  appEventsConfigurationProvider:(Class<FBSDKAppEventsConfigurationProviding>)provider
{
  _store = store;
  _appEventsConfigurationProvider = provider;
}

+ (id<FBSDKDataPersisting>)store
{
  return _store;
}

+ (Class<FBSDKAppEventsConfigurationProviding>)appEventsConfigurationProvider
{
  return _appEventsConfigurationProvider;
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
  return [self _JPEGCompressionQualityNumber].floatValue;
}

+ (void)setJPEGCompressionQuality:(CGFloat)JPEGCompressionQuality
{
  [self _setJPEGCompressionQualityNumber:@(JPEGCompressionQuality)];
}

+ (BOOL)isInstrumentEnabled
{
  return [self _instrumentEnabled].boolValue;
}

+ (void)setInstrumentEnabled:(BOOL)instrumentEnabled
{
  [self _setInstrumentEnabled:@(instrumentEnabled)];
}

+ (BOOL)isCodelessDebugLogEnabled
{
  return [self _codelessDebugLogEnabled].boolValue;
}

+ (void)setCodelessDebugLogEnabled:(BOOL)codelessDebugLogEnabled
{
  [self _setCodelessDebugLogEnabled:@(codelessDebugLogEnabled)];
}

+ (BOOL)isAutoLogAppEventsEnabled
{
  return [self _autoLogAppEventsEnabled].boolValue;
}

+ (void)setAutoLogAppEventsEnabled:(BOOL)autoLogAppEventsEnabled
{
  [self _setAutoLogAppEventsEnabled:@(autoLogAppEventsEnabled)];
}

+ (BOOL)isAdvertiserIDCollectionEnabled
{
  return [self _advertiserIDCollectionEnabled].boolValue;
}

+ (void)setAdvertiserIDCollectionEnabled:(BOOL)advertiserIDCollectionEnabled
{
  [self _setAdvertiserIDCollectionEnabled:@(advertiserIDCollectionEnabled)];
}

+ (BOOL)isAdvertiserTrackingEnabled
{
  return [FBSDKSettings getAdvertisingTrackingStatus] == FBSDKAdvertisingTrackingAllowed;
}

+ (BOOL)setAdvertiserTrackingEnabled:(BOOL)enabled;
{
  if (@available(iOS 14.0, *)) {
    [FBSDKSettings setAdvertiserTrackingStatus:enabled ? FBSDKAdvertisingTrackingAllowed : FBSDKAdvertisingTrackingDisallowed];
    [self recordSetAdvertiserTrackingEnabled];
    return YES;
  } else {
    return NO;
  }
}

+ (FBSDKAdvertisingTrackingStatus)getAdvertisingTrackingStatus
{
  if (@available(iOS 14.0, *)) {
    if (g_advertiserTrackingStatus == nil) {
      g_advertiserTrackingStatus = [self.store objectForKey:FBSDKSettingsAdvertisingTrackingStatus];
      if (g_advertiserTrackingStatus == nil) {
        return [[self.appEventsConfigurationProvider cachedAppEventsConfiguration] defaultATEStatus];
      }
    }
    return g_advertiserTrackingStatus.unsignedIntegerValue;
  } else {
    // @lint-ignore CLANGTIDY
    return ASIdentifierManager.sharedManager.advertisingTrackingEnabled ? FBSDKAdvertisingTrackingAllowed : FBSDKAdvertisingTrackingDisallowed;
  }
}

+ (void)setAdvertiserTrackingStatus:(FBSDKAdvertisingTrackingStatus)status
{
  g_advertiserTrackingStatus = @(status);
  [self.store setObject:g_advertiserTrackingStatus forKey:FBSDKSettingsAdvertisingTrackingStatus];
}

+ (BOOL)isSKAdNetworkReportEnabled
{
  return [self _SKAdNetworkReportEnabled].boolValue;
}

+ (void)setSKAdNetworkReportEnabled:(BOOL)SKAdNetworkReportEnabled
{
  [self _setSKAdNetworkReportEnabled:@(SKAdNetworkReportEnabled)];
}

+ (BOOL)shouldLimitEventAndDataUsage
{
  NSNumber *storedValue = [self.store objectForKey:FBSDKSettingsLimitEventAndDataUsage];
  if (storedValue == nil) {
    return NO;
  }
  return storedValue.boolValue;
}

+ (void)setLimitEventAndDataUsage:(BOOL)limitEventAndDataUsage
{
  [self.store setObject:@(limitEventAndDataUsage) forKey:FBSDKSettingsLimitEventAndDataUsage];
}

+ (NSSet<FBSDKLoggingBehavior> *)loggingBehaviors
{
  if (!g_loggingBehaviors) {
    NSArray<FBSDKLoggingBehavior> *bundleLoggingBehaviors = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"FacebookLoggingBehavior"];
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
  NSArray<NSString *> *options = [FBSDKTypeUtility dictionary:[FBSDKSettings dataProcessingOptions]
                                                 objectForKey:DATA_PROCESSING_OPTIONS
                                                       ofType:NSArray.class];
  for (NSString *option in options) {
    if ([@"ldu" isEqualToString:[[FBSDKTypeUtility stringValue:option] lowercaseString]]) {
      return YES;
    }
  }
  return NO;
}

+ (void)_logWarnings
{
  NSBundle *mainBundle = [NSBundle mainBundle];
  // Log warnings for App Event Flags
  if (![mainBundle objectForInfoDictionaryKey:@"FacebookAutoLogAppEventsEnabled"]) {
    NSLog(autoLogAppEventsEnabledNotSetWarning);
  }
  if (![mainBundle objectForInfoDictionaryKey:@"FacebookAdvertiserIDCollectionEnabled"]) {
    NSLog(advertiserIDCollectionEnabledNotSetWarning);
  }
  if (![FBSDKSettings isAdvertiserIDCollectionEnabled]) {
    NSLog(advertiserIDCollectionEnabledFalseWarning);
  }
}

+ (void)_logIfSDKSettingsChanged
{
  NSInteger bitmask = 0;
  // Starting at 1 to maintain the meaning of the bits since the autoInit flag was removed.
  NSInteger bit = 1;
  bitmask |= ([FBSDKSettings isAutoLogAppEventsEnabled] ? 1 : 0) << bit++;
  bitmask |= ([FBSDKSettings isAdvertiserIDCollectionEnabled] ? 1 : 0) << bit++;

  NSInteger previousBitmask = [self.store integerForKey:FBSDKSettingsBitmask];
  if (previousBitmask != bitmask) {
    [self.store setInteger:bitmask forKey:FBSDKSettingsBitmask];

    NSArray<NSString *> *keys = @[@"FacebookAutoLogAppEventsEnabled",
                                  @"FacebookAdvertiserIDCollectionEnabled"];
    NSArray<NSNumber *> *defaultValues = @[@YES, @YES];
    NSInteger initialBitmask = 0;
    NSInteger usageBitmask = 0;
    for (int i = 0; i < keys.count; i++) {
      NSNumber *plistValue = [[NSBundle mainBundle] objectForInfoDictionaryKey:[FBSDKTypeUtility array:keys objectAtIndex:i]];
      BOOL initialValue = [(plistValue ?: [FBSDKTypeUtility array:defaultValues objectAtIndex:i]) boolValue];
      initialBitmask |= (initialValue ? 1 : 0) << i;
      usageBitmask |= (plistValue != nil ? 1 : 0) << i;
    }
    [FBSDKAppEvents logInternalEvent:@"fb_sdk_settings_changed"
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
  NSDate *installTimestamp = [self.store objectForKey:FBSDKSettingsInstallTimestamp];
  NSDate *setATETimestamp = [self.store objectForKey:FBSDKSettingsSetAdvertiserTrackingEnabledTimestamp];
  if (installTimestamp && setATETimestamp) {
    return [setATETimestamp timeIntervalSinceDate:installTimestamp] > 86400;
  }
  return NO;
}

+ (NSDate *_Nullable)getInstallTimestamp
{
  return [self.store objectForKey:FBSDKSettingsInstallTimestamp];
}

+ (NSDate *_Nullable)getSetAdvertiserTrackingEnabledTimestamp
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
  _store = nil;
  _appEventsConfigurationProvider = nil;

  g_loggingBehaviors = nil;
  g_FacebookAppID = nil;
  g_FacebookUrlSchemeSuffix = nil;
  g_FacebookClientToken = nil;
  g_FacebookDisplayName = nil;
  g_FacebookDomainPart = nil;
  g_FacebookJpegCompressionQuality = nil;
  g_FacebookInstrumentEnabled = nil;
  g_FacebookAutoLogAppEventsEnabled = nil;
  g_FacebookAdvertiserIDCollectionEnabled = nil;
  g_advertiserTrackingStatus = nil;
  g_FacebookSKAdNetworkReportEnabled = nil;
  g_userAgentSuffix = nil;
  g_FacebookCodelessDebugLogEnabled = nil;
  g_dataProcessingOptions = nil;
}

 #endif
#endif

@end
