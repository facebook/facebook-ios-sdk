/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <FBSDKLoginKit/FBSDKLoginKit.h>

#import "FBSDKAuthenticationTokenClaims+Testing.h"
#import "FBSDKAuthenticationTokenCreating.h"
#import "FBSDKAuthenticationTokenFactory.h"
#import "FBSDKAuthenticationTokenFactory+Testing.h"
#import "FBSDKAuthenticationTokenHeader.h"
#import "FBSDKAuthenticationTokenHeader+Testing.h"
#import "FBSDKCodeVerifier.h"
#import "FBSDKDeviceLoginCodeInfo+Testing.h"
#import "FBSDKDevicePoller.h"
#import "FBSDKDevicePolling.h"
#import "FBSDKLoginCompleterFactory.h"
#import "FBSDKLoginCompletionParameters+Internal.h"
#import "FBSDKLoginErrorFactory.h"
#import "FBSDKLoginManagerLogger.h"
#import "FBSDKLoginProviding.h"
#import "FBSDKLoginRecoveryAttempter.h"
#import "FBSDKLoginURLCompleter+Testing.h"
#import "FBSDKProfileFactory.h"

// +Testing.h files
#import "FBSDKAccessToken+Testing.h"
#import "FBSDKDeviceLoginCodeInfo+Testing.h"
#import "FBSDKDeviceLoginManager+Testing.h"
#import "FBSDKDeviceLoginManagerResult+Testing.h"
#import "FBSDKDeviceRequestsHelper+Testing.h"
#import "FBSDKInternalUtility+Testing.h"
#import "FBSDKLoginManager+Testing.h"
#import "FBSDKLoginTooltipView+Testing.h"
#import "FBSDKProfile+Testing.h"
#import "FBSDKSettings+Testing.h"
#import "FBSDKTooltipView+Testing.h"
