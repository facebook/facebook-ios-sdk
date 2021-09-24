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

#if !TARGET_OS_TV

#import <Foundation/Foundation.h>

@protocol FBSDKBridgeAPIRequest;
@class FBSDKBridgeAPIResponse;

NS_ASSUME_NONNULL_BEGIN

/**
 Internal Type exposed to facilitate transition to Swift.
 API Subject to change or removal without warning. Do not use.

 @warning UNSAFE - DO NOT USE
 */
typedef void (^FBSDKBridgeAPIResponseBlock)(FBSDKBridgeAPIResponse *response)
NS_SWIFT_NAME(BridgeAPIResponseBlock);

/**
 Internal Type exposed to facilitate transition to Swift.
 API Subject to change or removal without warning. Do not use.

 @warning UNSAFE - DO NOT USE
 */
NS_SWIFT_NAME(BridgeAPIResponse)
@interface FBSDKBridgeAPIResponse : NSObject <NSCopying, NSObject>

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

+ (instancetype)bridgeAPIResponseWithRequest:(NSObject<FBSDKBridgeAPIRequest> *)request error:(NSError *)error;
+ (nullable instancetype)bridgeAPIResponseWithRequest:(NSObject<FBSDKBridgeAPIRequest> *)request
                                          responseURL:(NSURL *)responseURL
                                    sourceApplication:(nullable NSString *)sourceApplication
                                                error:(NSError *__autoreleasing *)errorRef;
+ (instancetype)bridgeAPIResponseCancelledWithRequest:(NSObject<FBSDKBridgeAPIRequest> *)request;

@property (nonatomic, assign, readonly, getter=isCancelled) BOOL cancelled;
@property (nullable, nonatomic, copy, readonly) NSError *error;
@property (nonatomic, copy, readonly) NSObject<FBSDKBridgeAPIRequest> *request;
@property (nullable, nonatomic, copy, readonly) NSDictionary<NSString *, id> *responseParameters;

@end

NS_ASSUME_NONNULL_END

#endif
