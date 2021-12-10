/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !TARGET_OS_TV

#import <UIKit/UIKit.h>

@interface UIPasteboard (FBSDKPasteboard) <FBSDKPasteboard>
@end

@implementation UIPasteboard (FBSDKPasteboard)

- (BOOL)_isGeneralPasteboard
{
  return UIPasteboardNameGeneral == self.name;
}

NS_ASSUME_NONNULL_BEGIN

@end

NS_ASSUME_NONNULL_END

#endif
