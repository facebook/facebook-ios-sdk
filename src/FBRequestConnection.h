/*
 * Copyright 2012 Facebook
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

#import <Foundation/Foundation.h>

// up-front decl's
@class FBRequest;
@class FBRequestConnection;

/*!
 Normally requests return JSON data that is parsed into a set of NSDictionary
 and NSArray objects.

 When a request returns a non-JSON response, that response is packaged in
 a NSDictionary using FBNonJSONResponseProperty as the key and the literal
 response as the value.
*/
extern NSString *const FBNonJSONResponseProperty;

/*!
 @typedef FBRequestHandler

 @abstract
 Passed to addRequest to register for a callback with the results of that
 request once the connection completes.

 @discussion
 Pass one of these when calling addRequest.  This will be called once
 the request completes.  The call occurs on the UI thread.

 @param connection      The FBRequestConnection that sent the request.

 @param result          The result of the request.  This is a translation of
                        JSON data to NSDictionary and NSArray objects.  This
                        is nil if there was an error.

 @param error           The NSError representing any error that occurred.

*/
typedef void (^FBRequestHandler)(FBRequestConnection *connection, 
                                 id result,
                                 NSError *error);

/*!
 @class FBRequestConnection

 @abstract
 Represents a single connection to Facebook to service a request.

 @discussion
 Represents a single connection to Facebook to service a request. The logical
 request settings are encapsulated in a reusable FBRequest object, and 
 FBRequestConnection encapsulates the concerns of a single communication
 e.g. starting and canceling a connection, batching.

 @unsorted
*/
@interface FBRequestConnection : NSObject

/*!
 @methodgroup Creating a request
*/

/*!
 @method

 @seealso initWithTimeout: for parameter details
*/
- (id)init;

/*!
 @method

 @abstract
 FBRequestConnection objects are used to issue one or more requests as a single
 request/response connection with Facebook.

 @discussion
 For a single request, the usual method for creating an FBRequestConnection
 object is to call one of the start* methods on FBRequest. However, it is
 allowable to init an FBRequestConnection object directly, and call addRequest
 to add one or more request objects to the connection, before calling start.

 @param timeout         NSTimeInterval to wait for a response before giving up.
                        The units are in seconds.

*/
     
- (id)initWithTimeout:(NSTimeInterval)timeout;

// properties

/*!
 @abstract
 The request that will be sent to the server.

 @discussion
 This property can be used to create a NSURLRequest without using
 FBRequestConnection to send that request.  It is also legal to set this
 property, and the provided NSMutableURLRequest will be used instead.  However,
 the NSMutableURLRequest must result in an appropriate response.  Further, once
 this property has been set, no more FBRequests can be added to this
 FBRequestConnection.
*/
@property(nonatomic, retain, readwrite) NSMutableURLRequest *urlRequest;

/*!
 @abstract
 The raw response that was returned from the server.  (readonly)

 @discussion
 This property can be used to inspect HTTP headers that were returned from
 the server.

 The property is nil until the request completes.  If there was a response,
 it is non-nil during the FBRequestHandler callback.
*/
@property(nonatomic, retain, readonly) NSHTTPURLResponse *urlResponse; 

/*!
 @methodgroup Adding requests
*/

/*!
 @method

 @seealso addRequest:completionHandler:batchEntryName: for parameter details
*/
- (void)addRequest:(FBRequest*)request
 completionHandler:(FBRequestHandler)handler;

/*!
 @method

 @abstract
 Add one or more requests to the connection, prior to calling start.

 @discussion
 The block passed to addRequest is retained until the block is called upon
 completion or cancellation of the connection.

 @param request         A request to be included in the round-trip when start is called

 @param handler         A handler to call back when the round-trip completes or times out

 @param name            An optional name for this request.  This can be used to feed
                        the results of one request as an input to another FBRequest in
                        the same FBRequestConnection; default=nil
*/
- (void)addRequest:(FBRequest*)request
 completionHandler:(FBRequestHandler)handler
    batchEntryName:(NSString*)name;

/*!
 @methodgroup Instance methods
*/

/*!
 @method

 @abstract
 Starts a connection with the server, capable of handling all of the requests
 added to the connection.

 Returns itself to allow for chained calls.

 @discussion
 Errors are reported via the handler callback, even in cases where no 
 communication is attempted by the implementation of FBRequestConnection. In 
 such cases multiple error conditions may apply, and if so the following
 priority (highest to lowest) is used.

 <pre>
 @textblock
 FBRequestConnectionInvalidRequestKey -- when an FBRequest is unable to be 
                                         encoded for transmission

 FBRequestConnectionInvalidBatchKey   -- when any request in the connection 
                                         cannot be encoded for transmission
                                         with the batch, all requests fail
 @/textblock
 </pre>
  
 Start is idempotent, and if no requests are associated with an
 FBRequestConnection object, the method nominally succeeds.
*/
- (FBRequestConnection*)start;

/*!
 @method

 @abstract
 Signals that a connection should be logically terminated, meaning the
 application is no longer interested in a response.

 @discussion
 Synchronously calls any handlers indicating the request was cancelled. Cancel
 does not guarantee that request related processing will cease, however it 
 does promise that  all handlers complete before cancel returns. A call to
 cancel prior to start, implies start/cancellation of all requests associated
 with the connection.
*/
- (void)cancel;

@end
