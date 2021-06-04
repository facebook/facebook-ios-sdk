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

#if SWIFT_PACKAGE
 #import "FBSDKGraphRequestFlags.h"
#else
 #import <FBSDKCoreKit/FBSDKGraphRequestFlags.h>
#endif

@protocol FBSDKGraphRequest;

typedef NSString *const FBSDKHTTPMethod NS_TYPED_EXTENSIBLE_ENUM NS_SWIFT_NAME(HTTPMethod);

NS_ASSUME_NONNULL_BEGIN

/// Describes anything that can provide instances of `GraphRequestProtocol`
NS_SWIFT_NAME(GraphRequestProviding)
@protocol FBSDKGraphRequestProviding

- (id<FBSDKGraphRequest>)createGraphRequestWithGraphPath:(NSString *)graphPath
                                                      parameters:(NSDictionary *)parameters
                                                     tokenString:(nullable NSString *)tokenString
                                                      HTTPMethod:(nullable FBSDKHTTPMethod)method
                                                           flags:(FBSDKGraphRequestFlags)flags;

- (id<FBSDKGraphRequest>)createGraphRequestWithGraphPath:(NSString *)graphPath
                                              parameters:(NSDictionary<NSString *, id> *)parameters;

- (id<FBSDKGraphRequest>)createGraphRequestWithGraphPath:(NSString *)graphPath;

- (id<FBSDKGraphRequest>)createGraphRequestWithGraphPath:(NSString *)graphPath
                           parameters:(NSDictionary<NSString *, id> *)parameters
                           HTTPMethod:(FBSDKHTTPMethod)method;

- (id<FBSDKGraphRequest>)createGraphRequestWithGraphPath:(NSString *)graphPath
                           parameters:(NSDictionary<NSString *, id> *)parameters
                           tokenString:(nullable NSString *)tokenString
                           version:(nullable NSString *)version
                           HTTPMethod:(FBSDKHTTPMethod)method;

- (id<FBSDKGraphRequest>)createGraphRequestWithGraphPath:(NSString *)graphPath
                                              parameters:(NSDictionary*)parameters
                                                   flags:(FBSDKGraphRequestFlags)flags;

@end

NS_ASSUME_NONNULL_END
