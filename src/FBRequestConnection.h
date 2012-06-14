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
 Normally requests return JSON data that is parsed into a set of `NSDictionary`
 and `NSArray` objects.

 When a request returns a non-JSON response, that response is packaged in
 a `NSDictionary` using FBNonJSONResponseProperty as the key and the literal
 response as the value.
*/
extern NSString *const FBNonJSONResponseProperty;

/*!
 @typedef FBRequestHandler

 @abstract
 A block that is passed to addRequest to register for a callback with the results of that
 request once the connection completes.

 @discussion
 Pass a block of this type when calling addRequest.  This will be called once
 the request completes.  The call occurs on the UI thread.

 @param connection      The `FBRequestConnection` that sent the request.

 @param result          The result of the request.  This is a translation of
                        JSON data to `NSDictionary` and `NSArray` objects.  This
                        is nil if there was an error.

 @param error           The `NSError` representing any error that occurred.

*/
typedef void (^FBRequestHandler)(FBRequestConnection *connection, 
                                 id result,
                                 NSError *error);

/*!
 @class FBRequestConnection

 @abstract
 The `FBRequestConnection` represents a single connection to Facebook to service a request.

 @discussion
 The request settings are encapsulated in a reusable <FBRequest> object. The 
 `FBRequestConnection` object encapsulates the concerns of a single communication
 e.g. starting a connection, canceling a connection, or batching requests.

*/
@interface FBRequestConnection : NSObject

/*!
 @methodgroup Creating a request
*/

/*!
 @method

 Calls <initWithTimeout:> with a default timeout of 180 seconds.
*/
- (id)init;

/*!
 @method

 @abstract
 `FBRequestConnection` objects are used to issue one or more requests as a single
 request/response connection with Facebook.

 @discussion
 For a single request, the usual method for creating an `FBRequestConnection`
 object is to call one of the **start* ** methods on <FBRequest>. However, it is
 allowable to init an `FBRequestConnection` object directly, and call 
 <addRequest:completionHandler:> to add one or more request objects to the 
 connection, before calling start.
 
 Note that if requests are part of a batch, they must have an open
 FBSession that has an access token associated with it. Alternatively a default App ID
 must be set either in the plist or through an explicit call to <[FBSession defaultAppID]>.

 @param timeout         The `NSTimeInterval` (seconds) to wait for a response before giving up.
*/
     
- (id)initWithTimeout:(NSTimeInterval)timeout;

// properties

/*!
 @abstract
 The request that will be sent to the server.

 @discussion
 This property can be used to create a `NSURLRequest` without using
 `FBRequestConnection` to send that request.  It is legal to set this property 
 in which case the provided `NSMutableURLRequest` will be used instead.  However,
 the `NSMutableURLRequest` must result in an appropriate response.  Furthermore, once
 this property has been set, no more <FBRequest> objects can be added to this
 `FBRequestConnection`.
*/
@property(nonatomic, retain, readwrite) NSMutableURLRequest *urlRequest;

/*!
 @abstract
 The raw response that was returned from the server.  (readonly)

 @discussion
 This property can be used to inspect HTTP headers that were returned from
 the server.

 The property is nil until the request completes.  If there was a response
 then this property will be non-nil during the FBRequestHandler callback.
*/
@property(nonatomic, retain, readonly) NSHTTPURLResponse *urlResponse; 

/*!
 @methodgroup Adding requests
*/

/*!
 @method
 
 @abstract
 This method adds an <FBRequest> object to this connection and then calls 
 <start> on the connection.
 
 @discussion
 The completion handler is retained until the block is called upon the 
 completion or cancellation of the connection.
 
 @param request       A request to be included in the round-trip when start is called.
 @param handler       A handler to call back when the round-trip completes or times out.
*/
- (void)addRequest:(FBRequest*)request
 completionHandler:(FBRequestHandler)handler;

/*!
 @method

 @abstract
 This method adds an <FBRequest> object to this connection and then calls 
 <start> on the connection.

 @discussion
 The completion handler is retained until the block is called upon the
 completion or cancellation of the connection. This request can be named
 to allow for using the request's response in a subsequent request.

 @param request         A request to be included in the round-trip when start is called.

 @param handler         A handler to call back when the round-trip completes or times out.
 
 @param name            An optional name for this request.  This can be used to feed
 the results of one request to the input of another <FBRequest> in the same 
 `FBRequestConnection` as described in 
 [Graph API Batch Requests]( https://developers.facebook.com/docs/reference/api/batch/ ). 
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
 This method starts a connection with the server and is capable of handling all of the 
 requests that were added to the connection.

 @discussion
 Errors are reported via the handler callback, even in cases where no 
 communication is attempted by the implementation of `FBRequestConnection`. In 
 such cases multiple error conditions may apply, and if so the following
 priority (highest to lowest) is used:

 - `FBRequestConnectionInvalidRequestKey` -- this error is reported when an 
 <FBRequest> cannot be encoded for transmission.

 - `FBRequestConnectionInvalidBatchKey`   -- this error is reported when any
 request in the connection cannot be encoded for transmission with the batch.
 In this scenario all requests fail.
  
 This method cannot be called twice for an `FBRequestConnection` instance.
*/
- (void)start;

/*!
 @method

 @abstract
 Signals that a connection should be logically terminated as the
 application is no longer interested in a response.

 @discussion
 Synchronously calls any handlers indicating the request was cancelled. Cancel
 does not guarantee that the request-related processing will cease. It 
 does promise that  all handlers will complete before the cancel returns. A call to
 cancel prior to a start implies a cancellation of all requests associated
 with the connection.
*/
- (void)cancel;

@end
