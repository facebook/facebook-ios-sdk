/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "FBSDKLoginAppEventName.h"

// MARK: - Device Requests

FBSDKAppEventName const FBSDKAppEventNameFBSDKSmartLoginService = @"fb_smart_login_service";

// MARK: - Login Button

FBSDKAppEventName const FBSDKAppEventNameFBSDKLoginButtonDidTap = @"fb_login_button_did_tap";

// MARK: - Login Manager

/// Use to log the result of the App Switch OS AlertView. Only available on OS >= iOS10
FBSDKAppEventName const FBSDKAppEventNameFBSessionFASLoginDialogResult = @"fb_mobile_login_fas_dialog_result";

/// Use to log the start of an auth request that cannot be fulfilled by the token cache
FBSDKAppEventName const FBSDKAppEventNameFBSessionAuthStart = @"fb_mobile_login_start";

/// Use to log the end of an auth request that was not fulfilled by the token cache
FBSDKAppEventName const FBSDKAppEventNameFBSessionAuthEnd = @"fb_mobile_login_complete";

/// Use to log the start of a specific auth method as part of an auth request
FBSDKAppEventName const FBSDKAppEventNameFBSessionAuthMethodStart = @"fb_mobile_login_method_start";

/// Use to log the end of the last tried auth method as part of an auth request
FBSDKAppEventName const FBSDKAppEventNameFBSessionAuthMethodEnd = @"fb_mobile_login_method_complete";

/// Use to log the post-login heartbeat event after  the end of an auth request
FBSDKAppEventName const FBSDKAppEventNameFBSessionAuthHeartbeat = @"fb_mobile_login_heartbeat";
