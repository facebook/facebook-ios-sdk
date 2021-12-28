/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <FBSDKCoreKit/FBSDKCoreKit.h>

// MARK: - Device Requests

FOUNDATION_EXPORT FBSDKAppEventName const FBSDKAppEventNameFBSDKSmartLoginService;

// MARK: - Login Button

FOUNDATION_EXPORT FBSDKAppEventName const FBSDKAppEventNameFBSDKLoginButtonDidTap;

// MARK: - Referral Manager

/** Use to log the start of a referral request */
FOUNDATION_EXPORT FBSDKAppEventName const FBSDKAppEventNameFBReferralStart;

/** Use to log the end of a referral request */
FOUNDATION_EXPORT FBSDKAppEventName const FBSDKAppEventNameFBReferralEnd;

// MARK: - Login Manager

/** Use to log the result of the App Switch OS AlertView. Only available on OS >= iOS10 */
FOUNDATION_EXPORT FBSDKAppEventName const FBSDKAppEventNameFBSessionFASLoginDialogResult;

/** Use to log the start of an auth request that cannot be fulfilled by the token cache */
FOUNDATION_EXPORT FBSDKAppEventName const FBSDKAppEventNameFBSessionAuthStart;

/** Use to log the end of an auth request that was not fulfilled by the token cache */
FOUNDATION_EXPORT FBSDKAppEventName const FBSDKAppEventNameFBSessionAuthEnd;

/** Use to log the start of a specific auth method as part of an auth request */
FOUNDATION_EXPORT FBSDKAppEventName const FBSDKAppEventNameFBSessionAuthMethodStart;

/** Use to log the end of the last tried auth method as part of an auth request */
FOUNDATION_EXPORT FBSDKAppEventName const FBSDKAppEventNameFBSessionAuthMethodEnd;

/** Use to log the post-login heartbeat event after  the end of an auth request*/
FOUNDATION_EXPORT FBSDKAppEventName const FBSDKAppEventNameFBSessionAuthHeartbeat;
