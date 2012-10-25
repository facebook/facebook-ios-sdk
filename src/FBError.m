/*
 * Copyright 2012 Facebook
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#import "FBError.h"

NSString *const FacebookSDKDomain = @"com.facebook.sdk";
NSString *const FBErrorInnerErrorKey = @"com.facebook.sdk:ErrorInnerErrorKey";
NSString *const FBErrorParsedJSONResponseKey = @"com.facebook.sdk:ParsedJSONResponseKey";
NSString *const FBErrorHTTPStatusCodeKey = @"com.facebook.sdk:HTTPStatusCode";

NSString *const FBErrorLoginFailedReason = @"com.facebook.sdk:ErrorLoginFailedReason";
NSString *const FBErrorLoginFailedOriginalErrorCode = @"com.facebook.sdk:ErrorLoginFailedOriginalErrorCode";

NSString *const FBErrorReauthorizeFailedReasonSessionClosed = @"com.facebook.sdk:ErrorReauthorizeFailedReasonSessionClosed";
NSString *const FBErrorReauthorizeFailedReasonUserCancelled = @"com.facebook.sdk:ErrorReauthorizeFailedReasonUserCancelled";
NSString *const FBErrorReauthorizeFailedReasonWrongUser = @"com.facebook.sdk:ErrorReauthorizeFailedReasonWrongUser";

NSString *const FBInvalidOperationException = @"com.facebook.sdk:InvalidOperationException";

NSString *const FBErrorNativeDialogReasonKey = @"com.facebook.sdk:NativeDialogReasonKey";
NSString *const FBErrorNativeDialogNotSupported = @"com.facebook.sdk:NativeDialogNotSupported";
NSString *const FBErrorNativeDialogInvalidForSession = @"NativeDialogInvalidForSession";
NSString *const FBErrorNativeDialogCantBeDisplayed = @"NativeDialogCantBeDisplayed";
