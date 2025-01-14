/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "FBSDKServerConfiguration.h"
#import "FBSDKServerConfiguration+Internal.h"

#import <FBSDKCoreKit_Basics/FBSDKCoreKit_Basics.h>

// one minute
#define DEFAULT_SESSION_TIMEOUT_INTERVAL 60

#define FBSDK_SERVER_CONFIGURATION_ADVERTISING_ID_ENABLED_KEY @"advertisingIDEnabled"
#define FBSDK_SERVER_CONFIGURATION_APP_ID_KEY @"appID"
#define FBSDK_SERVER_CONFIGURATION_APP_NAME_KEY @"appName"
#define FBSDK_SERVER_CONFIGURATION_DIALOG_CONFIGURATIONS_KEY @"dialogConfigs"
#define FBSDK_SERVER_CONFIGURATION_DIALOG_FLOWS_KEY @"dialogFlows"
#define FBSDK_SERVER_CONFIGURATION_ERROR_CONFIGURATIONS_KEY @"errorConfigs"
#define FBSDK_SERVER_CONFIGURATION_IMPLICIT_LOGGING_ENABLED_KEY @"implicitLoggingEnabled"
#define FBSDK_SERVER_CONFIGURATION_DEFAULT_SHARE_MODE_KEY @"defaultShareMode"
#define FBSDK_SERVER_CONFIGURATION_IMPLICIT_PURCHASE_LOGGING_ENABLED_KEY @"implicitPurchaseLoggingEnabled"
#define FBSDK_SERVER_CONFIGURATION_CODELESS_EVENTS_ENABLED_KEY @"codelessEventsEnabled"
#define FBSDK_SERVER_CONFIGURATION_LOGIN_TOOLTIP_ENABLED_KEY @"loginTooltipEnabled"
#define FBSDK_SERVER_CONFIGURATION_LOGIN_TOOLTIP_TEXT_KEY @"loginTooltipText"
#define FBSDK_SERVER_CONFIGURATION_TIMESTAMP_KEY @"timestamp"
#define FBSDK_SERVER_CONFIGURATION_SESSION_TIMEOUT_INTERVAL @"sessionTimeoutInterval"
#define FBSDK_SERVER_CONFIGURATION_LOGGING_TOKEN @"loggingToken"
#define FBSDK_SERVER_CONFIGURATION_SMART_LOGIN_OPTIONS_KEY @"smartLoginEnabled"
#define FBSDK_SERVER_CONFIGURATION_SMART_LOGIN_BOOKMARK_ICON_URL_KEY @"smarstLoginBookmarkIconURL"
#define FBSDK_SERVER_CONFIGURATION_SMART_LOGIN_MENU_ICON_URL_KEY @"smarstLoginBookmarkMenuURL"
#define FBSDK_SERVER_CONFIGURATION_UPDATE_MESSAGE_KEY @"SDKUpdateMessage"
#define FBSDK_SERVER_CONFIGURATION_EVENT_BINDINGS  @"eventBindings"
#define FBSDK_SERVER_CONFIGURATION_RESTRICTIVE_PARAMS @"restrictiveParams"
#define FBSDK_SERVER_CONFIGURATION_AAM_RULES @"AAMRules"
#define FBSDK_SERVER_CONFIGURATION_SUGGESTED_EVENTS_SETTING @"suggestedEventsSetting"
#define FBSDK_SERVER_CONFIGURATION_VERSION_KEY @"version"
#define FBSDK_SERVER_CONFIGURATION_TRACK_UNINSTALL_ENABLED_KEY @"trackAppUninstallEnabled"
#define FBSDK_SERVER_CONFIGURATION_PROTECTED_MODE_RULES @"protectedModeRules"
#define FBSDK_SERVER_CONFIGURATION_MIGRATED_AUTO_LOG_VALUES_KEY @"migratedAutoLogValues"

#pragma mark - Dialog Names

NSString *const FBSDKDialogConfigurationNameDefault = @"default";

NSString *const FBSDKDialogConfigurationNameLogin = @"login";

NSString *const FBSDKDialogConfigurationNameSharing = @"sharing";

NSString *const FBSDKDialogConfigurationNameAppInvite = @"app_invite";
NSString *const FBSDKDialogConfigurationNameGameRequest = @"game_request";
NSString *const FBSDKDialogConfigurationNameGroup = @"group";
NSString *const FBSDKDialogConfigurationNameMessage = @"message";
NSString *const FBSDKDialogConfigurationNameShare = @"share";

NSString *const FBSDKDialogConfigurationFeatureUseNativeFlow = @"use_native_flow";
NSString *const FBSDKDialogConfigurationFeatureUseSafariViewController = @"use_safari_vc";

// Increase this value when adding new fields and previous cached configurations should be
// treated as stale.
const NSInteger FBSDKServerConfigurationVersion = 3;

@interface FBSDKServerConfiguration ()
@property (nonatomic) NSDictionary<NSString *, id> *dialogConfigurations;
@property (nonatomic) NSDictionary<NSString *, id> *dialogFlows;
@property (nonatomic) NSInteger version;
@end

@implementation FBSDKServerConfiguration

#pragma mark - Object Lifecycle

- (instancetype)   initWithAppID:(NSString *)appID
                         appName:(NSString *)appName
             loginTooltipEnabled:(BOOL)loginTooltipEnabled
                loginTooltipText:(NSString *)loginTooltipText
                defaultShareMode:(NSString *)defaultShareMode
            advertisingIDEnabled:(BOOL)advertisingIDEnabled
          implicitLoggingEnabled:(BOOL)implicitLoggingEnabled
  implicitPurchaseLoggingEnabled:(BOOL)implicitPurchaseLoggingEnabled
           codelessEventsEnabled:(BOOL)codelessEventsEnabled
        uninstallTrackingEnabled:(BOOL)uninstallTrackingEnabled
            dialogConfigurations:(NSDictionary<NSString *, id> *)dialogConfigurations
                     dialogFlows:(NSDictionary<NSString *, id> *)dialogFlows
                       timestamp:(NSDate *)timestamp
              errorConfiguration:(FBSDKErrorConfiguration *)errorConfiguration
          sessionTimeoutInterval:(NSTimeInterval)sessionTimeoutInterval
                        defaults:(BOOL)defaults
                    loggingToken:(NSString *)loggingToken
               smartLoginOptions:(FBSDKServerConfigurationSmartLoginOptions)smartLoginOptions
       smartLoginBookmarkIconURL:(NSURL *)smartLoginBookmarkIconURL
           smartLoginMenuIconURL:(NSURL *)smartLoginMenuIconURL
                   updateMessage:(NSString *)updateMessage
                   eventBindings:(NSArray<NSDictionary<NSString *, id> *> *)eventBindings
               restrictiveParams:(NSDictionary<NSString *, id> *)restrictiveParams
                        AAMRules:(NSDictionary<NSString *, id> *)AAMRules
          suggestedEventsSetting:(NSDictionary<NSString *, id> *)suggestedEventsSetting
              protectedModeRules:(NSDictionary<NSString *, id> *)protectedModeRules
           migratedAutoLogValues:(NSDictionary<NSString *, id> *) migratedAutoLogValues
{
  if ((self = [super init])) {
    _appID = [appID copy];
    _appName = [appName copy];
    _loginTooltipEnabled = loginTooltipEnabled;
    _loginTooltipText = [loginTooltipText copy];
    _defaultShareMode = defaultShareMode;
    _advertisingIDEnabled = advertisingIDEnabled;
    _implicitLoggingEnabled = implicitLoggingEnabled;
    _implicitPurchaseLoggingEnabled = implicitPurchaseLoggingEnabled;
    _codelessEventsEnabled = codelessEventsEnabled;
    _uninstallTrackingEnabled = uninstallTrackingEnabled;
    _dialogConfigurations = [dialogConfigurations copy];
    _dialogFlows = [dialogFlows copy];
    _timestamp = [timestamp copy];
    _errorConfiguration = [errorConfiguration copy];
    _sessionTimeoutInterval = sessionTimeoutInterval ?: DEFAULT_SESSION_TIMEOUT_INTERVAL;
    _defaults = defaults;
    _loggingToken = loggingToken;
    _smartLoginOptions = smartLoginOptions;
    _smartLoginMenuIconURL = [smartLoginMenuIconURL copy];
    _smartLoginBookmarkIconURL = [smartLoginBookmarkIconURL copy];
    _updateMessage = [updateMessage copy];
    _eventBindings = eventBindings;
    _restrictiveParams = restrictiveParams;
    _AAMRules = AAMRules;
    _suggestedEventsSetting = suggestedEventsSetting;
    _version = FBSDKServerConfigurationVersion;
    _protectedModeRules = protectedModeRules;
    _migratedAutoLogValues = [migratedAutoLogValues copy];
  }
  return self;
}

+ (FBSDKServerConfiguration *)defaultServerConfigurationForAppID:(NSString *)appID
{
  // Use a default configuration while we do not have a configuration back from the server. This allows us to set
  // the default values for any of the dialog sets or anything else in a centralized location while we are waiting for
  // the server to respond.
  static FBSDKServerConfiguration *_defaultServerConfiguration = nil;
  if (![_defaultServerConfiguration.appID isEqualToString:appID]) {
    // Enable SFSafariViewController by default.
    NSDictionary<NSString *, id> *dialogFlows = @{
      FBSDKDialogConfigurationNameDefault : @{
        FBSDKDialogConfigurationFeatureUseNativeFlow : @NO,
        FBSDKDialogConfigurationFeatureUseSafariViewController : @YES,
      },
      FBSDKDialogConfigurationNameMessage : @{
        FBSDKDialogConfigurationFeatureUseNativeFlow : @YES,
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
                                                            codelessEventsEnabled:NO
                                                         uninstallTrackingEnabled:NO
                                                             dialogConfigurations:nil
                                                                      dialogFlows:dialogFlows
                                                                        timestamp:nil
                                                               errorConfiguration:nil
                                                           sessionTimeoutInterval:DEFAULT_SESSION_TIMEOUT_INTERVAL
                                                                         defaults:YES
                                                                     loggingToken:nil
                                                                smartLoginOptions:FBSDKServerConfigurationSmartLoginOptionsUnknown
                                                        smartLoginBookmarkIconURL:nil
                                                            smartLoginMenuIconURL:nil
                                                                    updateMessage:nil
                                                                    eventBindings:nil
                                                                restrictiveParams:nil
                                                                         AAMRules:nil
                                                           suggestedEventsSetting:nil
                                                               protectedModeRules:nil
                                                            migratedAutoLogValues:nil
    ];
  }
  return _defaultServerConfiguration;
}

#pragma mark - Public Methods

- (nullable FBSDKDialogConfiguration *)dialogConfigurationForDialogName:(NSString *)dialogName
{
  return _dialogConfigurations[dialogName];
}

- (BOOL)useNativeDialogForDialogName:(NSString *)dialogName
{
  return [self _useFeatureWithKey:FBSDKDialogConfigurationFeatureUseNativeFlow dialogName:dialogName];
}

- (BOOL)useSafariViewControllerForDialogName:(NSString *)dialogName
{
  return [self _useFeatureWithKey:FBSDKDialogConfigurationFeatureUseSafariViewController dialogName:dialogName];
}

- (BOOL)_useFeatureWithKey:(NSString *)key dialogName:(NSString *)dialogName
{
  if ([dialogName isEqualToString:FBSDKDialogConfigurationNameLogin]) {
    return ((NSNumber *)(_dialogFlows[dialogName][key]
      ?: _dialogFlows[FBSDKDialogConfigurationNameDefault][key])).boolValue;
  } else {
    return ((NSNumber *)(_dialogFlows[dialogName][key]
      ?: _dialogFlows[FBSDKDialogConfigurationNameSharing][key]
        ?: _dialogFlows[FBSDKDialogConfigurationNameDefault][key])).boolValue;
  }
}

#pragma mark - NSCoding

+ (BOOL)supportsSecureCoding
{
  return YES;
}

- (instancetype)initWithCoder:(NSCoder *)decoder
{
  NSString *appID = [decoder decodeObjectOfClass:NSString.class forKey:FBSDK_SERVER_CONFIGURATION_APP_ID_KEY];
  NSString *appName = [decoder decodeObjectOfClass:NSString.class forKey:FBSDK_SERVER_CONFIGURATION_APP_NAME_KEY];
  BOOL loginTooltipEnabled = [decoder decodeBoolForKey:FBSDK_SERVER_CONFIGURATION_LOGIN_TOOLTIP_ENABLED_KEY];
  NSString *loginTooltipText = [decoder decodeObjectOfClass:NSString.class
                                                     forKey:FBSDK_SERVER_CONFIGURATION_LOGIN_TOOLTIP_TEXT_KEY];
  NSString *defaultShareMode = [decoder decodeObjectOfClass:NSString.class
                                                     forKey:FBSDK_SERVER_CONFIGURATION_DEFAULT_SHARE_MODE_KEY];
  BOOL advertisingIDEnabled = [decoder decodeBoolForKey:FBSDK_SERVER_CONFIGURATION_ADVERTISING_ID_ENABLED_KEY];
  BOOL implicitLoggingEnabled = [decoder decodeBoolForKey:FBSDK_SERVER_CONFIGURATION_IMPLICIT_LOGGING_ENABLED_KEY];
  BOOL implicitPurchaseLoggingEnabled =
  [decoder decodeBoolForKey:FBSDK_SERVER_CONFIGURATION_IMPLICIT_PURCHASE_LOGGING_ENABLED_KEY];
  BOOL codelessEventsEnabled =
  [decoder decodeBoolForKey:FBSDK_SERVER_CONFIGURATION_CODELESS_EVENTS_ENABLED_KEY];
  BOOL uninstallTrackingEnabled =
  [decoder decodeBoolForKey:FBSDK_SERVER_CONFIGURATION_TRACK_UNINSTALL_ENABLED_KEY];
  FBSDKServerConfigurationSmartLoginOptions smartLoginOptions = [decoder decodeIntegerForKey:FBSDK_SERVER_CONFIGURATION_SMART_LOGIN_OPTIONS_KEY];
  NSDate *timestamp = [decoder decodeObjectOfClass:NSDate.class forKey:FBSDK_SERVER_CONFIGURATION_TIMESTAMP_KEY];
  NSSet<Class> *dialogConfigurationsClasses = [[NSSet alloc] initWithObjects:
                                               [NSDictionary<NSString *, id> class],
                                               FBSDKDialogConfiguration.class,
                                               nil];
  NSDictionary<NSString *, id> *dialogConfigurations = [decoder decodeObjectOfClasses:dialogConfigurationsClasses
                                                                               forKey:FBSDK_SERVER_CONFIGURATION_DIALOG_CONFIGURATIONS_KEY];
  NSSet<Class> *dialogFlowsClasses = [[NSSet alloc] initWithObjects:
                                      [NSDictionary<NSString *, id> class],
                                      NSString.class,
                                      NSNumber.class,
                                      nil];
  NSDictionary<NSString *, id> *dialogFlows = [decoder decodeObjectOfClasses:dialogFlowsClasses
                                                                      forKey:FBSDK_SERVER_CONFIGURATION_DIALOG_FLOWS_KEY];
  FBSDKErrorConfiguration *errorConfiguration = [decoder decodeObjectOfClass:FBSDKErrorConfiguration.class forKey:FBSDK_SERVER_CONFIGURATION_ERROR_CONFIGURATIONS_KEY];
  NSTimeInterval sessionTimeoutInterval = [decoder decodeDoubleForKey:FBSDK_SERVER_CONFIGURATION_SESSION_TIMEOUT_INTERVAL];
  NSString *loggingToken = [decoder decodeObjectOfClass:NSString.class forKey:FBSDK_SERVER_CONFIGURATION_LOGGING_TOKEN];
  NSURL *smartLoginBookmarkIconURL = [decoder decodeObjectOfClass:NSURL.class forKey:FBSDK_SERVER_CONFIGURATION_SMART_LOGIN_BOOKMARK_ICON_URL_KEY];
  NSURL *smartLoginMenuIconURL = [decoder decodeObjectOfClass:NSURL.class forKey:FBSDK_SERVER_CONFIGURATION_SMART_LOGIN_MENU_ICON_URL_KEY];
  NSString *updateMessage = [decoder decodeObjectOfClass:NSString.class forKey:FBSDK_SERVER_CONFIGURATION_UPDATE_MESSAGE_KEY];
  NSSet<Class> *eventBindingsClasses = [[NSSet alloc] initWithObjects:
                                        [NSDictionary<NSString *, id> class],
                                        NSString.class,
                                        NSArray.class,
                                        NSNumber.class,
                                        nil];
  NSArray<NSDictionary<NSString *, id> *> *eventBindings = [decoder decodeObjectOfClasses:eventBindingsClasses forKey:FBSDK_SERVER_CONFIGURATION_EVENT_BINDINGS];
  NSSet<Class> *dictionaryClasses = [NSSet setWithObjects:
                                     [NSDictionary<NSString *, id> class],
                                     NSArray.class,
                                     NSData.class,
                                     NSString.class,
                                     NSNumber.class,
                                     nil];
  NSDictionary<NSString *, id> *restrictiveParams = [FBSDKTypeUtility dictionaryValue:[decoder decodeObjectOfClasses:dictionaryClasses forKey:FBSDK_SERVER_CONFIGURATION_RESTRICTIVE_PARAMS]];
  NSDictionary<NSString *, id> *AAMRules = [FBSDKTypeUtility dictionaryValue:[decoder decodeObjectOfClasses:dictionaryClasses forKey:FBSDK_SERVER_CONFIGURATION_AAM_RULES]];
  NSDictionary<NSString *, id> *suggestedEventsSetting = [FBSDKTypeUtility dictionaryValue:[decoder decodeObjectOfClasses:dictionaryClasses forKey:FBSDK_SERVER_CONFIGURATION_SUGGESTED_EVENTS_SETTING]];
  NSInteger version = [decoder decodeIntegerForKey:FBSDK_SERVER_CONFIGURATION_VERSION_KEY];
  NSDictionary<NSString *, id> *protectedModeRules = [FBSDKTypeUtility dictionaryValue:[decoder decodeObjectOfClasses:dictionaryClasses forKey:FBSDK_SERVER_CONFIGURATION_PROTECTED_MODE_RULES]];
  NSDictionary<NSString*, id> *migratedAutoLogValues = [FBSDKTypeUtility dictionaryValue:[decoder decodeObjectOfClasses:dictionaryClasses forKey:FBSDK_SERVER_CONFIGURATION_MIGRATED_AUTO_LOG_VALUES_KEY]];
  
  FBSDKServerConfiguration *configuration = [self initWithAppID:appID
                                                                    appName:appName
                                                        loginTooltipEnabled:loginTooltipEnabled
                                                           loginTooltipText:loginTooltipText
                                                           defaultShareMode:defaultShareMode
                                                       advertisingIDEnabled:advertisingIDEnabled
                                                     implicitLoggingEnabled:implicitLoggingEnabled
                                             implicitPurchaseLoggingEnabled:implicitPurchaseLoggingEnabled
                                                      codelessEventsEnabled:codelessEventsEnabled
                                                   uninstallTrackingEnabled:uninstallTrackingEnabled
                                                       dialogConfigurations:dialogConfigurations
                                                                dialogFlows:dialogFlows
                                                                  timestamp:timestamp
                                                         errorConfiguration:errorConfiguration
                                                     sessionTimeoutInterval:sessionTimeoutInterval
                                                                   defaults:NO
                                                               loggingToken:loggingToken
                                                          smartLoginOptions:smartLoginOptions
                                                  smartLoginBookmarkIconURL:smartLoginBookmarkIconURL
                                                      smartLoginMenuIconURL:smartLoginMenuIconURL
                                                              updateMessage:updateMessage
                                                              eventBindings:eventBindings
                                                          restrictiveParams:restrictiveParams
                                                                   AAMRules:AAMRules
                                                     suggestedEventsSetting:suggestedEventsSetting
                                                         protectedModeRules:protectedModeRules
                                                      migratedAutoLogValues:migratedAutoLogValues
  ];
  configuration->_version = version;
  return configuration;
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
  [encoder encodeBool:_advertisingIDEnabled forKey:FBSDK_SERVER_CONFIGURATION_ADVERTISING_ID_ENABLED_KEY];
  [encoder encodeObject:_appID forKey:FBSDK_SERVER_CONFIGURATION_APP_ID_KEY];
  [encoder encodeObject:_appName forKey:FBSDK_SERVER_CONFIGURATION_APP_NAME_KEY];
  [encoder encodeObject:_defaultShareMode forKey:FBSDK_SERVER_CONFIGURATION_DEFAULT_SHARE_MODE_KEY];
  [encoder encodeObject:_dialogConfigurations forKey:FBSDK_SERVER_CONFIGURATION_DIALOG_CONFIGURATIONS_KEY];
  [encoder encodeObject:_dialogFlows forKey:FBSDK_SERVER_CONFIGURATION_DIALOG_FLOWS_KEY];
  [encoder encodeObject:_errorConfiguration forKey:FBSDK_SERVER_CONFIGURATION_ERROR_CONFIGURATIONS_KEY];
  [encoder encodeBool:_implicitLoggingEnabled forKey:FBSDK_SERVER_CONFIGURATION_IMPLICIT_LOGGING_ENABLED_KEY];
  [encoder encodeBool:_implicitPurchaseLoggingEnabled
               forKey:FBSDK_SERVER_CONFIGURATION_IMPLICIT_PURCHASE_LOGGING_ENABLED_KEY];
  [encoder encodeBool:_codelessEventsEnabled
               forKey:FBSDK_SERVER_CONFIGURATION_CODELESS_EVENTS_ENABLED_KEY];
  [encoder encodeBool:_loginTooltipEnabled forKey:FBSDK_SERVER_CONFIGURATION_LOGIN_TOOLTIP_ENABLED_KEY];
  [encoder encodeBool:_uninstallTrackingEnabled
               forKey:FBSDK_SERVER_CONFIGURATION_TRACK_UNINSTALL_ENABLED_KEY];
  [encoder encodeObject:_loginTooltipText forKey:FBSDK_SERVER_CONFIGURATION_LOGIN_TOOLTIP_TEXT_KEY];
  [encoder encodeObject:_timestamp forKey:FBSDK_SERVER_CONFIGURATION_TIMESTAMP_KEY];
  [encoder encodeDouble:_sessionTimeoutInterval forKey:FBSDK_SERVER_CONFIGURATION_SESSION_TIMEOUT_INTERVAL];
  [encoder encodeObject:_loggingToken forKey:FBSDK_SERVER_CONFIGURATION_LOGGING_TOKEN];
  [encoder encodeInteger:_smartLoginOptions forKey:FBSDK_SERVER_CONFIGURATION_SMART_LOGIN_OPTIONS_KEY];
  [encoder encodeObject:_smartLoginBookmarkIconURL forKey:FBSDK_SERVER_CONFIGURATION_SMART_LOGIN_BOOKMARK_ICON_URL_KEY];
  [encoder encodeObject:_smartLoginMenuIconURL forKey:FBSDK_SERVER_CONFIGURATION_SMART_LOGIN_MENU_ICON_URL_KEY];
  [encoder encodeObject:_updateMessage forKey:FBSDK_SERVER_CONFIGURATION_UPDATE_MESSAGE_KEY];
  [encoder encodeObject:_eventBindings forKey:FBSDK_SERVER_CONFIGURATION_EVENT_BINDINGS];
  [encoder encodeObject:_restrictiveParams forKey:FBSDK_SERVER_CONFIGURATION_RESTRICTIVE_PARAMS];
  [encoder encodeObject:_AAMRules forKey:FBSDK_SERVER_CONFIGURATION_AAM_RULES];
  [encoder encodeObject:_suggestedEventsSetting forKey:FBSDK_SERVER_CONFIGURATION_SUGGESTED_EVENTS_SETTING];
  [encoder encodeInteger:_version forKey:FBSDK_SERVER_CONFIGURATION_VERSION_KEY];
  [encoder encodeObject:_protectedModeRules forKey:FBSDK_SERVER_CONFIGURATION_PROTECTED_MODE_RULES];
  [encoder encodeObject:_migratedAutoLogValues forKey:FBSDK_SERVER_CONFIGURATION_MIGRATED_AUTO_LOG_VALUES_KEY];
}

#pragma mark - NSCopying

- (instancetype)copyWithZone:(NSZone *)zone
{
  return self;
}

// Private accessors for unit tests
- (NSDictionary<NSString *, id> *)dialogConfigurations
{
  return _dialogConfigurations;
}

- (NSDictionary<NSString *, id> *)dialogFlows
{
  return _dialogFlows;
}

@end
