/*
 * Copyright 2010-present Facebook.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#import "FBError.h"

NSString *const FacebookSDKDomain = @"com.facebook.sdk";
NSString *const FacebookNativeApplicationDomain = @"com.facebook.Facebook.platform";

NSString *const FBErrorInnerErrorKey = @"com.facebook.sdk:ErrorInnerErrorKey";
NSString *const FBErrorParsedJSONResponseKey = @"com.facebook.sdk:ParsedJSONResponseKey";
NSString *const FBErrorHTTPStatusCodeKey = @"com.facebook.sdk:HTTPStatusCode";
NSString *const FBErrorSessionKey = @"com.facebook.sdk:ErrorSessionKey";
NSString *const FBErrorUnprocessedURLKey = @"com.facebook.sdk:UnprocessedURLKey";

NSString *const FBErrorLoginFailedReason = @"com.facebook.sdk:ErrorLoginFailedReason";
NSString *const FBErrorLoginFailedOriginalErrorCode = @"com.facebook.sdk:ErrorLoginFailedOriginalErrorCode";

NSString *const FBErrorLoginFailedReasonInlineCancelledValue = @"com.facebook.sdk:InlineLoginCancelled";
NSString *const FBErrorLoginFailedReasonInlineNotCancelledValue = @"com.facebook.sdk:ErrorLoginNotCancelled";
NSString *const FBErrorLoginFailedReasonUserCancelledValue = @"com.facebook.sdk:UserLoginCancelled";
NSString *const FBErrorLoginFailedReasonUserCancelledSystemValue = @"com.facebook.sdk:SystemLoginCancelled";
NSString *const FBErrorLoginFailedReasonOtherError = @"com.facebook.sdk:UserLoginOtherError";
NSString *const FBErrorLoginFailedReasonSystemDisallowedWithoutErrorValue = @"com.facebook.sdk:SystemLoginDisallowedWithoutError";
NSString *const FBErrorLoginFailedReasonSystemError = @"com.facebook.sdk:SystemLoginError";

NSString *const FBErrorReauthorizeFailedReasonSessionClosed = @"com.facebook.sdk:ErrorReauthorizeFailedReasonSessionClosed";
NSString *const FBErrorReauthorizeFailedReasonUserCancelled = @"com.facebook.sdk:ErrorReauthorizeFailedReasonUserCancelled";
NSString *const FBErrorReauthorizeFailedReasonUserCancelledSystem = @"com.facebook.sdk:ErrorReauthorizeFailedReasonUserCancelledSystem";
NSString *const FBErrorReauthorizeFailedReasonWrongUser = @"com.facebook.sdk:ErrorReauthorizeFailedReasonWrongUser";

NSString *const FBInvalidOperationException = @"com.facebook.sdk:InvalidOperationException";

NSString *const FBErrorDialogReasonKey = @"com.facebook.sdk:DialogReasonKey";
NSString *const FBErrorDialogNotSupported = @"com.facebook.sdk:DialogNotSupported";
NSString *const FBErrorDialogInvalidForSession = @"DialogInvalidForSession";
NSString *const FBErrorDialogCantBeDisplayed = @"DialogCantBeDisplayed";
NSString *const FBErrorDialogInvalidOpenGraphObject = @"DialogInvalidOpenGraphObject";
NSString *const FBErrorDialogInvalidOpenGraphActionParameters = @"DialogInvalidOpenGraphActionParameters";
NSString *const FBErrorDialogInvalidShareParameters = @"DialogInvalidShareParameters";
NSString *const FBErrorDialogInvalidLikeObjectID = @"DialogInvalidLikeObjectID";

NSString *const FBErrorAppEventsReasonKey = @"com.facebook.sdk:AppEventsReasonKey";
