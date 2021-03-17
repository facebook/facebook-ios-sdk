// Copyright (c) 2014-present, Facebook, Inc. All rights reserved.
//
// You are hereby granted a non-exclusive, worldwide, royalty-free license to use,
// copy, modify, and distribute this software in source code or binary form for use
// in connection with the web services and APIs provided by Facebook.
//
// As with any software that integrates with the Facebook platform, your use of
// this software is subject to the Facebook Developer Principles and Policies
// [http://developers.facebook.com/policy/]. This copyright notice shall be
// included in all copies or substantial portions of the software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
// FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
// COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
// IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
// CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

#import <Foundation/Foundation.h>

#import "FBSDKGraphRequestHTTPMethod.h"

NS_ASSUME_NONNULL_BEGIN

@protocol FBSDKGraphRequestConnecting;

@class FBSDKGraphRequestConnection;
typedef void (^FBSDKGraphRequestBlock)(FBSDKGraphRequestConnection *_Nullable connection,
                                       id _Nullable result,
                                       NSError *_Nullable error);

/// A protocol to describe anything that represents a graph request
NS_SWIFT_NAME(GraphRequestProtocol)
@protocol FBSDKGraphRequest

/**
  The request parameters.
 */
@property (nonatomic, copy) NSDictionary<NSString *, id> *parameters;

/**
  The access token string used by the request.
 */
@property (nonatomic, copy, readonly, nullable) NSString *tokenString;

/**
  The Graph API endpoint to use for the request, for example "me".
 */
@property (nonatomic, copy, readonly) NSString *graphPath;

/**
  The HTTPMethod to use for the request, for example "GET" or "POST".
 */
@property (nonatomic, copy, readonly) FBSDKHTTPMethod HTTPMethod;

/**
  The Graph API version to use (e.g., "v2.0")
 */
@property (nonatomic, copy, readonly) NSString *version;

/**
  Starts a connection to the Graph API.
 @param handler The handler block to call when the request completes.
 */
- (id<FBSDKGraphRequestConnecting>)startWithCompletionHandler:(nullable FBSDKGraphRequestBlock)handler;

/**
  A formatted description of the graph request
 */
- (NSString *)formattedDescription;

@end

NS_ASSUME_NONNULL_END
