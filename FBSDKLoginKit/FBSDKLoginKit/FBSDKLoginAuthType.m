/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "FBSDKLoginAuthType.h"

#if !TARGET_OS_TV

FBSDKLoginAuthType FBSDKLoginAuthTypeRerequest = @"rerequest";
FBSDKLoginAuthType FBSDKLoginAuthTypeReauthorize = @"reauthorize";

#endif
