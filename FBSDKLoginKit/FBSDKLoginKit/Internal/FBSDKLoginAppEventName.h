// Copyright (c) 2014-present, Facebook, Inc. All rights reserved.
//
// You are hereby granted a non-exclusive, worldwide, royalty-free license to use,
// copy, modify, and distribute this software in source code or binary form for use
// in connection with the web services and APIs provided by Facebook.
//
// As with any software that integrates with the Facebook platform, your use of
// this software is subject to the Facebook Developer Principles and Policies
// [http://developers.facebook.com/policy/]. This copyright notice shall be
// included in all copies or substantial portions of the software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
// FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
// COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
// IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
// CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

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
