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

#import <Foundation/Foundation.h>

#import "FBSDKDialogConfiguration.h"
#import "FBSDKErrorConfiguration.h"

NS_ASSUME_NONNULL_BEGIN

// login kit
FOUNDATION_EXPORT NSString *const FBSDKDialogConfigurationNameLogin;

// share kit
FOUNDATION_EXPORT NSString *const FBSDKDialogConfigurationNameAppInvite;
FOUNDATION_EXPORT NSString *const FBSDKDialogConfigurationNameGameRequest;
FOUNDATION_EXPORT NSString *const FBSDKDialogConfigurationNameGroup;

FOUNDATION_EXPORT const NSInteger FBSDKServerConfigurationVersion;

typedef NS_OPTIONS(NSUInteger, FBSDKServerConfigurationSmartLoginOptions)
{
  FBSDKServerConfigurationSmartLoginOptionsUnknown = 0,
  FBSDKServerConfigurationSmartLoginOptionsEnabled = 1 << 0,
  FBSDKServerConfigurationSmartLoginOptionsRequireConfirmation  = 1 << 1,
};

NS_SWIFT_NAME(ServerConfiguration)
@interface FBSDKServerConfiguration : NSObject <NSCopying, NSObject, NSSecureCoding>

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

- (instancetype)initWithAppID:(NSString *)appID
                      appName:(nullable NSString *)appName
          loginTooltipEnabled:(BOOL)loginTooltipEnabled
             loginTooltipText:(nullable NSString *)loginTooltipText
             defaultShareMode:(nullable NSString *)defaultShareMode
         advertisingIDEnabled:(BOOL)advertisingIDEnabled
       implicitLoggingEnabled:(BOOL)implicitLoggingEnabled
implicitPurchaseLoggingEnabled:(BOOL)implicitPurchaseLoggingEnabled
        codelessEventsEnabled:(BOOL)codelessEventsEnabled
     uninstallTrackingEnabled:(BOOL)uninstallTrackingEnabled
         dialogConfigurations:(nullable NSDictionary<NSString *, id> *)dialogConfigurations
                  dialogFlows:(nullable NSDictionary<NSString *, id> *)dialogFlows
                    timestamp:(nullable NSDate *)timestamp
           errorConfiguration:(nullable FBSDKErrorConfiguration *)errorConfiguration
       sessionTimeoutInterval:(NSTimeInterval) sessionTimeoutInterval
                     defaults:(BOOL)defaults
                 loggingToken:(nullable NSString *)loggingToken
            smartLoginOptions:(FBSDKServerConfigurationSmartLoginOptions)smartLoginOptions
    smartLoginBookmarkIconURL:(nullable NSURL *)smartLoginBookmarkIconURL
        smartLoginMenuIconURL:(nullable NSURL *)smartLoginMenuIconURL
                updateMessage:(nullable NSString *)updateMessage
                eventBindings:(nullable NSArray *)eventBindings
            restrictiveParams:(nullable NSDictionary<NSString *, id> *)restrictiveParams
                     AAMRules:(nullable NSDictionary<NSString *, id> *)AAMRules
       suggestedEventsSetting:(nullable NSDictionary<NSString *, id> *)suggestedEventsSetting
NS_DESIGNATED_INITIALIZER;

@property (nonatomic, assign, readonly, getter=isAdvertisingIDEnabled) BOOL advertisingIDEnabled;
@property (nonatomic, copy, readonly) NSString *appID;
@property (nonatomic, nullable, copy, readonly) NSString *appName;
@property (nonatomic, assign, readonly, getter=isDefaults) BOOL defaults;
@property (nonatomic, nullable, copy, readonly) NSString *defaultShareMode;
@property (nonatomic, nullable, strong, readonly) FBSDKErrorConfiguration *errorConfiguration;
@property (nonatomic, assign, readonly, getter=isImplicitLoggingSupported) BOOL implicitLoggingEnabled;
@property (nonatomic, assign, readonly, getter=isImplicitPurchaseLoggingSupported) BOOL implicitPurchaseLoggingEnabled;
@property (nonatomic, assign, readonly, getter=isCodelessEventsEnabled) BOOL codelessEventsEnabled;
@property (nonatomic, assign, readonly, getter=isLoginTooltipEnabled) BOOL loginTooltipEnabled;
@property (nonatomic, assign, readonly, getter=isUninstallTrackingEnabled) BOOL uninstallTrackingEnabled;
@property (nonatomic, nullable, copy, readonly) NSString *loginTooltipText;
@property (nonatomic, nullable, copy, readonly) NSDate *timestamp;
@property (nonatomic, assign) NSTimeInterval sessionTimoutInterval;
@property (nonatomic, nullable, copy, readonly) NSString *loggingToken;
@property (nonatomic, assign, readonly) FBSDKServerConfigurationSmartLoginOptions smartLoginOptions;
@property (nonatomic, nullable, copy, readonly) NSURL *smartLoginBookmarkIconURL;
@property (nonatomic, nullable, copy, readonly) NSURL *smartLoginMenuIconURL;
@property (nonatomic, nullable, copy, readonly) NSString *updateMessage;
@property (nonatomic, nullable, copy, readonly) NSArray *eventBindings;
@property (nonatomic, nullable, copy, readonly) NSDictionary<NSString *, id> *restrictiveParams;
@property (nonatomic, nullable, copy, readonly) NSDictionary<NSString *, id> *AAMRules;
@property (nonatomic, nullable, copy, readonly) NSDictionary<NSString *, id> *suggestedEventsSetting;
@property (nonatomic, readonly) NSInteger version;

- (nullable FBSDKDialogConfiguration *)dialogConfigurationForDialogName:(NSString *)dialogName;
- (BOOL)useNativeDialogForDialogName:(NSString *)dialogName;
- (BOOL)useSafariViewControllerForDialogName:(NSString *)dialogName;

@end

NS_ASSUME_NONNULL_END
