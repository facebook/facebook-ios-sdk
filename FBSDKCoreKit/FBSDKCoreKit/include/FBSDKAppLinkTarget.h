/*
 * Copyright (c) Facebook, Inc. and its affiliates.
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
+ (instancetype)appLinkTargetWithURL:(nullable NSURL *)url
                          appStoreId:(nullable NSString *)appStoreId
                             appName:(NSString *)appName
NS_SWIFT_NAME(init(url:appStoreId:appName:));

/** The URL prefix for this app link target */
@property (nonatomic, strong, readonly, nullable) NSURL *URL;

/** The app ID for the app store */
@property (nonatomic, copy, readonly, nullable) NSString *appStoreId;

/** The name of the app */
@property (nonatomic, copy, readonly) NSString *appName;

@end

NS_ASSUME_NONNULL_END

#endif
