/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

/**
 NS_ENUM(NSUInteger, FBSDKProductCondition)
 Specifies product condition for Product Catalog product item update
 */
typedef NS_ENUM(NSUInteger, FBSDKProductCondition) {
  FBSDKProductConditionNew = 0,
  FBSDKProductConditionRefurbished,
  FBSDKProductConditionUsed,
} NS_SWIFT_NAME(AppEvents.ProductCondition);
