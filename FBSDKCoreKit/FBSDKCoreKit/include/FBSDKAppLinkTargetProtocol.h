/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !TARGET_OS_TV

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// A protocol to describe an AppLinkTarget
NS_SWIFT_NAME(AppLinkTargetProtocol)
@protocol FBSDKAppLinkTarget

+ (instancetype)appLinkTargetWithURL:(nullable NSURL *)url
                          appStoreId:(nullable NSString *)appStoreId
                             appName:(NSString *)appName
NS_SWIFT_NAME(init(url:appStoreId:appName:));

/** The URL prefix for this app link target */
@property (nullable, readonly, nonatomic) NSURL *URL;

/** The app ID for the app store */
@property (nullable, copy, readonly, nonatomic) NSString *appStoreId;

/** The name of the app */
@property (nonatomic, copy, readonly) NSString *appName;

@end

NS_ASSUME_NONNULL_END

#endif
