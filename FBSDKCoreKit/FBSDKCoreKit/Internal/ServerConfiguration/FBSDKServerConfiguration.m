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

#import "FBSDKServerConfiguration.h"

#import "FBSDKMacros.h"

#define FBSDK_SERVER_CONFIGURATION_ADVERTISING_ID_ENABLED_KEY @"advertisingIDEnabled"
#define FBSDK_SERVER_CONFIGURATION_APP_ID_KEY @"appID"
#define FBSDK_SERVER_CONFIGURATION_APP_NAME_KEY @"appName"
#define FBSDK_SERVER_CONFIGURATION_DIALOG_CONFIGS_KEY @"dialogConfigs"
#define FBSDK_SERVER_CONFIGURATION_ERROR_CONFIGS_KEY @"errorConfigs"
#define FBSDK_SERVER_CONFIGURATION_IMPLICIT_LOGGING_ENABLED_KEY @"implicitLoggingEnabled"
#define FBSDK_SERVER_CONFIGURATION_IMPLICIT_PURCHASE_LOGGING_ENABLED_KEY @"implicitPurchaseLoggingEnabled"
#define FBSDK_SERVER_CONFIGURATION_LOGIN_TOOLTIP_ENABLED_KEY @"loginTooltipEnabled"
#define FBSDK_SERVER_CONFIGURATION_LOGIN_TOOLTIP_TEXT_KEY @"loginTooltipText"
#define FBSDK_SERVER_CONFIGURATION_SYSTEM_AUTHENTICATION_ENABLED_KEY @"systemAuthenticationEnabled"
#define FBSDK_SERVER_CONFIGURATION_TIMESTAMP_KEY @"timestamp"

@implementation FBSDKServerConfiguration
{
  NSDictionary *_dialogConfigurations;
}

#pragma mark - Object Lifecycle

- (instancetype)initWithAppID:(NSString *)appID
                      appName:(NSString *)appName
          loginTooltipEnabled:(BOOL)loginTooltipEnabled
             loginTooltipText:(NSString *)loginTooltipText
         advertisingIDEnabled:(BOOL)advertisingIDEnabled
       implicitLoggingEnabled:(BOOL)implicitLoggingEnabled
implicitPurchaseLoggingEnabled:(BOOL)implicitPurchaseLoggingEnabled
  systemAuthenticationEnabled:(BOOL)systemAuthenticationEnabled
         dialogConfigurations:(NSDictionary *)dialogConfigurations
                    timestamp:(NSDate *)timestamp
           errorConfiguration:(FBSDKErrorConfiguration *)errorConfiguration
{
  if ((self = [super init])) {
    _appID = [appID copy];
    _appName = [appName copy];
    _loginTooltipEnabled = loginTooltipEnabled;
    _loginTooltipText = [loginTooltipText copy];
    _advertisingIDEnabled = advertisingIDEnabled;
    _implicitLoggingEnabled = implicitLoggingEnabled;
    _implicitPurchaseLoggingEnabled = implicitPurchaseLoggingEnabled;
    _systemAuthenticationEnabled = systemAuthenticationEnabled;
    _dialogConfigurations = [dialogConfigurations copy];
    _timestamp = [timestamp copy];
    _errorConfiguration = [errorConfiguration copy];
  }
  return self;
}

#pragma mark - Public Methods

- (FBSDKDialogConfiguration *)dialogConfigurationForDialogName:(NSString *)dialogName
{
  return _dialogConfigurations[dialogName];
}

#pragma mark - NSCoding

+ (BOOL)supportsSecureCoding
{
  return YES;
}

- (id)initWithCoder:(NSCoder *)decoder
{
  NSString *appID = [decoder decodeObjectOfClass:[NSString class] forKey:FBSDK_SERVER_CONFIGURATION_APP_ID_KEY];
  NSString *appName = [decoder decodeObjectOfClass:[NSString class] forKey:FBSDK_SERVER_CONFIGURATION_APP_NAME_KEY];
  BOOL loginTooltipEnabled = [decoder decodeBoolForKey:FBSDK_SERVER_CONFIGURATION_LOGIN_TOOLTIP_ENABLED_KEY];
  NSString *loginTooltipText = [decoder decodeObjectOfClass:[NSString class]
                                                     forKey:FBSDK_SERVER_CONFIGURATION_LOGIN_TOOLTIP_TEXT_KEY];
  BOOL advertisingIDEnabled = [decoder decodeBoolForKey:FBSDK_SERVER_CONFIGURATION_ADVERTISING_ID_ENABLED_KEY];
  BOOL implicitLoggingEnabled = [decoder decodeBoolForKey:FBSDK_SERVER_CONFIGURATION_IMPLICIT_LOGGING_ENABLED_KEY];
  BOOL implicitPurchaseLoggingEnabbled =
  [decoder decodeBoolForKey:FBSDK_SERVER_CONFIGURATION_IMPLICIT_PURCHASE_LOGGING_ENABLED_KEY];
  BOOL systemAuthenticationEnabled =
  [decoder decodeBoolForKey:FBSDK_SERVER_CONFIGURATION_SYSTEM_AUTHENTICATION_ENABLED_KEY];
  NSDate *timestamp = [decoder decodeObjectOfClass:[NSDate class] forKey:FBSDK_SERVER_CONFIGURATION_TIMESTAMP_KEY];
  NSSet *dialogConfigurationsClasses = [[NSSet alloc] initWithObjects:
                                        [NSDictionary class],
                                        [FBSDKDialogConfiguration class],
                                        nil];
  NSDictionary *dialogConfigurations = [decoder decodeObjectOfClasses:dialogConfigurationsClasses
                                                               forKey:FBSDK_SERVER_CONFIGURATION_DIALOG_CONFIGS_KEY];
  FBSDKErrorConfiguration *errorConfiguration = [decoder decodeObjectOfClass:[FBSDKErrorConfiguration class] forKey:FBSDK_SERVER_CONFIGURATION_ERROR_CONFIGS_KEY];
  return [self initWithAppID:appID
                     appName:appName
         loginTooltipEnabled:loginTooltipEnabled
            loginTooltipText:loginTooltipText
        advertisingIDEnabled:advertisingIDEnabled
      implicitLoggingEnabled:implicitLoggingEnabled
implicitPurchaseLoggingEnabled:implicitPurchaseLoggingEnabbled
 systemAuthenticationEnabled:systemAuthenticationEnabled
        dialogConfigurations:dialogConfigurations
                   timestamp:timestamp
          errorConfiguration:errorConfiguration];
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
  [encoder encodeBool:_advertisingIDEnabled forKey:FBSDK_SERVER_CONFIGURATION_ADVERTISING_ID_ENABLED_KEY];
  [encoder encodeObject:_appID forKey:FBSDK_SERVER_CONFIGURATION_APP_ID_KEY];
  [encoder encodeObject:_appName forKey:FBSDK_SERVER_CONFIGURATION_APP_NAME_KEY];
  [encoder encodeObject:_dialogConfigurations forKey:FBSDK_SERVER_CONFIGURATION_DIALOG_CONFIGS_KEY];
  [encoder encodeBool:_implicitLoggingEnabled forKey:FBSDK_SERVER_CONFIGURATION_IMPLICIT_LOGGING_ENABLED_KEY];
  [encoder encodeBool:_implicitPurchaseLoggingEnabled
               forKey:FBSDK_SERVER_CONFIGURATION_IMPLICIT_PURCHASE_LOGGING_ENABLED_KEY];
  [encoder encodeBool:_loginTooltipEnabled forKey:FBSDK_SERVER_CONFIGURATION_LOGIN_TOOLTIP_ENABLED_KEY];
  [encoder encodeObject:_loginTooltipText forKey:FBSDK_SERVER_CONFIGURATION_LOGIN_TOOLTIP_TEXT_KEY];
  [encoder encodeBool:_systemAuthenticationEnabled forKey:FBSDK_SERVER_CONFIGURATION_SYSTEM_AUTHENTICATION_ENABLED_KEY];
  [encoder encodeObject:_timestamp forKey:FBSDK_SERVER_CONFIGURATION_TIMESTAMP_KEY];
  [encoder encodeObject:_errorConfiguration forKey:FBSDK_SERVER_CONFIGURATION_ERROR_CONFIGS_KEY];
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone
{
  return self;
}

@end
