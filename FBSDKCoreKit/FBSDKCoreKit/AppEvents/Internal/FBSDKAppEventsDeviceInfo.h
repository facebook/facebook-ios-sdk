/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <Foundation/Foundation.h>

#import <FBSDKCoreKit/FBSDKSettingsProtocol.h>

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(AppEventsDeviceInfo)
@interface FBSDKAppEventsDeviceInfo : NSObject

@property (class, nonnull, nonatomic, readonly) FBSDKAppEventsDeviceInfo *shared;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

- (void)configureWithSettings:(id<FBSDKSettings>)settings;
- (void)extendDictionaryWithDeviceInfo:(NSMutableDictionary<NSString *, id> *)dictionary;

#if FBTEST && DEBUG
+ (void)reset;
#endif

@end

NS_ASSUME_NONNULL_END
