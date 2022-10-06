/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !TARGET_OS_TV

#import <FBSDKCoreKit/UIPasteboard+Pasteboard.h>

#import <UIKit/UIKit.h>

FB_LINK_CATEGORY_IMPLEMENTATION(UIPasteboard, FBSDKPasteboard)
@implementation UIPasteboard (FBSDKPasteboard)

- (BOOL)_isGeneralPasteboard
{
  return UIPasteboardNameGeneral == self.name;
}

@end

#endif
