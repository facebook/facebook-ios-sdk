/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !TARGET_OS_TV

#import <Foundation/Foundation.h>

#import <FBSDKCoreKit/FBSDKAppLinkTargetProtocol.h>

NS_ASSUME_NONNULL_BEGIN

/**
 Represents a target defined in App Link metadata, consisting of at least
 a URL, and optionally an App Store ID and name.
 */
NS_SWIFT_NAME(AppLinkTarget)
@interface FBSDKAppLinkTarget : NSObject <FBSDKAppLinkTarget>

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

/** Creates a FBSDKAppLinkTarget with the given app site and target URL. */
// UNCRUSTIFY_FORMAT_OFF
+ (instancetype)appLinkTargetWithURL:(nullable NSURL *)url
                          appStoreId:(nullable NSString *)appStoreId
                             appName:(NSString *)appName
NS_SWIFT_NAME(init(url:appStoreId:appName:));
// UNCRUSTIFY_FORMAT_ON

/** The URL prefix for this app link target */
@property (nullable, nonatomic, readonly, strong) NSURL *URL;

/** The app ID for the app store */
@property (nullable, nonatomic, readonly, copy) NSString *appStoreId;

/** The name of the app */
@property (nonatomic, readonly, copy) NSString *appName;

@end

NS_ASSUME_NONNULL_END

#endif
