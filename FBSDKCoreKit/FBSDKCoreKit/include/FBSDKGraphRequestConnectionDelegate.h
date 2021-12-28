/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <Foundation/Foundation.h>

#import <FBSDKCoreKit/FBSDKGraphRequestConnecting.h>

NS_ASSUME_NONNULL_BEGIN

/**
 @protocol

 The `FBSDKGraphRequestConnectionDelegate` protocol defines the methods used to receive network
 activity progress information from a <FBSDKGraphRequestConnection>.
 */
NS_SWIFT_NAME(GraphRequestConnectionDelegate)
@protocol FBSDKGraphRequestConnectionDelegate <NSObject>

@optional

/**
 @method

 Tells the delegate the request connection will begin loading

 If the <FBSDKGraphRequestConnection> is created using one of the convenience factory methods prefixed with
 start, the object returned from the convenience method has already begun loading and this method
 will not be called when the delegate is set.

 @param connection    The request connection that is starting a network request
 */
- (void)requestConnectionWillBeginLoading:(id<FBSDKGraphRequestConnecting>)connection;

/**
 @method

 Tells the delegate the request connection finished loading

 If the request connection completes without a network error occurring then this method is called.
 Invocation of this method does not indicate success of every <FBSDKGraphRequest> made, only that the
 request connection has no further activity. Use the error argument passed to the FBSDKGraphRequestBlock
 block to determine success or failure of each <FBSDKGraphRequest>.

 This method is invoked after the completion handler for each <FBSDKGraphRequest>.

 @param connection    The request connection that successfully completed a network request
 */
- (void)requestConnectionDidFinishLoading:(id<FBSDKGraphRequestConnecting>)connection;

/**
 @method

 Tells the delegate the request connection failed with an error

 If the request connection fails with a network error then this method is called. The `error`
 argument specifies why the network connection failed. The `NSError` object passed to the
 FBSDKGraphRequestBlock block may contain additional information.

 @param connection    The request connection that successfully completed a network request
 @param error         The `NSError` representing the network error that occurred, if any. May be nil
 in some circumstances. Consult the `NSError` for the <FBSDKGraphRequest> for reliable
 failure information.
 */
- (void)requestConnection:(id<FBSDKGraphRequestConnecting>)connection
         didFailWithError:(NSError *)error;

/**
 @method

 Tells the delegate how much data has been sent and is planned to send to the remote host

 The byte count arguments refer to the aggregated <FBSDKGraphRequest> objects, not a particular <FBSDKGraphRequest>.

 Like `NSURLSession`, the values may change in unexpected ways if data needs to be resent.

 @param connection                The request connection transmitting data to a remote host
 @param bytesWritten              The number of bytes sent in the last transmission
 @param totalBytesWritten         The total number of bytes sent to the remote host
 @param totalBytesExpectedToWrite The total number of bytes expected to send to the remote host
 */
- (void)  requestConnection:(id<FBSDKGraphRequestConnecting>)connection
            didSendBodyData:(NSInteger)bytesWritten
          totalBytesWritten:(NSInteger)totalBytesWritten
  totalBytesExpectedToWrite:(NSInteger)totalBytesExpectedToWrite;

@end

NS_ASSUME_NONNULL_END
