/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "FBSDKCodelessIndexer+Internal.h"

NS_ASSUME_NONNULL_BEGIN

@interface FBSDKCodelessIndexer (Testing)

@property (class, nullable, nonatomic, readonly) id<FBSDKGraphRequestFactory> graphRequestFactory;
@property (class, nullable, nonatomic, readonly) id<FBSDKServerConfigurationProviding> serverConfigurationProvider;
@property (class, nullable, nonatomic, readonly) id<FBSDKDataPersisting> dataStore;
@property (class, nullable, nonatomic, readonly) id<FBSDKGraphRequestConnectionFactory> graphRequestConnectionFactory;
@property (class, nullable, nonatomic, readonly) Class<FBSDKSwizzling> swizzler;
@property (class, nullable, nonatomic, readonly) id<FBSDKSettings> settings;
@property (class, nullable, nonatomic, readonly) id<FBSDKAdvertiserIDProviding> advertiserIDProvider;
@property (class, nullable, nonatomic, readonly) NSString *currentSessionDeviceID;
@property (class, readonly) BOOL isCheckingSession;
@property (class, nullable, nonatomic, readonly) NSTimer *appIndexingTimer;

// UNCRUSTIFY_FORMAT_OFF
+ (nullable id<FBSDKGraphRequest>)requestToLoadCodelessSetup:(NSString *)appID
NS_SWIFT_NAME(requestToLoadCodelessSetup(appID:));
// UNCRUSTIFY_FORMAT_ON

+ (void)loadCodelessSettingWithCompletionBlock:(FBSDKCodelessSettingLoadBlock)completionBlock;
+ (void)uploadIndexing:(nullable NSString *)tree;
+ (void)checkCodelessIndexingSession;
+ (NSDictionary<NSString *, NSNumber *> *)dimensionOf:(NSObject *)obj;

+ (void)reset;
+ (void)resetIsCodelessIndexing;

@end

NS_ASSUME_NONNULL_END
