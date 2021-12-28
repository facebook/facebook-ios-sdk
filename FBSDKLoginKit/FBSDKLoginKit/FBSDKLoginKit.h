/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <FBSDKLoginKit/FBSDKDeviceLoginCodeInfo.h>
#import <FBSDKLoginKit/FBSDKDeviceLoginManager.h>
#import <FBSDKLoginKit/FBSDKDeviceLoginManagerDelegate.h>
#import <FBSDKLoginKit/FBSDKDeviceLoginManagerResult.h>
#import <FBSDKLoginKit/FBSDKLoginConstants.h>

#import <UIKit/UIKit.h>

#import <FBSDKCoreKit/FBSDKCoreKit.h>

#if !TARGET_OS_TV
 #import <FBSDKLoginKit/FBSDKLoginButton.h>
 #import <FBSDKLoginKit/FBSDKLoginButtonDelegate.h>
 #import <FBSDKLoginKit/FBSDKLoginConfiguration.h>
 #import <FBSDKLoginKit/FBSDKLoginManager.h>
 #import <FBSDKLoginKit/FBSDKLoginManagerLoginResult.h>
 #import <FBSDKLoginKit/FBSDKLoginTooltipView.h>
 #import <FBSDKLoginKit/FBSDKLoginTooltipViewDelegate.h>
 #import <FBSDKLoginKit/FBSDKReferralManager.h>
 #import <FBSDKLoginKit/FBSDKReferralManagerResult.h>
#endif
