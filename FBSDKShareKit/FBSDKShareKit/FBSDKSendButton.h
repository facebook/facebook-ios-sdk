/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !TARGET_OS_TV

#import <UIKit/UIKit.h>

#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <FBSDKShareKit/FBSDKShareConstants.h>
#import <FBSDKShareKit/FBSDKSharingButton.h>

NS_ASSUME_NONNULL_BEGIN

/**
  A button to send content through Messenger.

 Tapping the receiver will invoke the FBSDKShareDialog with the attached shareContent.  If the dialog cannot
 be shown, the button will be disable.
 */
NS_SWIFT_NAME(FBSendButton)
@interface FBSDKSendButton : FBSDKButton <FBSDKSharingButton>

@end

NS_ASSUME_NONNULL_END

#endif
