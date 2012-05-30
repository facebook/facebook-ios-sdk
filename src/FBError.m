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

NSString *const FBiOSSDKDomain = @"com.facebook.FBiOSSDK";
NSString *const FBErrorInnerErrorKey = @"com.facebook.FBiOSSDK:ErrorInnerErrorKey";
NSString *const FBErrorParsedJSONResponseKey = @"com.facebook.FBiOSSDK:ParsedJSONResponseKey";
NSString *const FBErrorHTTPStatusCodeKey = @"com.facebook.FBiOSSDK:HTTPStatusCode";

NSString *const FBErrorLoginFailedReason = @"com.facebook.FBiOSSDK:ErrorLoginFailedReason";
NSString *const FBErrorLoginFailedOriginalErrorCode = @"com.facebook.FBiOSSDK:ErrorLoginFailedOriginalErrorCode";

NSString *const FBErrorReauthorizeFailedReasonSessionClosed = @"com.facebook.FBiOSSDK:ErrorReauthorizeFailedReasonSessionClosed";
NSString *const FBErrorReauthorizeFailedReasonUserCancelled = @"com.facebook.FBiOSSDK:ErrorReauthorizeFailedReasonUserCancelled";
NSString *const FBErrorReauthorizeFailedReasonWrongUser = @"com.facebook.FBiOSSDK:ErrorReauthorizeFailedReasonWrongUser";

NSString *const FBInvalidOperationException = @"com.facebook.FBiOSSDK:InvalidOperationException";
