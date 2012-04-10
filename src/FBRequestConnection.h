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

#import <Foundation/Foundation.h>

// up-front decl's
@class FBRequest;
@class FBRequestConnection;
enum FBRequestConnectionState;

typedef void (^FBRequestHandler)(FBRequestConnection *connection, 
                                 id result,
                                 NSError *error);

// FBRequestConnection class
//
// Summary:
// Represents a single connection to Facebook to service a request. The logical
// request settings are encapsulated in a reusable FBRequest object, and 
// FBRequestConnection encapsulates the concerns of a single communication
// (e.g. starting and canceling a connection, batching.)
//
@interface FBRequestConnection : NSObject

// creating a request

// init
//
// Summary:
// FBRequestConnection objects are used to issue one or more requests as a
// single request/response connection with Facebook. For a single request, the
// usual method for creating an FBRequestConnection object is to call one of
// the start* methods on FBRequest. However, it is allowable to init an
// FBRequestConnection object directly, and call addRequest to add one or more
// request objects to the connection, before calling start.
//     
- (id)init;
- (id)initWithTimeout:(NSTimeInterval)timeout;

// properties
//
@property(nonatomic, retain, readwrite) NSMutableURLRequest *urlRequest;
@property(nonatomic, retain, readonly) NSHTTPURLResponse *urlResponse; 

// instance methods

// addRequest
//
// Summary:
// Add a request to the connection, prior to calling start.
//
// Behavior notes:
// The block passed to addRequest is retained until the block is called upon
// completion or cancellation of the connection.
- (void)addRequest:(FBRequest*)request
 completionHandler:(FBRequestHandler)handler;

- (void)addRequest:(FBRequest*)request
 completionHandler:(FBRequestHandler)handler
    batchEntryName:(NSString*)name;

// start
//
// Summary:
// Starts a connection with the server, capable of handling all of the requests
// added to the connection.
// Returns itself to allow for chained calls.
//
// Behavior notes:
// Errors are reported via the handler callback, even in cases where no 
// communication is attempted by the implementation of FBRequestConnection. In 
// such cases multiple error conditions may apply, and if so the following
// priority (highest to lowest) is used.
//   FBRequestConnectionInvalidRequestKey -- when an FBRequest is unable to be 
//                                           encoded for transmission
//   FBRequestConnectionInvalidBatchKey   -- when any request in the connection 
//                                           cannot be encoded for transmission
//                                           with the batch, all requests fail
//   
// Start is idempotent, and if no requests are associated with an
// FBRequestConnection object, the method nominally succeeds.
//
- (FBRequestConnection*)start;

// cancel
//
// Summary:
// Signals that a connection should be logically terminated, meaning the
// application is no longer interested in a response.
//
// Behavior notes:
// Synchronously calls any handlers indicating the request was cancelled. Cancel
// does not guarantee that request related processing will cease, however it 
// does promise that  all handlers complete before cancel returns. A call to
// cancel prior to start, implies start/cancellation of all requests associated
// with the connection.
//
- (void)cancel;

@end
