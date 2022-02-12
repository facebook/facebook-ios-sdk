/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !TARGET_OS_TV

#import <Foundation/Foundation.h>

#import <FBSDKCoreKit/FBSDKAppLinkTarget.h>

NS_ASSUME_NONNULL_BEGIN

/// The version of the App Link protocol that this library supports
FOUNDATION_EXPORT NSString *const FBSDKAppLinkVersion
NS_SWIFT_NAME(AppLinkVersion);

/**
 Contains App Link metadata relevant for navigation on this device
 derived from the HTML at a given URL.
 */
NS_SWIFT_NAME(AppLink)
@interface FBSDKAppLink : NSObject

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

/**
 Creates a FBSDKAppLink with the given list of FBSDKAppLinkTargets and target URL.

 Generally, this will only be used by implementers of the FBSDKAppLinkResolving protocol,
 as these implementers will produce App Link metadata for a given URL.

 @param sourceURL the URL from which this App Link is derived
 @param targets an ordered list of FBSDKAppLinkTargets for this platform derived
 from App Link metadata.
 @param webURL the fallback web URL, if any, for the app link.
 */
// UNCRUSTIFY_FORMAT_OFF
+ (instancetype)appLinkWithSourceURL:(nullable NSURL *)sourceURL
                             targets:(NSArray<FBSDKAppLinkTarget *> *)targets
                              webURL:(nullable NSURL *)webURL
NS_SWIFT_NAME(init(sourceURL:targets:webURL:));
// UNCRUSTIFY_FORMAT_ON

/// The URL from which this FBSDKAppLink was derived
@property (nullable, nonatomic, readonly, strong) NSURL *sourceURL;

/**
 The ordered list of targets applicable to this platform that will be used
 for navigation.
 */
@property (nonatomic, readonly, copy) NSArray<id<FBSDKAppLinkTarget>> *targets;

/// The fallback web URL to use if no targets are installed on this device.
@property (nullable, nonatomic, readonly, strong) NSURL *webURL;

@end

NS_ASSUME_NONNULL_END

#endif
