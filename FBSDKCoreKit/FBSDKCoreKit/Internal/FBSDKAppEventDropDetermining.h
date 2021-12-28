/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// An internal protocol used to describe anything that can determine if all app events should be dropped
NS_SWIFT_NAME(AppEventDropDetermining)
@protocol FBSDKAppEventDropDetermining

@property (nonatomic, readonly) BOOL shouldDropAppEvents;

@end

NS_ASSUME_NONNULL_END
