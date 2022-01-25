/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "_FBSDKShareAppEventParameters.h"

FBSDKAppEventParameterName const FBSDKAppEventParameterNameDialogErrorMessage = @"fb_dialog_outcome_error_message";
FBSDKAppEventParameterName const FBSDKAppEventParameterNameDialogOutcome = @"fb_dialog_outcome";
FBSDKAppEventParameterName const FBSDKAppEventParameterNameDialogShareContentType = @"fb_dialog_share_content_type";
FBSDKAppEventParameterName const FBSDKAppEventParameterNameDialogMode = @"fb_dialog_mode";
FBSDKAppEventParameterName const FBSDKAppEventParameterNameDialogShareContentPageID = @"fb_dialog_share_content_page_id";
FBSDKAppEventParameterName const FBSDKAppEventParameterNameDialogShareContentUUID = @"fb_dialog_share_content_uuid";

NSString *const FBSDKAppEventsDialogOutcomeValue_Cancelled = @"Cancelled";
NSString *const FBSDKAppEventsDialogOutcomeValue_Completed = @"Completed";
NSString *const FBSDKAppEventsDialogOutcomeValue_Failed = @"Failed";

NSString *const FBSDKAppEventsDialogShareContentTypeStatus = @"Status";
NSString *const FBSDKAppEventsDialogShareContentTypePhoto = @"Photo";
NSString *const FBSDKAppEventsDialogShareContentTypeVideo = @"Video";
NSString *const FBSDKAppEventsDialogShareContentTypeCamera = @"Camera";
NSString *const FBSDKAppEventsDialogShareContentTypeUnknown = @"Unknown";
