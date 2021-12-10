/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 NS_ENUM(NSUInteger, FBSDKShareDialogMode)
  Modes for the FBSDKShareDialog.

 The automatic mode will progressively check the availability of different modes and open the most
 appropriate mode for the dialog that is available.
 */
typedef NS_ENUM(NSUInteger, FBSDKShareDialogMode) {
  /**
    Acts with the most appropriate mode that is available.
   */
  FBSDKShareDialogModeAutomatic = 0,
  /**
   @Displays the dialog in the main native Facebook app.
   */
  FBSDKShareDialogModeNative,
  /**
   @Displays the dialog in the iOS integrated share sheet.
   */
  FBSDKShareDialogModeShareSheet,
  /**
   @Displays the dialog in Safari.
   */
  FBSDKShareDialogModeBrowser,
  /**
   @Displays the dialog in a WKWebView within the app.
   */
  FBSDKShareDialogModeWeb,
  /**
   @Displays the feed dialog in Safari.
   */
  FBSDKShareDialogModeFeedBrowser,
  /**
   @Displays the feed dialog in a WKWebView within the app.
   */
  FBSDKShareDialogModeFeedWeb,
} NS_SWIFT_NAME(ShareDialog.Mode);

/**
  Converts an FBSDKShareDialogMode to an NSString.
 */
FOUNDATION_EXPORT NSString *NSStringFromFBSDKShareDialogMode(FBSDKShareDialogMode dialogMode)
NS_REFINED_FOR_SWIFT;

NS_ASSUME_NONNULL_END
