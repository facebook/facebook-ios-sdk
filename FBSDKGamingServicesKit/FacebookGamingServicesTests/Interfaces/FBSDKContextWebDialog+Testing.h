/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@import FacebookGamingServices;

NS_ASSUME_NONNULL_BEGIN
@interface FBSDKContextWebDialog (Testing)

// UNCRUSTIFY_FORMAT_OFF
- (instancetype)initWithDelegate:(id<FBSDKContextDialogDelegate>)delegate
NS_SWIFT_NAME(init(delegate:));
// UNCRUSTIFY_FORMAT_ON

@end
NS_ASSUME_NONNULL_END
