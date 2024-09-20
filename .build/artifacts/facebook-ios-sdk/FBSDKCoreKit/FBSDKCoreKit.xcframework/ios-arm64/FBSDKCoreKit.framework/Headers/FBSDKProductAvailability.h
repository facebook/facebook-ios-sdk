/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

/**
 NS_ENUM(NSUInteger, FBSDKProductAvailability)
    Specifies product availability for Product Catalog product item update
 */
typedef NS_ENUM(NSUInteger, FBSDKProductAvailability) {
  /// Item ships immediately
  FBSDKProductAvailabilityInStock = 0,
  /// No plan to restock
  FBSDKProductAvailabilityOutOfStock,
  /// Available in future
  FBSDKProductAvailabilityPreOrder,
  /// Ships in 1-2 weeks
  FBSDKProductAvailabilityAvailableForOrder,
  /// Discontinued
  FBSDKProductAvailabilityDiscontinued,
} NS_SWIFT_NAME(AppEvents.ProductAvailability);
