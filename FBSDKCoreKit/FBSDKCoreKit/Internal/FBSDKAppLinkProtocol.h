/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !TARGET_OS_TV

#import <Foundation/Foundation.h>

@protocol FBSDKAppLinkTarget;

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(AppLinkProtocol)
@protocol FBSDKAppLink

/** The URL from which this FBSDKAppLink was derived */
@property (nullable, nonatomic, readonly, strong) NSURL *sourceURL;

/**
 The ordered list of targets applicable to this platform that will be used
 for navigation.
 */
@property (nonatomic, readonly, copy) NSArray<id<FBSDKAppLinkTarget>> *targets;

/** The fallback web URL to use if no targets are installed on this device. */
@property (nullable, nonatomic, readonly, strong) NSURL *webURL;

/** return if this AppLink is to go back to referrer. */
@property (nonatomic, readonly, getter = isBackToReferrer, assign) BOOL backToReferrer;

@end

NS_ASSUME_NONNULL_END

#endif
