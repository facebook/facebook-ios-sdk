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

#import "FBSDKServerConfigurationFixtures.h"

@interface FBSDKServerConfiguration (Testing)

- (NSDictionary *)dialogConfigurations;
- (NSDictionary *)dialogFlows;

@end

@implementation FBSDKServerConfigurationFixtures

+ (FBSDKServerConfiguration *)defaultConfig
{
  return [FBSDKServerConfiguration defaultServerConfigurationForAppID:nil];
}

+ (FBSDKServerConfiguration *)configWithDictionary:(NSDictionary *)dict
{
  BOOL loginTooltipEnabled = self.defaultConfig.loginTooltipEnabled;
  if (dict[@"loginTooltipEnabled"]) {
    loginTooltipEnabled = [dict[@"loginTooltipEnabled"] intValue];
  }
  BOOL advertisingIDEnabled = self.defaultConfig.advertisingIDEnabled;
  if (dict[@"advertisingIDEnabled"]) {
    advertisingIDEnabled = [dict[@"advertisingIDEnabled"] intValue];
  }
  BOOL implicitLoggingEnabled = self.defaultConfig.implicitLoggingEnabled;
  if (dict[@"implicitLoggingEnabled"]) {
    implicitLoggingEnabled = [dict[@"implicitLoggingEnabled"] intValue];
  }
  BOOL implicitPurchaseLoggingEnabled = self.defaultConfig.implicitPurchaseLoggingEnabled;
  if (dict[@"implicitPurchaseLoggingEnabled"]) {
    implicitPurchaseLoggingEnabled = [dict[@"implicitPurchaseLoggingEnabled"] intValue];
  }
  BOOL codelessEventsEnabled = self.defaultConfig.codelessEventsEnabled;
  if (dict[@"codelessEventsEnabled"]) {
    codelessEventsEnabled = [dict[@"codelessEventsEnabled"] intValue];
  }
  BOOL uninstallTrackingEnabled = self.defaultConfig.uninstallTrackingEnabled;
  if (dict[@"uninstallTrackingEnabled"]) {
    uninstallTrackingEnabled = [dict[@"uninstallTrackingEnabled"] intValue];
  }
  BOOL smartLoginOptions = self.defaultConfig.smartLoginOptions;
  if (dict[@"smartLoginOptions"]) {
    smartLoginOptions = [dict[@"smartLoginOptions"] intValue];
  }
  BOOL defaults = self.defaultConfig.defaults;
  if (dict[@"defaults"]) {
    defaults = [dict[@"defaults"] intValue];
  }

  return [[FBSDKServerConfiguration alloc]
          initWithAppID:dict[@"appID"] ?: self.defaultConfig.appID
          appName:dict[@"appName"] ?: self.defaultConfig.appName
          loginTooltipEnabled:loginTooltipEnabled
          loginTooltipText:dict[@"loginTooltipText"] ?: self.defaultConfig.loginTooltipText
          defaultShareMode:dict[@"defaultShareMode"] ?: self.defaultConfig.defaultShareMode
          advertisingIDEnabled:advertisingIDEnabled
          implicitLoggingEnabled:implicitLoggingEnabled
          implicitPurchaseLoggingEnabled:implicitPurchaseLoggingEnabled
          codelessEventsEnabled:codelessEventsEnabled
          uninstallTrackingEnabled:uninstallTrackingEnabled
          dialogConfigurations:self.defaultConfig.dialogConfigurations ?: dict[@"dialogConfigurations"]
          dialogFlows:dict[@"dialogFlows"] ?: self.defaultConfig.dialogFlows
          timestamp:dict[@"timestamp"] ?: self.defaultConfig.timestamp
          errorConfiguration:dict[@"errorConfiguration"] ?: self.defaultConfig.errorConfiguration
          sessionTimeoutInterval:[dict[@"sessionTimeoutInterval"] intValue] ?: self.defaultConfig.sessionTimoutInterval
          defaults:defaults
          loggingToken:dict[@"loggingToken"] ?: self.defaultConfig.loggingToken
          smartLoginOptions:smartLoginOptions
          smartLoginBookmarkIconURL:dict[@"smartLoginBookmarkIconURL"] ?: self.defaultConfig.smartLoginBookmarkIconURL
          smartLoginMenuIconURL:dict[@"smartLoginMenuIconURL"] ?: self.defaultConfig.smartLoginMenuIconURL
          updateMessage:dict[@"updateMessage"] ?: self.defaultConfig.updateMessage
          eventBindings:dict[@"eventBindings"] ?: self.defaultConfig.eventBindings
          restrictiveParams:dict[@"restrictiveParams"] ?: self.defaultConfig.restrictiveParams
          AAMRules:dict[@"aamRules"] ?: self.defaultConfig.AAMRules
          suggestedEventsSetting:dict[@"suggestedEventsSetting"] ?: self.defaultConfig.suggestedEventsSetting
          monitoringConfiguration:dict[@"monitoringConfiguration"] ?: self.defaultConfig.monitoringConfiguration];
}

@end
