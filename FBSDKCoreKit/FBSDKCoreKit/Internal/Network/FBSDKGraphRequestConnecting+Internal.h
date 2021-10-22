/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <FBSDKCoreKit/FBSDKGraphRequestConnecting.h>

#import "FBSDKGraphRequestMetadata.h"

NS_ASSUME_NONNULL_BEGIN

@protocol _FBSDKGraphRequestConnecting <FBSDKGraphRequestConnecting>

@property (nonatomic, readonly) NSMutableArray<FBSDKGraphRequestMetadata *> *requests;

@end

NS_ASSUME_NONNULL_END
