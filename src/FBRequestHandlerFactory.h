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

// Internal only factory class to curry FBRequestHandlers to provide various
// error handling behaviors. See `FBRequestConnection.errorBehavior`
// and `FBRequestConnectionRetryManager` for details.

// Essentially this currying approach offers the flexibility of chaining work internally while
// maintaining the existing surface area of request handlers. In the future this could easily
// be replaced by an actual Promises/Deferred framework (or even provide a responder object param
// to the FBRequestHandler callback for even more extensibility)
@interface FBRequestHandlerFactory : NSObject

+(FBRequestHandler) handlerThatRetries:(FBRequestHandler )handler forRequest:(FBRequest* )request;
+(FBRequestHandler) handlerThatReconnects:(FBRequestHandler )handler forRequest:(FBRequest* )request;
+(FBRequestHandler) handlerThatAlertsUser:(FBRequestHandler )handler forRequest:(FBRequest* )request;

@end
