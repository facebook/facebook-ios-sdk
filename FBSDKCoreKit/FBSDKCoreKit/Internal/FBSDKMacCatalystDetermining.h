/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

// Describes any type that can determine if the current app is mac catalyst
NS_SWIFT_NAME(MacCatalystDetermining)

@protocol FBSDKMacCatalystDetermining <NSObject>

@property (readonly, getter = isMacCatalystApp) BOOL macCatalystApp;

@end

NS_ASSUME_NONNULL_END
