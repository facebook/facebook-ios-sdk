/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <FBSDKCoreKit/FBSDKAdvertisingTrackingStatus.h>
#import <FBSDKCoreKit/FBSDKLoggingBehavior.h>

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(SettingsProtocol)
@protocol FBSDKSettings

@property (nullable, nonatomic, copy) NSString *appID;
@property (nullable, nonatomic, copy) NSString *clientToken;
@property (nullable, nonatomic, copy) NSString *userAgentSuffix;
@property (nonatomic, readonly, copy) NSString *sdkVersion;
@property (nullable, nonatomic, copy) NSString *displayName;
@property (nullable, nonatomic, copy) NSString *facebookDomainPart;
@property (nonnull, nonatomic, copy) NSSet<FBSDKLoggingBehavior> *loggingBehaviors;
@property (class, nonnull, nonatomic, copy) NSSet<FBSDKLoggingBehavior> *loggingBehaviors
  DEPRECATED_MSG_ATTRIBUTE("property class `loggingBehaviors` is deprecated and will be removed in the next major release, please use property instance`loggingBehaviors` instead");
@property (nullable, nonatomic, copy) NSString *appURLSchemeSuffix;
@property (nonatomic, readonly) BOOL isDataProcessingRestricted;
@property (nonatomic, readonly) BOOL isAutoLogAppEventsEnabled;
@property (nonatomic, getter = isCodelessDebugLogEnabled) BOOL codelessDebugLogEnabled;
@property (nonatomic, getter = isAdvertiserIDCollectionEnabled) BOOL advertiserIDCollectionEnabled;
@property (nonatomic, readonly) BOOL isSetATETimeExceedsInstallTime;
@property (nonatomic, readonly) BOOL isSKAdNetworkReportEnabled;
@property (nonatomic, readonly) FBSDKAdvertisingTrackingStatus advertisingTrackingStatus;
@property (nullable, nonatomic, readonly) NSDate *installTimestamp;
@property (nullable, nonatomic, readonly) NSDate *advertiserTrackingEnabledTimestamp;
@property (nonatomic) BOOL isEventDataUsageLimited;
@property (nonatomic) BOOL shouldUseTokenOptimizations;
@property (nonatomic, copy) NSString *graphAPIVersion;
@property (nonatomic) BOOL isGraphErrorRecoveryEnabled;
@property (nullable, nonatomic, readonly, copy) NSString *graphAPIDebugParamValue;
@property (nonatomic, getter = isAdvertiserTrackingEnabled) BOOL advertiserTrackingEnabled;
@property (nonatomic) BOOL shouldUseCachedValuesForExpensiveMetadata;
@end
NS_ASSUME_NONNULL_END
