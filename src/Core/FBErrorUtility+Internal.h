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
#import "FBErrorUtility.h"
#import "FBSDKMacros.h"

typedef enum {
    FBAuthSubcodeNone = 0,
    FBAuthSubcodeAppNotInstalled = 458,
    FBAuthSubcodeUserCheckpointed = 459,
    FBAuthSubcodePasswordChanged = 460,
    FBAuthSubcodeExpired = 463,
    FBAuthSubcodeUnconfirmedUser = 464,
} FBAuthSubcode;

FBSDK_EXTERN const int FBOAuthError;

// Internal class collecting error related methods.

@interface FBErrorUtility (Internal)

+ (FBErrorCategory)fberrorCategoryFromError:(NSError *)error
                                       code:(int)code
                                   subcode:(int)subcode
                      returningUserMessage:(NSString **)puserMessage
                       andShouldNotifyUser:(BOOL *)pshouldNotifyUser;

+ (void)fberrorGetCodeValueForError:(NSError *)error
                              index:(NSUInteger)index
                               code:(int *)pcode
                            subcode:(int *)psubcode;

+ (NSError *)fberrorForSystemPasswordChange:(NSError *)innerError;

+ (NSError *)fberrorForRetry:(NSError *)innerError;

+ (NSDictionary *)jsonDictionaryForError:(NSError *)error;

+ (BOOL)errorIsNetworkError:(NSError *)error;

@end
