/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "FBSDKShareDialogMode.h"

NSString *const FBSDKAppEventsDialogShareModeAutomatic = @"Automatic";
NSString *const FBSDKAppEventsDialogShareModeBrowser = @"Browser";
NSString *const FBSDKAppEventsDialogShareModeNative = @"Native";
NSString *const FBSDKAppEventsDialogShareModeShareSheet = @"ShareSheet";
NSString *const FBSDKAppEventsDialogShareModeWeb = @"Web";
NSString *const FBSDKAppEventsDialogShareModeFeedBrowser = @"FeedBrowser";
NSString *const FBSDKAppEventsDialogShareModeFeedWeb = @"FeedWeb";
NSString *const FBSDKAppEventsDialogShareModeUnknown = @"Unknown";

NSString *NSStringFromFBSDKShareDialogMode(FBSDKShareDialogMode dialogMode)
{
  switch (dialogMode) {
    case FBSDKShareDialogModeAutomatic: {
      return FBSDKAppEventsDialogShareModeAutomatic;
    }
    case FBSDKShareDialogModeBrowser: {
      return FBSDKAppEventsDialogShareModeBrowser;
    }
    case FBSDKShareDialogModeNative: {
      return FBSDKAppEventsDialogShareModeNative;
    }
    case FBSDKShareDialogModeShareSheet: {
      return FBSDKAppEventsDialogShareModeShareSheet;
    }
    case FBSDKShareDialogModeWeb: {
      return FBSDKAppEventsDialogShareModeWeb;
    }
    case FBSDKShareDialogModeFeedBrowser: {
      return FBSDKAppEventsDialogShareModeFeedBrowser;
    }
    case FBSDKShareDialogModeFeedWeb: {
      return FBSDKAppEventsDialogShareModeFeedWeb;
    }
    default: {
      return FBSDKAppEventsDialogShareModeUnknown;
    }
  }
}
