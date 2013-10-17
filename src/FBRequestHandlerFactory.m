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


#import "FBRequestHandlerFactory.h"

#import <UIKit/UIKit.h>

#import "FBAccessTokenData.h"
#import "FBError.h"
#import "FBErrorUtility+Internal.h"
#import "FBRequest+Internal.h"
#import "FBRequestConnection+Internal.h"
#import "FBRequestConnectionRetryManager.h"
#import "FBRequestMetadata.h"
#import "FBSession+Internal.h"
#import "FBSystemAccountStoreAdapter.h"

@implementation FBRequestHandlerFactory

// These handlers should generally conform to the following pattern:
// 1. Save any original errors/results to the metadata.
// 2. Check the retryManager.state to determine if retry behavior should be aborted.
// 3. Invoking the original handler if the retry condition is not met.
// We (ab)use the retryManager to maintain any necessary state between handlers
//  (such as an optional user facing alert message).
+(FBRequestHandler) handlerThatRetries:(FBRequestHandler )handler forRequest:(FBRequest* )request {
    return [[^(FBRequestConnection *connection,
               id result,
               NSError *error){
        FBRequestMetadata *metadata = [connection getRequestMetadata:request];
        metadata.originalError = metadata.originalError ?: error;
        metadata.originalResult = metadata.originalResult ?: result;

        if (connection.retryManager.state != FBRequestConnectionRetryManagerStateAbortRetries
            && error
            && [FBErrorUtility errorCategoryForError:error] == FBErrorCategoryRetry) {

            if (metadata.retryCount < FBREQUEST_DEFAULT_MAX_RETRY_LIMIT) {
                metadata.retryCount++;
                [connection.retryManager addRequestMetadata:metadata];
                return;
            }
        }

        // Otherwise, invoke the supplied handler
        if (handler){
            handler(connection, result, error);
        }
    } copy] autorelease];
}

+(FBRequestHandler) handlerThatAlertsUser:(FBRequestHandler )handler forRequest:(FBRequest* )request {
    return [[^(FBRequestConnection *connection,
               id result,
               NSError *error){
        FBRequestMetadata *metadata = [connection getRequestMetadata:request];
        metadata.originalError = metadata.originalError ?: error;
        metadata.originalResult = metadata.originalResult ?: result;
        NSString *message = [FBErrorUtility userMessageForError:error];
        if (connection.retryManager.state != FBRequestConnectionRetryManagerStateAbortRetries
            && message.length > 0) {

            connection.retryManager.alertMessage = message;
        }

        // In this case, always invoke the handler.
        if (handler) {
            handler(connection, result, error);
        }

    } copy] autorelease];
}

+(FBRequestHandler) handlerThatReconnects:(FBRequestHandler )handler forRequest:(FBRequest* )request {
    // Defer closing of sessions for these kinds of requests.
    request.canCloseSessionOnError = NO;
    return [[^(FBRequestConnection *connection,
               id result,
               NSError *error){
        FBRequestMetadata *metadata = [connection getRequestMetadata:request];
        metadata.originalError = metadata.originalError ?: error;
        metadata.originalResult = metadata.originalResult ?: result;

        FBErrorCategory errorCategory = error ? [FBErrorUtility errorCategoryForError:error] : FBErrorCategoryInvalid;
        if (connection.retryManager.state != FBRequestConnectionRetryManagerStateAbortRetries
            && error
            && errorCategory  == FBErrorCategoryAuthenticationReopenSession){
            int code, subcode;
            [FBErrorUtility fberrorGetCodeValueForError:error
                                                  index:0
                                                   code:&code
                                                subcode:&subcode];

            // If the session has already been closed, we cannot repair.
            BOOL canRepair = request.session.isOpen;
            switch (subcode) {
                case FBAuthSubcodeAppNotInstalled :
                case FBAuthSubcodeUnconfirmedUser : canRepair = NO; break;
            }

            if (canRepair) {
                if (connection.retryManager.sessionToReconnect == nil) {
                    connection.retryManager.sessionToReconnect = request.session;
                }

                if (request.session.accessTokenData.loginType == FBSessionLoginTypeSystemAccount) {
                    // For iOS 6, we also cannot reconnect disabled app sliders.
                    // This has the side effect of not repairing sessions on a device
                    // that has since removed the Facebook device account since we cannot distinguish
                    // between a disabled slider versus no account set up (in the former, we do not
                    // want to attempt FB App/Safari SSO).
                    canRepair = [FBSystemAccountStoreAdapter sharedInstance].canRequestAccessWithoutUI;
                }

                if (canRepair) {
                    if (connection.retryManager.sessionToReconnect == nil) {
                        connection.retryManager.sessionToReconnect = request.session;
                    }

                    // Only support reconnecting one session instance for a give request connection.
                    if (connection.retryManager.sessionToReconnect == request.session) {

                        connection.retryManager.sessionToReconnect = request.session;
                        [connection.retryManager addRequestMetadata:metadata];

                        connection.retryManager.state = FBRequestConnectionRetryManagerStateRepairSession;
                        return;
                    }
                }
            }
        }

        // Otherwise, invoke the supplied handler
        if (handler){
            // Since FBRequestConnection typically closes invalid sessions before invoking the supplied handler,
            // we have to manually mimic that behavior here.
            request.canCloseSessionOnError = YES;
            if (errorCategory == FBErrorCategoryAuthenticationReopenSession){
                [request.session closeAndClearTokenInformation:error];
            }

            handler(connection, result, error);
        }

    } copy] autorelease];
}

@end


