/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <Foundation/Foundation.h>

#import <FBSDKCoreKit_Basics/FBSDKDataPersisting.h>

NS_ASSUME_NONNULL_BEGIN

/// Default conformance to the data persisting protocol
@interface NSUserDefaults (DataPersisting) <FBSDKDataPersisting>
@end

NS_ASSUME_NONNULL_END
