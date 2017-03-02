// Copyright 2004-present Facebook. All Rights Reserved.
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
#import "SettingsUtil.h"

#import <AccountKit/AKFViewController.h>

#import "FBTweak/FBTweakInline.h"

#import "AdvancedUIManager.h"
#import "ReverbTheme.h"
#import "ReverbUIManager.h"
#import "Theme.h"

#define AddSettingsPermission(__mArray, __category, __permission) \
if (FBTweakValue(@"Settings", __category, __permission, NO)) { \
[__mArray addObject:__permission]; \
}

#define AddPublishPermission(__mArray, __permission) AddSettingsPermission(permissions, @"FB Login Publish Permissions",__permission)
#define AddReadPermission(__mArray, __permission) AddSettingsPermission(permissions, @"FB Login Read Permissions",__permission)

#define EntryButtonTypes @{ \
@(AKFButtonTypeDefault): @"Default", \
@(AKFButtonTypeOK): @"OK", \
@(AKFButtonTypeCount): @"Count", \
@(AKFButtonTypeNext): @"Next", \
@(AKFButtonTypeSend): @"Send", \
@(AKFButtonTypeBegin): @"Begin", \
@(AKFButtonTypeLogIn): @"Login", \
@(AKFButtonTypeStart): @"Start" \
}

@implementation SettingsUtil

static NSArray *fbPermissions;

+ (NSDictionary *)themeTweakValues
{
  NSMutableDictionary *ret = [NSMutableDictionary new];
  for (ThemeType themeType = ThemeTypeDefault; themeType < ThemeTypeCount; themeType++) {
    ret[@(themeType)] = [Theme labelForThemeType:themeType];
  }
  return [ret copy];
}

+ (NSDictionary *)entryButtonTweakValues
{
  return @{
           @(AKFButtonTypeDefault): @"Default",
           @(AKFButtonTypeOK): @"OK",
           @(AKFButtonTypeCount): @"Count",
           @(AKFButtonTypeNext): @"Next",
           @(AKFButtonTypeSend): @"Send",
           @(AKFButtonTypeBegin): @"Begin",
           @(AKFButtonTypeLogIn): @"Login",
           @(AKFButtonTypeStart): @"Start"
           };
}

+ (NSDictionary *)textPositionTweakValues
{
  return @{
           @(AKFTextPositionDefault): @"Default",
           @(AKFTextPositionCount): @"Count",
           @(AKFTextPositionAboveBody): @"Above Body",
           @(AKFTextPositionBelowBody): @"Below Body",
           };
}

+ (NSDictionary *)loginTypeTweakValues
{
  return @{
           @(AKFLoginTypePhone): @"Phone",
           @(AKFLoginTypeEmail): @"Email",
           };
}

+ (NSDictionary *)responseTypes
{
  return @{
           @(AKFResponseTypeAccessToken): @"Access Token",
           @(AKFResponseTypeAuthorizationCode): @"Authorization Code",
           };
}

+ (AKFResponseType)responseType
{
  return [FBTweakValue(@"Settings", @"AccountKit", @"Response Type", @(AKFResponseTypeAccessToken), [SettingsUtil responseTypes]) integerValue];
}

+ (Theme *)currentTheme
{
  ThemeType themeType = [FBTweakValue(@"Settings", @"AccountKit", @"Theme", @(ThemeTypeDefault), [SettingsUtil themeTweakValues]) integerValue];
  Theme *theme = nil;
  if ([Theme isReverbTheme:themeType]) {
    theme = [ReverbTheme themeWithType:themeType];
  } else {
    theme = [Theme themeWithType:themeType];
  }
  return theme;
}

+ (void)setAdvancedUIManagerForController:(id<AKFViewController>)controller
{
  Theme *theme = [self currentTheme];
  BOOL useAdvancedUIManager = FBTweakValue(@"Settings", @"AccountKit", @"Advanced Theme", NO);
  if (useAdvancedUIManager || [Theme isReverbTheme:theme.themeType]) {
    AKFButtonType entryButtonType = [FBTweakValue(@"Settings", @"AccountKit", @"Entry Button", @(AKFButtonTypeDefault), [SettingsUtil entryButtonTweakValues]) integerValue];
    AKFButtonType confirmButtonType = [FBTweakValue(@"Settings", @"AccountKit", @"Confirm Button", @(AKFButtonTypeDefault), [SettingsUtil entryButtonTweakValues]) integerValue];
    AKFTextPosition textPosition = [FBTweakValue(@"Settings", @"AccountKit", @"Text Position", @(AKFButtonTypeDefault), [SettingsUtil textPositionTweakValues]) integerValue];
    if ([Theme isReverbTheme:theme.themeType]) {
      controller.uiManager = [[ReverbUIManager alloc] initWithConfirmButtonType:confirmButtonType
                                                                entryButtonType:entryButtonType
                                                                      loginType:controller.loginType
                                                                   textPosition:textPosition
                                                                          theme:(ReverbTheme *)theme
                                                                       delegate:nil];
    } else {
      controller.uiManager = [[AdvancedUIManager alloc] initWithConfirmButtonType:confirmButtonType
                                                                  entryButtonType:entryButtonType
                                                                        loginType:controller.loginType
                                                                     textPosition:textPosition];
    }
  }
}

+ (NSArray *)publishPermissions
{
  NSMutableArray *permissions = [NSMutableArray new];
  AddPublishPermission(permissions, @"publish_actions");
  AddPublishPermission(permissions, @"publish_pages");
  return [permissions copy];
}

+ (NSArray *)readPermissions
{
  NSMutableArray *permissions = [NSMutableArray new];
  AddReadPermission(permissions, @"public_profile");
  AddReadPermission(permissions, @"user_friends");
  AddReadPermission(permissions, @"email");
  AddReadPermission(permissions, @"user_mobile_phone");
  AddReadPermission(permissions, @"user_about_me");
  AddReadPermission(permissions, @"user_actions.books");
  AddReadPermission(permissions, @"user_actions.fitness");
  AddReadPermission(permissions, @"user_actions.music");
  AddReadPermission(permissions, @"user_actions.news");
  AddReadPermission(permissions, @"user_actions.video");
  AddReadPermission(permissions, @"user_birthday");
  AddReadPermission(permissions, @"user_education_history");
  AddReadPermission(permissions, @"user_events");
  AddReadPermission(permissions, @"user_games_activity");
  AddReadPermission(permissions, @"user_hometown");
  AddReadPermission(permissions, @"user_likes");
  AddReadPermission(permissions, @"user_location");
  AddReadPermission(permissions, @"user_managed_groups");
  AddReadPermission(permissions, @"user_photos");
  AddReadPermission(permissions, @"user_posts");
  AddReadPermission(permissions, @"user_relationships");
  AddReadPermission(permissions, @"user_relationship_details");
  AddReadPermission(permissions, @"user_religion_politics");
  AddReadPermission(permissions, @"user_tagged_places");
  AddReadPermission(permissions, @"user_videos");
  AddReadPermission(permissions, @"user_website");
  AddReadPermission(permissions, @"user_work_history");
  AddReadPermission(permissions, @"read_custom_friendlists");
  AddReadPermission(permissions, @"read_insights");
  AddReadPermission(permissions, @"read_audience_network_insights");
  AddReadPermission(permissions, @"read_page_mailboxes");
  AddReadPermission(permissions, @"manage_pages");
  AddReadPermission(permissions, @"rsvp_event");
  AddReadPermission(permissions, @"pages_show_list");
  AddReadPermission(permissions, @"pages_manage_cta");
  AddReadPermission(permissions, @"pages_manage_instant_articles");
  AddReadPermission(permissions, @"ads_read");
  AddReadPermission(permissions, @"ads_management");
  AddReadPermission(permissions, @"business_management");
  AddReadPermission(permissions, @"pages_messaging");
  AddReadPermission(permissions, @"pages_messaging_phone_number");
 return [permissions copy];
}

@end
