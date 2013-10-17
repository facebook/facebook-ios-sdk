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

#import "FBRequestMetadata.h"

#import "FBRequest+Internal.h"
#import "FBRequestHandlerFactory.h"

const int FBREQUEST_DEFAULT_MAX_RETRY_LIMIT = 1;

@implementation FBRequestMetadata

- (id) initWithRequest:(FBRequest *)request
     completionHandler:(FBRequestHandler)handler
       batchParameters:(NSDictionary *)batchParameters
              behavior:(FBRequestConnectionErrorBehavior) behavior {

    if ((self = [super init])) {
        _request = [request retain];
        _originalCompletionHandler = [handler copy];
        _batchParameters = [batchParameters copy];
        _behavior = behavior;

        // Only consider retry handlers if the request has enabled canCloseSessionOnError.
        // We are essentially reusing that flag to identify implicit requests, and we
        // don't want implicit requests to trigger retries.
        if (request.canCloseSessionOnError) {
            // Note the order of composing these retry handlers is significant and
            // is like a stack (last wrapping handler is invoked first).
            if (behavior & FBRequestConnectionErrorBehaviorReconnectSession) {
                handler = [FBRequestHandlerFactory handlerThatReconnects:handler forRequest:request];
            }
            if (behavior & FBRequestConnectionErrorBehaviorAlertUser) {
                handler = [FBRequestHandlerFactory handlerThatAlertsUser:handler forRequest:request];
            }
            if (behavior & FBRequestConnectionErrorBehaviorRetry) {
                handler = [FBRequestHandlerFactory handlerThatRetries:handler forRequest:request];
            }
        }


        self.completionHandler = handler;
    }
    return self;
}

- (void) dealloc {
    [_request release];
    [_completionHandler release];
    [_batchParameters release];
    [_originalCompletionHandler release];
    [_originalResult release];
    [_originalError release];

    [super dealloc];
}

- (void)invokeCompletionHandlerForConnection:(FBRequestConnection *)connection
                                 withResults:(id)results
                                       error:(NSError *)error {
    if (self.completionHandler) {
        self.completionHandler(connection, results, error);
    }
}

- (NSString*)description {
    return [NSString stringWithFormat:@"<%@: %p, batchParameters: %@, completionHandler: %p, request: %@>",
            NSStringFromClass([self class]),
            self,
            self.batchParameters,
            self.completionHandler,
            self.request.description];
}

@end
