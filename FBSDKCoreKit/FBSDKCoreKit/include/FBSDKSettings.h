/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <UIKit/UIKit.h>

#import <FBSDKCoreKit/FBSDKLoggingBehavior.h>
#import <FBSDKCoreKit/FBSDKSettingsProtocol.h>

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(Settings)
@interface FBSDKSettings : NSObject <FBSDKSettings>

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

/**
 The shared settings instance. Prefer this and the exposed instance methods over the class variants.
 */
@property (class, nonatomic, readonly) FBSDKSettings *sharedSettings;

/**
 Retrieve the current iOS SDK version.
 */
@property (nonatomic, readonly, copy) NSString *sdkVersion;

/**
 Retrieve the current iOS SDK version.
 */
@property (class, nonatomic, readonly, copy) NSString *sdkVersion
  DEPRECATED_MSG_ATTRIBUTE("`Settings.sdkVersion` is deprecated and will be removed in the next major release, please use `Settings.shared.sdkVersion` instead");

/**
 Retrieve the current default Graph API version.
 */
@property (class, nonatomic, readonly, copy) NSString *defaultGraphAPIVersion
  DEPRECATED_MSG_ATTRIBUTE("`Settings.defaultGraphAPIVersion` is deprecated and will be removed in the next major release, please use `Settings.shared.defaultGraphAPIVersion` instead");

/**
 Retrieve the current default Graph API version.
 */
@property (nonatomic, readonly, copy) NSString *defaultGraphAPIVersion;

/**
 The quality of JPEG images sent to Facebook from the SDK,
 expressed as a value from 0.0 to 1.0.

 If not explicitly set, the default is 0.9.

 @see [UIImageJPEGRepresentation](https://developer.apple.com/library/ios/documentation/UIKit/Reference/UIKitFunctionReference/#//apple_ref/c/func/UIImageJPEGRepresentation) */
@property (class, nonatomic) CGFloat JPEGCompressionQuality
NS_SWIFT_NAME(jpegCompressionQuality)
DEPRECATED_MSG_ATTRIBUTE("`Settings.JPEGCompressionQuality` is deprecated and will be removed in the next major release, please use `Settings.shared.JPEGCompressionQuality` instead");

/**
 The quality of JPEG images sent to Facebook from the SDK,
 expressed as a value from 0.0 to 1.0.

 If not explicitly set, the default is 0.9.

 @see [UIImageJPEGRepresentation](https://developer.apple.com/library/ios/documentation/UIKit/Reference/UIKitFunctionReference/#//apple_ref/c/func/UIImageJPEGRepresentation) */
@property (nonatomic) CGFloat JPEGCompressionQuality
NS_SWIFT_NAME(jpegCompressionQuality);

/**
 Controls the auto logging of basic app events, such as activateApp and deactivateApp.
 If not explicitly set, the default is true
 */
@property (class, nonatomic, getter = isAutoLogAppEventsEnabled) BOOL autoLogAppEventsEnabled
  DEPRECATED_MSG_ATTRIBUTE("`Settings.isAutoLogAppEventsEnabled` is deprecated and will be removed in the next major release, please use `Settings.shared.isAutoLogAppEventsEnabled` instead");

/**
 Controls the auto logging of basic app events, such as activateApp and deactivateApp.
 If not explicitly set, the default is true
 */
@property (nonatomic, getter = isAutoLogAppEventsEnabled) BOOL autoLogAppEventsEnabled;

/**
 Controls the fb_codeless_debug logging event
 If not explicitly set, the default is true
 */
@property (class, nonatomic, getter = isCodelessDebugLogEnabled) BOOL codelessDebugLogEnabled
  DEPRECATED_MSG_ATTRIBUTE("`Settings.isCodelessDebugLogEnabled` is deprecated and will be removed in the next major release, please use `Settings.shared.isCodelessDebugLogEnabled` instead");

/**
 Controls the fb_codeless_debug logging event
 If not explicitly set, the default is true
 */
@property (nonatomic, getter = isCodelessDebugLogEnabled) BOOL codelessDebugLogEnabled;

/**
 Controls the access to IDFA
 If not explicitly set, the default is true
 */
@property (class, nonatomic, getter = isAdvertiserIDCollectionEnabled) BOOL advertiserIDCollectionEnabled
  DEPRECATED_MSG_ATTRIBUTE("`Settings.isAdvertiserIDCollectionEnabled` is deprecated and will be removed in the next major release, please use `Settings.shared.isAdvertiserIDCollectionEnabled` instead");

/**
 Controls the access to IDFA
 If not explicitly set, the default is true
 */
@property (nonatomic, getter = isAdvertiserIDCollectionEnabled) BOOL advertiserIDCollectionEnabled;

/**
 Controls the SKAdNetwork report
 If not explicitly set, the default is true
 */
@property (class, nonatomic, getter = isSKAdNetworkReportEnabled) BOOL SKAdNetworkReportEnabled
  DEPRECATED_MSG_ATTRIBUTE("`Settings.isSKAdNetworkReportEnabled` is deprecated and will be removed in the next major release, please use `Settings.shared.isSKAdNetworkReportEnabled` instead");

/**
 Controls the SKAdNetwork report
 If not explicitly set, the default is true
 */
@property (nonatomic, getter = isSKAdNetworkReportEnabled) BOOL skAdNetworkReportEnabled;

/**
 Whether data such as that generated through FBSDKAppEvents and sent to Facebook
 should be restricted from being used for other than analytics and conversions.
 Defaults to NO. This value is stored on the device and persists across app launches.
 */
@property (class, nonatomic, getter = shouldLimitEventAndDataUsage) BOOL limitEventAndDataUsage
  DEPRECATED_MSG_ATTRIBUTE("`Settings.shouldLimitEventAndDataUsage` is deprecated and will be removed in the next major release, please use `Settings.shared.isEventDataUsageLimited` instead");

/**
 Whether data such as that generated through FBSDKAppEvents and sent to Facebook
 should be restricted from being used for other than analytics and conversions.
 Defaults to NO. This value is stored on the device and persists across app launches.
 */
@property (nonatomic) BOOL isEventDataUsageLimited;

/**
 Whether in memory cached values should be used for expensive metadata fields, such as
 carrier and advertiser ID, that are fetched on many applicationDidBecomeActive notifications.
 Defaults to NO. This value is stored on the device and persists across app launches.
 */
@property (class, nonatomic, getter = shouldUseCachedValuesForExpensiveMetadata) BOOL shouldUseCachedValuesForExpensiveMetadata
  DEPRECATED_MSG_ATTRIBUTE("`Settings.shouldUseCachedValuesForExpensiveMetadata` is deprecated and will be removed in the next major release, please use `Settings.shared.shouldUseCachedValuesForExpensiveMetadata` instead");

/**
 Whether in memory cached values should be used for expensive metadata fields, such as
 carrier and advertiser ID, that are fetched on many applicationDidBecomeActive notifications.
 Defaults to NO. This value is stored on the device and persists across app launches.
 */
@property (nonatomic) BOOL shouldUseCachedValuesForExpensiveMetadata;

/**
 A convenient way to toggle error recovery for all FBSDKGraphRequest instances created after this is set.
 */
@property (class, nonatomic, getter = isGraphErrorRecoveryEnabled) BOOL graphErrorRecoveryEnabled
  DEPRECATED_MSG_ATTRIBUTE("`Settings.isGraphErrorRecoveryEnabled` is deprecated and will be removed in the next major release, please use `Settings.shared.isGraphErrorRecoveryEnabled` instead");

/**
 A convenient way to toggle error recovery for all FBSDKGraphRequest instances created after this is set.
 */
@property (nonatomic) BOOL isGraphErrorRecoveryEnabled;

/**
  The Facebook App ID used by the SDK.

 If not explicitly set, the default will be read from the application's plist (FacebookAppID).
 */
@property (nullable, nonatomic, copy) NSString *appID;

/**
  The Facebook App ID used by the SDK.

 If not explicitly set, the default will be read from the application's plist (FacebookAppID).
 */
@property (class, nullable, nonatomic, copy) NSString *appID
  DEPRECATED_MSG_ATTRIBUTE("`Settings.appID` is deprecated and will be removed in the next major release, please use `Settings.shared.appID` instead");

/**
  The default url scheme suffix used for sessions.

 If not explicitly set, the default will be read from the application's plist (FacebookUrlSchemeSuffix).
 */
@property (class, nullable, nonatomic, copy) NSString *appURLSchemeSuffix
  DEPRECATED_MSG_ATTRIBUTE("`Settings.appURLSchemeSuffix` is deprecated and will be removed in the next major release, please use `Settings.shared.appURLSchemeSuffix` instead");

/**
  The default url scheme suffix used for sessions.

 If not explicitly set, the default will be read from the application's plist (FacebookUrlSchemeSuffix).
 */
@property (nullable, nonatomic, copy) NSString *appURLSchemeSuffix;

/**
  The Client Token that has been set via [[FBSDKSettings sharedSettings] setClientToken].
 This is needed for certain API calls when made anonymously, without a user-based access token.

 The Facebook App's "client token", which, for a given appid can be found in the Security
 section of the Advanced tab of the Facebook App settings found at <https://developers.facebook.com/apps/[your-app-id]>

 If not explicitly set, the default will be read from the application's plist (FacebookClientToken).
 */
@property (nullable, nonatomic, copy) NSString *clientToken;

/**
  The Client Token that has been set via [[FBSDKSettings sharedSettings] setClientToken].
 This is needed for certain API calls when made anonymously, without a user-based access token.

 The Facebook App's "client token", which, for a given appid can be found in the Security
 section of the Advanced tab of the Facebook App settings found at <https://developers.facebook.com/apps/[your-app-id]>

 If not explicitly set, the default will be read from the application's plist (FacebookClientToken).
 */
@property (class, nullable, nonatomic, copy) NSString *clientToken
  DEPRECATED_MSG_ATTRIBUTE("`Settings.clientToken` is deprecated and will be removed in the next major release, please use `Settings.shared.clientToken` instead");

/**
  The Facebook Display Name used by the SDK.

 This should match the Display Name that has been set for the app with the corresponding Facebook App ID,
 in the Facebook App Dashboard.

 If not explicitly set, the default will be read from the application's plist (FacebookDisplayName).
 */
@property (class, nullable, nonatomic, copy) NSString *displayName
  DEPRECATED_MSG_ATTRIBUTE("`Settings.displayName` is deprecated and will be removed in the next major release, please use `Settings.shared.displayName` instead");

/**
  The Facebook Display Name used by the SDK.

 This should match the Display Name that has been set for the app with the corresponding Facebook App ID,
 in the Facebook App Dashboard.

 If not explicitly set, the default will be read from the application's plist (FacebookDisplayName).
 */
@property (nullable, nonatomic, copy) NSString *displayName;

/**
 The Facebook domain part. This can be used to change the Facebook domain
 (e.g. @"beta") so that requests will be sent to `graph.beta.facebook.com`

 If not explicitly set, the default will be read from the application's plist (FacebookDomainPart).
 */
@property (class, nullable, nonatomic, copy) NSString *facebookDomainPart
  DEPRECATED_MSG_ATTRIBUTE("`Settings.facebookDomainPart` is deprecated and will be removed in the next major release, please use `Settings.shared.facebookDomainPart` instead");

/**
 The Facebook domain part. This can be used to change the Facebook domain
 (e.g. @"beta") so that requests will be sent to `graph.beta.facebook.com`

 If not explicitly set, the default will be read from the application's plist (FacebookDomainPart).
 */
@property (nullable, nonatomic, copy) NSString *facebookDomainPart;

/**
  The current Facebook SDK logging behavior. This should consist of strings
 defined as constants with FBSDKLoggingBehavior*.

 This should consist a set of strings indicating what information should be logged
 defined as constants with FBSDKLoggingBehavior*. Set to an empty set in order to disable all logging.

 You can also define this via an array in your app plist with key "FacebookLoggingBehavior" or add and remove individual values via enableLoggingBehavior: or disableLoggingBehavior:

 The default is a set consisting of FBSDKLoggingBehaviorDeveloperErrors
 */
@property (class, nonatomic, copy) NSSet<FBSDKLoggingBehavior> *loggingBehaviors
  DEPRECATED_MSG_ATTRIBUTE("`Settings.loggingBehaviors` is deprecated and will be removed in the next major release, please use `Settings.shared.loggingBehaviors` instead");

/**
  The current Facebook SDK logging behavior. This should consist of strings
 defined as constants with FBSDKLoggingBehavior*.

 This should consist a set of strings indicating what information should be logged
 defined as constants with FBSDKLoggingBehavior*. Set to an empty set in order to disable all logging.

 You can also define this via an array in your app plist with key "FacebookLoggingBehavior" or add and remove individual values via enableLoggingBehavior: or disableLoggingBehavior:

 The default is a set consisting of FBSDKLoggingBehaviorDeveloperErrors
 */
@property (nonatomic, copy) NSSet<FBSDKLoggingBehavior> *loggingBehaviors;

/**
  Overrides the default Graph API version to use with `FBSDKGraphRequests`.

 The string should be of the form `@"v2.7"`.

 Defaults to `defaultGraphAPIVersion`.
*/
@property (class, null_resettable, nonatomic, copy) NSString *graphAPIVersion
  DEPRECATED_MSG_ATTRIBUTE("`Settings.graphAPIVersion` is deprecated and will be removed in the next major release, please use the `Settings.shared.graphAPIVersion` property instead");

/**
  Overrides the default Graph API version to use with `FBSDKGraphRequests`.

 The string should be of the form `@"v2.7"`.

 Defaults to `defaultGraphAPIVersion`.
*/
@property (nonatomic, copy) NSString *graphAPIVersion;

/**
 Internal property exposed to facilitate transition to Swift.
 API Subject to change or removal without warning. Do not use.

 @warning INTERNAL - DO NOT USE
 */
@property (nullable, nonatomic, copy) NSString *userAgentSuffix;

/**
 The value of the flag advertiser_tracking_enabled that controls the advertiser tracking status of the data sent to Facebook
 If not explicitly set in iOS14 or above, the default is false in iOS14 or above.
 */
@property (nonatomic, getter = isAdvertiserTrackingEnabled) BOOL advertiserTrackingEnabled;

/**
 The value of the flag advertiser_tracking_enabled that controls the advertiser tracking status of the data sent to Facebook
 If not explicitly set in iOS14 or above, the default is false in iOS14 or above.
 */
+ (BOOL)isAdvertiserTrackingEnabled
    DEPRECATED_MSG_ATTRIBUTE("`Settings.isAdvertiserTrackingEnabled()` is deprecated and will be removed in the next major release, please use the `Settings.shared.isAdvertiserTrackingEnabled` property instead");

/**
Set the advertiser_tracking_enabled flag. It only works in iOS14 and above.

@param advertiserTrackingEnabled the value of the flag
@return Whether the the value is set successfully. It will always return NO in iOS 13 and below.
 */
+ (BOOL)setAdvertiserTrackingEnabled:(BOOL)advertiserTrackingEnabled
    DEPRECATED_MSG_ATTRIBUTE("`Settings.setAdvertiserTrackingEnabled(_:)` is deprecated and will be removed in the next major release, please use the `Settings.shared.isAdvertiserTrackingEnabled` property to set a value instead");

/**
Set the data processing options.

@param options list of options
*/
+ (void)setDataProcessingOptions:(nullable NSArray<NSString *> *)options
    DEPRECATED_MSG_ATTRIBUTE("`Settings.setDataProcessingOptions(_:)` is deprecated and will be removed in the next major release, please use the `Settings.shared.setDataProcessingOptions(_:)` method to set the data processing options instead");

/**
Set the data processing options.

@param options list of options
*/
- (void)setDataProcessingOptions:(nullable NSArray<NSString *> *)options;

/**
Set the data processing options.

@param options list of the options
@param country code of the country
@param state code of the state
*/
+ (void)setDataProcessingOptions:(nullable NSArray<NSString *> *)options
                         country:(int)country
                           state:(int)state
    DEPRECATED_MSG_ATTRIBUTE("`Settings.setDataProcessingOptions(_:_:_:)` is deprecated and will be removed in the next major release, please use the `Settings.shared.setDataProcessingOptions(_:_:_:)` method to set the data processing options instead");

/**
Set the data processing options.

@param options list of the options
@param country code of the country
@param state code of the state
*/
- (void)setDataProcessingOptions:(nullable NSArray<NSString *> *)options
                         country:(int)country
                           state:(int)state;

/**
 Enable a particular Facebook SDK logging behavior.

 @param loggingBehavior The LoggingBehavior to enable. This should be a string defined as a constant with FBSDKLoggingBehavior*.
 */
+ (void)enableLoggingBehavior:(FBSDKLoggingBehavior)loggingBehavior
    DEPRECATED_MSG_ATTRIBUTE("`Settings.enableLoggingBehavior()` is deprecated and will be removed in the next major release, please use `Settings.shared.enableLoggingBehavior()` instead");

/**
 Enable a particular Facebook SDK logging behavior.

 @param loggingBehavior The LoggingBehavior to enable. This should be a string defined as a constant with FBSDKLoggingBehavior*.
 */
- (void)enableLoggingBehavior:(FBSDKLoggingBehavior)loggingBehavior;

/**
 Disable a particular Facebook SDK logging behavior.

 @param loggingBehavior The LoggingBehavior to disable. This should be a string defined as a constant with FBSDKLoggingBehavior*.
 */
+ (void)disableLoggingBehavior:(FBSDKLoggingBehavior)loggingBehavior
    DEPRECATED_MSG_ATTRIBUTE("`Settings.disableLoggingBehavior()` is deprecated and will be removed in the next major release, please use `Settings.shared.disableLoggingBehavior()` instead");

/**
 Disable a particular Facebook SDK logging behavior.

 @param loggingBehavior The LoggingBehavior to disable. This should be a string defined as a constant with FBSDKLoggingBehavior*.
 */
- (void)disableLoggingBehavior:(FBSDKLoggingBehavior)loggingBehavior;

@end

NS_ASSUME_NONNULL_END
