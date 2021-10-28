/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(AppStoreReceiptProviding)
@protocol FBSDKAppStoreReceiptProviding

@property (nullable, readonly, copy) NSURL *appStoreReceiptURL;

@end

// Default conformance to the AppStoreReceiptProvider protocol
@interface NSBundle () <FBSDKAppStoreReceiptProviding>
@end

NS_ASSUME_NONNULL_END
