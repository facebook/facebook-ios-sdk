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

#import "FBRequestConnection.h"

// Defines the maximum number of retries for the FBRequestConnectionErrorBehaviorRetry.
extern const int FBREQUEST_DEFAULT_MAX_RETRY_LIMIT;

// Internal only class to facilitate FBRequest processing, specifically
// associating FBRequest and FBRequestHandler instances and necessary
// data for retry processing.
@interface FBRequestMetadata : NSObject

@property (nonatomic, retain) FBRequest *request;
@property (nonatomic, copy) FBRequestHandler completionHandler;
@property (nonatomic, copy) NSDictionary *batchParameters;
@property (nonatomic, assign) FBRequestConnectionErrorBehavior behavior;
@property (nonatomic, copy) FBRequestHandler originalCompletionHandler;

@property (nonatomic, assign) int retryCount;
@property (nonatomic, retain) id originalResult;
@property (nonatomic, retain) NSError* originalError;

- (id) initWithRequest:(FBRequest *)request
     completionHandler:(FBRequestHandler)handler
       batchParameters:(NSDictionary *)batchParameters
              behavior:(FBRequestConnectionErrorBehavior) behavior;

- (void)invokeCompletionHandlerForConnection:(FBRequestConnection *)connection
                                 withResults:(id)results
                                       error:(NSError *)error;
@end
