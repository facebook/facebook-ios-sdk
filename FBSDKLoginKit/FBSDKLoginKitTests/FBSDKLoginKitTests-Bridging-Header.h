/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <FBSDKLoginKit/FBSDKLoginKit.h>

#ifdef BUCK
 #import <FBSDKLoginKit+Internal/FBSDKAuthenticationTokenCreating.h>
 #import <FBSDKLoginKit+Internal/FBSDKAuthenticationTokenFactory.h>
 #import <FBSDKLoginKit+Internal/FBSDKAuthenticationTokenHeader.h>
 #import <FBSDKLoginKit+Internal/FBSDKDevicePoller.h>
 #import <FBSDKLoginKit+Internal/FBSDKDevicePolling.h>
 #import <FBSDKLoginKit+Internal/FBSDKLoginCompletion+Internal.h>
 #import <FBSDKLoginKit+Internal/FBSDKLoginProviding.h>
 #import <FBSDKLoginKit+Internal/FBSDKNonceUtility.h>
 #import <FBSDKLoginKit+Internal/FBSDKPermission.h>
 #import <FBSDKLoginKit+Internal/FBSDKProfileFactory.h>
#else
 #import "FBSDKAuthenticationTokenCreating.h"
 #import "FBSDKAuthenticationTokenFactory.h"
 #import "FBSDKAuthenticationTokenHeader.h"
 #import "FBSDKDevicePoller.h"
 #import "FBSDKDevicePolling.h"
 #import "FBSDKLoginCompletion+Internal.h"
 #import "FBSDKLoginProviding.h"
 #import "FBSDKNonceUtility.h"
 #import "FBSDKPermission.h"
 #import "FBSDKProfileFactory.h"
#endif

#import "FBSDKAccessToken+Testing.h"
#import "FBSDKAppEvents+Testing.h"
#import "FBSDKDeviceLoginCodeInfo+Testing.h"
#import "FBSDKDeviceLoginManager+Testing.h"
#import "FBSDKDeviceLoginManagerResult+Testing.h"
#import "FBSDKInternalUtility+Testing.h"
#import "FBSDKLoginButton+Testing.h"
#import "FBSDKLoginManager+Testing.h"
#import "FBSDKProfile+Testing.h"
#import "FBSDKSettings+Testing.h"
