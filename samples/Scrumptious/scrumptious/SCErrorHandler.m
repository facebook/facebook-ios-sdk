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

#import "SCErrorHandler.h"

#import <UIKit/UIKit.h>

#import <FacebookSDK/FacebookSDK.h>

void SCHandleError(NSError *error)
{
    if (error != nil) {
        NSString *alertMessage;
        NSString *alertTitle;

        // Facebook SDK * error handling *
        // Error handling is an important part of providing a good user experience.
        // Since this sample uses the FBLoginView, this delegate will respond to
        // login failures, or other failures that have closed the session (such
        // as a token becoming invalid). Please see the [- postOpenGraphAction:]
        // and [- requestPermissionAndPost] on `SCViewController` for further
        // error handling on other operations.
        if ([FBErrorUtility shouldNotifyUserForError:error]) {
            // If the SDK has a message for the user, surface it. This conveniently
            // handles cases like password change or iOS6 app slider state.
            alertTitle = @"Something Went Wrong";
            alertMessage = [FBErrorUtility userMessageForError:error];
        } else {
            switch ([FBErrorUtility errorCategoryForError:error]) {
                case FBErrorCategoryAuthenticationReopenSession:{
                    // It is important to handle session closures as mentioned. You can inspect
                    // the error for more context but this sample generically notifies the user.
                    alertTitle = @"Session Error";
                    alertMessage = @"Your current session is no longer valid. Please log in again.";
                    break;
                }
                case FBErrorCategoryUserCancelled:{
                    // The user has cancelled a login. You can inspect the error
                    // for more context. For this sample, we will simply ignore it.
                    NSLog(@"user cancelled login");
                    break;
                }
                default:{
                    // For simplicity, this sample treats other errors blindly, but you should
                    // refer to https://developers.facebook.com/docs/technical-guides/iossdk/errors/
                    // for more information.
                    alertTitle = @"Unknown Error";
                    alertMessage = @"Error.  Please try again later.";
                    NSLog(@"Unexpected error:%@", error);
                    break;
                }
            }
        }

        if (alertMessage) {
            [[[UIAlertView alloc] initWithTitle:alertTitle
                                        message:alertMessage
                                       delegate:nil
                              cancelButtonTitle:@"OK"
                              otherButtonTitles:nil] show];
        }
    }
}
