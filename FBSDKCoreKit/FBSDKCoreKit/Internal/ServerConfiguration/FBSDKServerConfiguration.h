/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

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

typedef NS_OPTIONS(NSUInteger, FBSDKServerConfigurationSmartLoginOptions) {
  FBSDKServerConfigurationSmartLoginOptionsUnknown = 0,
  FBSDKServerConfigurationSmartLoginOptionsEnabled = 1 << 0,
  FBSDKServerConfigurationSmartLoginOptionsRequireConfirmation = 1 << 1,
};

NS_SWIFT_NAME(ServerConfiguration)
@interface FBSDKServerConfiguration : NSObject <NSCopying, NSObject, NSSecureCoding>

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

- (instancetype)   initWithAppID:(NSString *)appID
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
          sessionTimeoutInterval:(NSTimeInterval)sessionTimeoutInterval
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

@property (nonatomic, readonly, getter = isAdvertisingIDEnabled, assign) BOOL advertisingIDEnabled;
@property (nonatomic, readonly, copy) NSString *appID;
@property (nullable, nonatomic, readonly, copy) NSString *appName;
@property (nonatomic, readonly, getter = isDefaults, assign) BOOL defaults;
@property (nullable, nonatomic, readonly, copy) NSString *defaultShareMode;
@property (nullable, nonatomic, readonly, strong) FBSDKErrorConfiguration *errorConfiguration;
@property (nonatomic, readonly, getter = isImplicitLoggingSupported, assign) BOOL implicitLoggingEnabled;
@property (nonatomic, readonly, getter = isImplicitPurchaseLoggingSupported, assign) BOOL implicitPurchaseLoggingEnabled;
@property (nonatomic, readonly, getter = isCodelessEventsEnabled, assign) BOOL codelessEventsEnabled;
@property (nonatomic, readonly, getter = isLoginTooltipEnabled, assign) BOOL loginTooltipEnabled;
@property (nonatomic, readonly, getter = isUninstallTrackingEnabled, assign) BOOL uninstallTrackingEnabled;
@property (nullable, nonatomic, readonly, copy) NSString *loginTooltipText;
@property (nullable, nonatomic, readonly, copy) NSDate *timestamp;
@property (nonatomic, assign) NSTimeInterval sessionTimoutInterval;
@property (nullable, nonatomic, readonly, copy) NSString *loggingToken;
@property (nonatomic, readonly, assign) FBSDKServerConfigurationSmartLoginOptions smartLoginOptions;
@property (nullable, nonatomic, readonly, copy) NSURL *smartLoginBookmarkIconURL;
@property (nullable, nonatomic, readonly, copy) NSURL *smartLoginMenuIconURL;
@property (nullable, nonatomic, readonly, copy) NSString *updateMessage;
@property (nullable, nonatomic, readonly, copy) NSArray *eventBindings;
@property (nullable, nonatomic, readonly, copy) NSDictionary<NSString *, id> *restrictiveParams;
@property (nullable, nonatomic, readonly, copy) NSDictionary<NSString *, id> *AAMRules;
@property (nullable, nonatomic, readonly, copy) NSDictionary<NSString *, id> *suggestedEventsSetting;
@property (nonatomic, readonly) NSInteger version;

- (nullable FBSDKDialogConfiguration *)dialogConfigurationForDialogName:(NSString *)dialogName;
- (BOOL)useNativeDialogForDialogName:(NSString *)dialogName;
- (BOOL)useSafariViewControllerForDialogName:(NSString *)dialogName;

@end

NS_ASSUME_NONNULL_END
