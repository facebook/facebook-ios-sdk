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

#import "FBSDKServerConfigurationManager+Internal.h"

#import "FBSDKGraphRequest+Internal.h"
#import "FBSDKGraphRequest.h"
#import "FBSDKInternalUtility.h"
#import "FBSDKLogger.h"
#import "FBSDKServerConfiguration+Internal.h"
#import "FBSDKServerConfiguration.h"
#import "FBSDKSettings.h"
#import "FBSDKTypeUtility.h"

#define FBSDK_SERVER_CONFIGURATION_MANAGER_CACHE_TIMEOUT (60 * 60) // one hour

#define FBSDK_SERVER_CONFIGURATION_USER_DEFAULTS_KEY @"com.facebook.sdk:serverConfiguration%@"

#define FBSDK_SERVER_CONFIGURATION_APP_EVENTS_FEATURES_FIELD @"app_events_feature_bitmask"
#define FBSDK_SERVER_CONFIGURATION_APP_NAME_FIELD @"name"
#define FBSDK_SERVER_CONFIGURATION_DEFAULT_SHARE_MODE_FIELD @"default_share_mode"
#define FBSDK_SERVER_CONFIGURATION_DIALOG_CONFIGS_FIELD @"ios_dialog_configs"
#define FBSDK_SERVER_CONFIGURATION_DIALOG_FLOWS_FIELD @"ios_sdk_dialog_flows"
#define FBSDK_SERVER_CONFIGURATION_ERROR_CONFIGURATION_FIELD @"ios_sdk_error_categories"
#define FBSDK_SERVER_CONFIGURATION_IMPLICIT_LOGGING_ENABLED_FIELD @"supports_implicit_sdk_logging"
#define FBSDK_SERVER_CONFIGURATION_LOGIN_TOOLTIP_ENABLED_FIELD @"gdpv4_nux_enabled"
#define FBSDK_SERVER_CONFIGURATION_LOGIN_TOOLTIP_TEXT_FIELD @"gdpv4_nux_content"
#define FBSDK_SERVER_CONFIGURATION_NATIVE_PROXY_AUTH_FLOW_ENABLED_FIELD @"ios_supports_native_proxy_auth_flow"
#define FBSDK_SERVER_CONFIGURATION_SYSTEM_AUTHENTICATION_ENABLED_FIELD @"ios_supports_system_auth"

@implementation FBSDKServerConfigurationManager

static NSMutableArray *_completionBlocks;
static BOOL _loadedFromUserDefaults;
static BOOL _loadingServerConfiguration;
static FBSDKServerConfiguration *_serverConfiguration;
static NSError *_serverConfigurationError;
static NSDate *_serverConfigurationErrorTimestamp;
static const NSTimeInterval kTimeout = 4.0;

typedef NS_OPTIONS(NSUInteger, FBSDKServerConfigurationManagerAppEventsFeatures)
{
  FBSDKServerConfigurationManagerAppEventsFeaturesNone                            = 0,
  FBSDKServerConfigurationManagerAppEventsFeaturesAdvertisingIDEnabled            = 1 << 0,
  FBSDKServerConfigurationManagerAppEventsFeaturesImplicitPurchaseLoggingEnabled  = 1 << 1,
};

#pragma mark - Public Methods

+ (void)initialize
{
  if (self == [FBSDKServerConfigurationManager class]) {
    _completionBlocks = [[NSMutableArray alloc] init];
  }
}

+ (FBSDKServerConfiguration *)_defaultServerConfigurationForAppID:(NSString *)appID
{
  // Use a default configuration while we do not have a configuration back from the server. This allows us to set
  // the default values for any of the dialog sets or anything else in a centralized location while we are waiting for
  // the server to respond.
  static FBSDKServerConfiguration *_defaultServerConfiguration = nil;
  if (![_defaultServerConfiguration.appID isEqualToString:appID]) {
    // Bypass the native dialog flow for iOS 9+, as it produces a series of additional confirmation dialogs that lead to
    // extra friction that is not desirable.
    NSOperatingSystemVersion iOS9Version = { .majorVersion = 9, .minorVersion = 0, .patchVersion = 0 };
    BOOL useNativeFlow = ![FBSDKInternalUtility isOSRunTimeVersionAtLeast:iOS9Version];
    // Also enable SFSafariViewController by default.
    NSDictionary *dialogFlows = @{
                                  FBSDKDialogConfigurationNameDefault: @{
                                      FBSDKDialogConfigurationFeatureUseNativeFlow: @(useNativeFlow),
                                      FBSDKDialogConfigurationFeatureUseSafariViewController: @YES,
                                      },
                                  FBSDKDialogConfigurationNameMessage: @{
                                      FBSDKDialogConfigurationFeatureUseNativeFlow: @YES,
                                      },
                                  };
    _defaultServerConfiguration = [[FBSDKServerConfiguration alloc] initWithAppID:appID
                                                                          appName:nil
                                                              loginTooltipEnabled:NO
                                                                 loginTooltipText:nil
                                                                 defaultShareMode:nil
                                                             advertisingIDEnabled:NO
                                                           implicitLoggingEnabled:NO
                                                   implicitPurchaseLoggingEnabled:NO
                                                      systemAuthenticationEnabled:NO
                                                            nativeAuthFlowEnabled:NO
                                                             dialogConfigurations:nil
                                                                      dialogFlows:dialogFlows
                                                                        timestamp:nil
                                                               errorConfiguration:nil
                                                                         defaults:YES];
  }
  return _defaultServerConfiguration;
}

+ (FBSDKServerConfiguration *)cachedServerConfiguration
{
  NSString *appID = [FBSDKSettings appID];
  @synchronized(self) {
    FBSDKServerConfiguration *configuration = ([self _cachedServerConfigurationIsValidForAppID:appID] ? _serverConfiguration : nil);
    return (configuration ?: [self _defaultServerConfigurationForAppID:appID]);  }
}

+ (void)loadServerConfigurationWithCompletionBlock:(FBSDKServerConfigurationManagerLoadBlock)completionBlock
{
  NSString *appID = [FBSDKSettings appID];
  BOOL shouldLoad = NO;
  FBSDKServerConfiguration *serverConfiguration = nil;
  NSError *serverConfigurationError = nil;
  // get out of the lock as soon as possible
  @synchronized(self) {
    if ([self _cachedServerConfigurationIsValidForAppID:appID]) {
      serverConfiguration = _serverConfiguration;
      serverConfigurationError = _serverConfigurationError;
    } else {
      shouldLoad = YES;
      [FBSDKInternalUtility array:_completionBlocks addObject:[completionBlock copy]];
      if (_loadingServerConfiguration) {
        return;
      }
      _loadingServerConfiguration = YES;
    }
  }
  if (shouldLoad) {
    [self _loadServerConfigurationForAppID:appID];
  } else if (completionBlock != NULL) {
    completionBlock(serverConfiguration, serverConfigurationError);
  }
}

#pragma mark - Internal methods

+ (void)processLoadRequestResponse:(id)result error:(NSError *)error appID:(NSString *)appID
{
  if (error) {
    [self _didLoadServerConfiguration:nil appID:appID error:error didLoadFromUserDefaults:NO];
    return;
  }

  NSDictionary *resultDictionary = [FBSDKTypeUtility dictionaryValue:result];
  NSUInteger appEventsFeatures = [FBSDKTypeUtility unsignedIntegerValue:resultDictionary[FBSDK_SERVER_CONFIGURATION_APP_EVENTS_FEATURES_FIELD]];
  BOOL advertisingIDEnabled = (appEventsFeatures & FBSDKServerConfigurationManagerAppEventsFeaturesAdvertisingIDEnabled);
  BOOL implicitPurchaseLoggingEnabled = (appEventsFeatures & FBSDKServerConfigurationManagerAppEventsFeaturesImplicitPurchaseLoggingEnabled);

  NSString *appName = [FBSDKTypeUtility stringValue:resultDictionary[FBSDK_SERVER_CONFIGURATION_APP_NAME_FIELD]];
  BOOL loginTooltipEnabled = [FBSDKTypeUtility boolValue:resultDictionary[FBSDK_SERVER_CONFIGURATION_LOGIN_TOOLTIP_ENABLED_FIELD]];
  NSString *loginTooltipText = [FBSDKTypeUtility stringValue:resultDictionary[FBSDK_SERVER_CONFIGURATION_LOGIN_TOOLTIP_TEXT_FIELD]];
  NSString *defaultShareMode = [FBSDKTypeUtility stringValue:resultDictionary[FBSDK_SERVER_CONFIGURATION_DEFAULT_SHARE_MODE_FIELD]];
  BOOL implicitLoggingEnabled = [FBSDKTypeUtility boolValue:resultDictionary[FBSDK_SERVER_CONFIGURATION_IMPLICIT_LOGGING_ENABLED_FIELD]];
  BOOL systemAuthenticationEnabled = [FBSDKTypeUtility boolValue:resultDictionary[FBSDK_SERVER_CONFIGURATION_SYSTEM_AUTHENTICATION_ENABLED_FIELD]];
  BOOL nativeAuthFlowEnabled =      [FBSDKTypeUtility boolValue:resultDictionary[FBSDK_SERVER_CONFIGURATION_NATIVE_PROXY_AUTH_FLOW_ENABLED_FIELD]];
  NSDictionary *dialogConfigurations = [FBSDKTypeUtility dictionaryValue:resultDictionary[FBSDK_SERVER_CONFIGURATION_DIALOG_CONFIGS_FIELD]];
  dialogConfigurations = [self _parseDialogConfigurations:dialogConfigurations];
  NSDictionary *dialogFlows = [FBSDKTypeUtility dictionaryValue:resultDictionary[FBSDK_SERVER_CONFIGURATION_DIALOG_FLOWS_FIELD]];
  FBSDKErrorConfiguration *errorConfiguration = [[FBSDKErrorConfiguration alloc] initWithDictionary:nil];
  [errorConfiguration parseArray:resultDictionary[FBSDK_SERVER_CONFIGURATION_ERROR_CONFIGURATION_FIELD]];
  FBSDKServerConfiguration *serverConfiguration = [[FBSDKServerConfiguration alloc] initWithAppID:appID
                                                                                          appName:appName
                                                                              loginTooltipEnabled:loginTooltipEnabled
                                                                                 loginTooltipText:loginTooltipText
                                                                                 defaultShareMode:defaultShareMode
                                                                             advertisingIDEnabled:advertisingIDEnabled
                                                                           implicitLoggingEnabled:implicitLoggingEnabled
                                                                   implicitPurchaseLoggingEnabled:implicitPurchaseLoggingEnabled
                                                                      systemAuthenticationEnabled:systemAuthenticationEnabled
                                                                            nativeAuthFlowEnabled:nativeAuthFlowEnabled
                                                                             dialogConfigurations:dialogConfigurations
                                                                                      dialogFlows:dialogFlows
                                                                                        timestamp:[NSDate date]
                                                                               errorConfiguration:errorConfiguration
                                                                                         defaults:NO];
  [self _didLoadServerConfiguration:serverConfiguration appID:appID error:nil didLoadFromUserDefaults:NO];
}

+ (FBSDKGraphRequest *)requestToLoadServerConfiguration:(NSString *)appID
{
  NSOperatingSystemVersion operatingSystemVersion = [FBSDKInternalUtility operatingSystemVersion];
  NSString *dialogFlowsField = [NSString stringWithFormat:@"%@.os_version(%ti.%ti.%ti)",
                                FBSDK_SERVER_CONFIGURATION_DIALOG_FLOWS_FIELD,
                                operatingSystemVersion.majorVersion,
                                operatingSystemVersion.minorVersion,
                                operatingSystemVersion.patchVersion];
  NSArray *fields = @[FBSDK_SERVER_CONFIGURATION_APP_EVENTS_FEATURES_FIELD,
                      FBSDK_SERVER_CONFIGURATION_APP_NAME_FIELD,
                      FBSDK_SERVER_CONFIGURATION_DEFAULT_SHARE_MODE_FIELD,
                      FBSDK_SERVER_CONFIGURATION_DIALOG_CONFIGS_FIELD,
                      dialogFlowsField,
                      FBSDK_SERVER_CONFIGURATION_ERROR_CONFIGURATION_FIELD,
                      FBSDK_SERVER_CONFIGURATION_IMPLICIT_LOGGING_ENABLED_FIELD,
                      FBSDK_SERVER_CONFIGURATION_LOGIN_TOOLTIP_ENABLED_FIELD,
                      FBSDK_SERVER_CONFIGURATION_LOGIN_TOOLTIP_TEXT_FIELD,
                      FBSDK_SERVER_CONFIGURATION_NATIVE_PROXY_AUTH_FLOW_ENABLED_FIELD,
                      FBSDK_SERVER_CONFIGURATION_SYSTEM_AUTHENTICATION_ENABLED_FIELD,
                      ];
  NSDictionary *parameters = @{ @"fields": [fields componentsJoinedByString:@","] };
  FBSDKGraphRequest *request = [[FBSDKGraphRequest alloc] initWithGraphPath:appID
                                                                 parameters:parameters
                                                                tokenString:nil
                                                                 HTTPMethod:nil
                                                                      flags:FBSDKGraphRequestFlagSkipClientToken | FBSDKGraphRequestFlagDisableErrorRecovery];
  return request;
}

#pragma mark - Object Lifecycle

- (instancetype)init
{
  return nil;
}

#pragma mark - Helper Methods

+ (BOOL)_cachedServerConfigurationIsValidForAppID:(NSString *)appID
{
  if (_serverConfiguration && ![_serverConfiguration.appID isEqualToString:appID]) {
    _serverConfiguration = nil;
    _serverConfigurationError = nil;
    _serverConfigurationErrorTimestamp = nil;
    return NO;
  }
  if (_serverConfiguration) {
    return [self _serverConfigurationTimestampIsValid:_serverConfiguration.timestamp];
  }
  if (_serverConfigurationError && [self _serverConfigurationTimestampIsValid:_serverConfigurationErrorTimestamp]) {
    return YES;
  }
  _serverConfigurationError = nil;
  _serverConfigurationErrorTimestamp = nil;
  return NO;
}

+ (void)_didLoadServerConfiguration:(FBSDKServerConfiguration *)serverConfiguration
                              appID:(NSString *)appID
                              error:(NSError *)error
            didLoadFromUserDefaults:(BOOL)didLoadFromUserDefaults
{
  if (error) {
    if (_serverConfiguration && [_serverConfiguration.appID isEqualToString:appID]) {
      // We have older app settings but the refresh received an error.
      // Log and ignore the error.
      [FBSDKLogger singleShotLogEntry:FBSDKLoggingBehaviorInformational
                         formatString:@"loadServerConfigurationWithCompletionBlock failed with %@", error];
    } else {
      // Only set the error if we don't have previously fetched app settings.
      // (i.e., if we have app settings and a new call gets an error, we'll
      // ignore the error and surface the last successfully fetched settings).
      _serverConfiguration = nil;
      _serverConfigurationError = error;
      _serverConfigurationErrorTimestamp = [NSDate date];
    }
  } else {
    _serverConfiguration = serverConfiguration;
    _serverConfigurationError = nil;
    _serverConfigurationErrorTimestamp = nil;
  }

  if (!didLoadFromUserDefaults) {
    // update the cached copy in NSUserDefaults
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *defaultsKey = [NSString stringWithFormat:FBSDK_SERVER_CONFIGURATION_USER_DEFAULTS_KEY, appID];
    if (serverConfiguration) {
      NSData *data = [NSKeyedArchiver archivedDataWithRootObject:serverConfiguration];
      [defaults setObject:data forKey:defaultsKey];
    }
  }

  // call the completion blocks
  NSArray *completionBlocks;
  @synchronized(self) {
    completionBlocks = [_completionBlocks copy];
    [_completionBlocks removeAllObjects];
    _loadingServerConfiguration = NO;
  }
  for (FBSDKServerConfigurationManagerLoadBlock completionBlock in completionBlocks) {
    completionBlock(_serverConfiguration, _serverConfigurationError);
  }
}

+ (void)_loadServerConfigurationForAppID:(NSString *)appID
{
  if (!_loadedFromUserDefaults) {
    _loadedFromUserDefaults = YES;
    FBSDKServerConfiguration *userDefaultsServerConfiguration = [self _loadServerConfigurationFromUserDefaultsForAppID:appID];
    if (userDefaultsServerConfiguration) {
      if ([self _serverConfigurationTimestampIsValid:userDefaultsServerConfiguration.timestamp]) {
        [self _didLoadServerConfiguration:userDefaultsServerConfiguration
                                    appID:appID
                                    error:nil
                  didLoadFromUserDefaults:YES];
        return;
      }
      // if it is expired, we want to fetch from the server, but keep the last configuration as a fallback
      _serverConfiguration = userDefaultsServerConfiguration;
    }
  }
  [self _loadServerConfigurationFromServerForAppID:appID];
}

+ (void)_loadServerConfigurationFromServerForAppID:(NSString *)appID
{
  FBSDKGraphRequest *request = [[self class] requestToLoadServerConfiguration:appID];

  // start request with specified timeout instead of the default 180s
  FBSDKGraphRequestConnection *requestConnection = [[FBSDKGraphRequestConnection alloc] init];
  requestConnection.timeout = kTimeout;
  [requestConnection addRequest:request completionHandler:^(FBSDKGraphRequestConnection *connection, id result, NSError *error) {
    [self processLoadRequestResponse:result error:error appID:appID];
  }];
  [requestConnection start];
}

+ (FBSDKServerConfiguration *)_loadServerConfigurationFromUserDefaultsForAppID:(NSString *)appID
{
  // load the defaults
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  NSString *defaultsKey = [NSString stringWithFormat:FBSDK_SERVER_CONFIGURATION_USER_DEFAULTS_KEY, appID];
  NSData *data = [defaults objectForKey:defaultsKey];
  if (![data isKindOfClass:[NSData class]]) {
    return nil;
  }

  // decode the configuration
  FBSDKServerConfiguration *serverConfiguration = [NSKeyedUnarchiver unarchiveObjectWithData:data];
  if (![serverConfiguration isKindOfClass:[FBSDKServerConfiguration class]]) {
    return nil;
  }

  // ensure that the configuration points to the current appID
  if (![serverConfiguration.appID isEqualToString:appID]) {
    return nil;
  }

  return serverConfiguration;
}

+ (NSDictionary *)_parseDialogConfigurations:(NSDictionary *)dictionary
{
  NSMutableDictionary *dialogConfigurations = [[NSMutableDictionary alloc] init];
  NSArray *dialogConfigurationsArray = [FBSDKTypeUtility arrayValue:dictionary[@"data"]];
  for (id dialogConfiguration in dialogConfigurationsArray) {
    NSDictionary *dialogConfigurationDictionary = [FBSDKTypeUtility dictionaryValue:dialogConfiguration];
    if (dialogConfigurationDictionary) {
      NSString *name = [FBSDKTypeUtility stringValue:dialogConfigurationDictionary[@"name"]];
      if ([name length]) {
        NSURL *URL = [FBSDKTypeUtility URLValue:dialogConfigurationDictionary[@"url"]];
        NSArray *appVersions = [FBSDKTypeUtility arrayValue:dialogConfigurationDictionary[@"versions"]];
        dialogConfigurations[name] = [[FBSDKDialogConfiguration alloc] initWithName:name
                                                                                URL:URL
                                                                        appVersions:appVersions];
      }
    }
  }
  return dialogConfigurations;
}

+ (BOOL)_serverConfigurationTimestampIsValid:(NSDate *)timestamp
{
  NSTimeInterval cacheAge = [[NSDate date] timeIntervalSinceDate:timestamp];
  return (cacheAge < FBSDK_SERVER_CONFIGURATION_MANAGER_CACHE_TIMEOUT);
}

@end
