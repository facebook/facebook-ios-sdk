/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <Foundation/Foundation.h>

#import <FBSDKCoreKit/FBSDKGraphRequestConnecting.h>
#import <FBSDKCoreKit/FBSDKGraphRequestConnectionDelegate.h>

NS_ASSUME_NONNULL_BEGIN

/**
 The key in the result dictionary for requests to old versions of the Graph API
 whose response is not a JSON object.


 When a request returns a non-JSON response (such as a "true" literal), that response
 will be wrapped into a dictionary using this const as the key. This only applies for very few Graph API
 prior to v2.1.
 */
FOUNDATION_EXPORT NSString *const FBSDKNonJSONResponseProperty
NS_SWIFT_NAME(NonJSONResponseProperty);

@protocol FBSDKGraphRequest;

/**
 The `FBSDKGraphRequestConnection` represents a single connection to Facebook to service a request.

 The request settings are encapsulated in a reusable <FBSDKGraphRequest> object. The
 `FBSDKGraphRequestConnection` object encapsulates the concerns of a single communication
 e.g. starting a connection, canceling a connection, or batching requests.

 */
NS_SWIFT_NAME(GraphRequestConnection)
@interface FBSDKGraphRequestConnection : NSObject <FBSDKGraphRequestConnecting>

/**
 The default timeout on all FBSDKGraphRequestConnection instances. Defaults to 60 seconds.
 */
@property (class, nonatomic, assign) NSTimeInterval defaultConnectionTimeout;

/**
 The delegate object that receives updates.
 */
@property (nullable, nonatomic, weak) id<FBSDKGraphRequestConnectionDelegate> delegate;

/**
 Gets or sets the timeout interval to wait for a response before giving up.
 */
@property (nonatomic, assign) NSTimeInterval timeout;

/**
 The raw response that was returned from the server.  (readonly)

 This property can be used to inspect HTTP headers that were returned from
 the server.

 The property is nil until the request completes.  If there was a response
 then this property will be non-nil during the FBSDKGraphRequestBlock callback.
 */
@property (nullable, nonatomic, readonly, retain) NSHTTPURLResponse *urlResponse;

/**
 Determines the operation queue that is used to call methods on the connection's delegate.

 By default, a connection is scheduled on the current thread in the default mode when it is created.
 You cannot reschedule a connection after it has started.
 */
@property (nullable, nonatomic) NSOperationQueue *delegateQueue;

/**
 @methodgroup Class methods
 */

/**
 @methodgroup Adding requests
 */

/**
 @method

 This method adds an <FBSDKGraphRequest> object to this connection.

 @param request       A request to be included in the round-trip when start is called.
 @param completion       A handler to call back when the round-trip completes or times out.

 The completion handler is retained until the block is called upon the
 completion or cancellation of the connection.
 */
- (void)addRequest:(id<FBSDKGraphRequest>)request
        completion:(FBSDKGraphRequestCompletion)completion;

/**
 @method

 This method adds an <FBSDKGraphRequest> object to this connection.

 @param request         A request to be included in the round-trip when start is called.

 @param completion         A handler to call back when the round-trip completes or times out.
 The handler will be invoked on the main thread.

 @param name            A name for this request.  This can be used to feed
 the results of one request to the input of another <FBSDKGraphRequest> in the same
 `FBSDKGraphRequestConnection` as described in
 [Graph API Batch Requests]( https://developers.facebook.com/docs/reference/api/batch/ ).

 The completion handler is retained until the block is called upon the
 completion or cancellation of the connection. This request can be named
 to allow for using the request's response in a subsequent request.
 */
- (void)addRequest:(id<FBSDKGraphRequest>)request
              name:(NSString *)name
        completion:(FBSDKGraphRequestCompletion)completion;

/**
 @method

 This method adds an <FBSDKGraphRequest> object to this connection.

 @param request         A request to be included in the round-trip when start is called.

 @param completion         A handler to call back when the round-trip completes or times out.

 @param parameters The dictionary of parameters to include for this request
 as described in [Graph API Batch Requests]( https://developers.facebook.com/docs/reference/api/batch/ ).
 Examples include "depends_on", "name", or "omit_response_on_success".

 The completion handler is retained until the block is called upon the
 completion or cancellation of the connection. This request can be named
 to allow for using the request's response in a subsequent request.
 */
- (void)addRequest:(id<FBSDKGraphRequest>)request
        parameters:(nullable NSDictionary<NSString *, id> *)parameters
        completion:(FBSDKGraphRequestCompletion)completion;

/**
 @methodgroup Instance methods
 */

/**
 @method

 Signals that a connection should be logically terminated as the
 application is no longer interested in a response.

 Synchronously calls any handlers indicating the request was cancelled. Cancel
 does not guarantee that the request-related processing will cease. It
 does promise that  all handlers will complete before the cancel returns. A call to
 cancel prior to a start implies a cancellation of all requests associated
 with the connection.
 */
- (void)cancel;

/**
 @method

 This method starts a connection with the server and is capable of handling all of the
 requests that were added to the connection.

 By default, a connection is scheduled on the current thread in the default mode when it is created.
 See `setDelegateQueue:` for other options.

 This method cannot be called twice for an `FBSDKGraphRequestConnection` instance.
 */
- (void)start;

/**
 @method

 Overrides the default version for a batch request

 The SDK automatically prepends a version part, such as "v2.0" to API paths in order to simplify API versioning
 for applications. If you want to override the version part while using batch requests on the connection, call
 this method to set the version for the batch request.

 @param version   This is a string in the form @"v2.0" which will be used for the version part of an API path
 */
- (void)overrideGraphAPIVersion:(NSString *)version;

@end

NS_ASSUME_NONNULL_END
