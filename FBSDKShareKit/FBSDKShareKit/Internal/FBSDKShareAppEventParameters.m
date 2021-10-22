/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "FBSDKShareAppEventParameters.h"

NSString *const FBSDKAppEventParameterDialogErrorMessage = @"fb_dialog_outcome_error_message";
NSString *const FBSDKAppEventParameterDialogOutcome = @"fb_dialog_outcome";
NSString *const FBSDKAppEventParameterDialogShareContentType = @"fb_dialog_share_content_type";
NSString *const FBSDKAppEventParameterDialogMode = @"fb_dialog_mode";
NSString *const FBSDKAppEventsDialogOutcomeValue_Cancelled = @"Cancelled";
NSString *const FBSDKAppEventsDialogOutcomeValue_Completed = @"Completed";
NSString *const FBSDKAppEventsDialogOutcomeValue_Failed = @"Failed";

NSString *const FBSDKAppEventsDialogShareContentTypeStatus = @"Status";
NSString *const FBSDKAppEventsDialogShareContentTypePhoto = @"Photo";
NSString *const FBSDKAppEventsDialogShareContentTypeVideo = @"Video";
NSString *const FBSDKAppEventsDialogShareContentTypeCamera = @"Camera";
NSString *const FBSDKAppEventsDialogShareContentTypeUnknown = @"Unknown";
