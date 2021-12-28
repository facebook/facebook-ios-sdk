/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// An internal protocol used to describe anything that can return an advertiser ID string
NS_SWIFT_NAME(AdvertiserIDProviding)
@protocol FBSDKAdvertiserIDProviding

@property (nullable, nonatomic, readonly, copy) NSString *advertiserID;

@end

NS_ASSUME_NONNULL_END
