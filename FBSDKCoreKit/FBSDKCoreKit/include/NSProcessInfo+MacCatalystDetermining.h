/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <FBSDKCoreKit/FBSDKMacCatalystDetermining.h>
#import <FBSDKCoreKit_Basics/FBSDKCoreKit_Basics.h>
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 Internal conformance exposed to facilitate transition to Swift.
 API Subject to change or removal without warning. Do not use.

 @warning INTERNAL - DO NOT USE
 */
FB_LINK_CATEGORY_INTERFACE(NSProcessInfo, MacCatalystDetermining)
@interface NSProcessInfo (MacCatalystDetermining) <FBSDKMacCatalystDetermining>

@end

NS_ASSUME_NONNULL_END
