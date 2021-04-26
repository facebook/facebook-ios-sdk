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

#if FBSDK_SWIFT_PACKAGE
 #import "FBSDKAppEventName.h"
 #import "FBSDKAppEventsFlushBehavior.h"
#else
 #import <FBSDKCoreKit/FBSDKAppEventName.h>
 #import <FBSDKCoreKit/FBSDKAppEventsFlushBehavior.h>
#endif

@class FBSDKAccessToken;

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(EventLogging)
@protocol FBSDKEventLogging

@property (nonatomic, readonly) FBSDKAppEventsFlushBehavior flushBehavior;

- (void)flushForReason:(NSUInteger)flushReason;

- (void)logEvent:(NSString *)eventName
      parameters:(NSDictionary<NSString *, id> *)parameters;

- (void)logEvent:(NSString *)eventName
      valueToSum:(double)valueToSum
      parameters:(NSDictionary<NSString *, id> *)parameters;

- (void)logInternalEvent:(NSString *)eventName
      isImplicitlyLogged:(BOOL)isImplicitlyLogged;

- (void)logInternalEvent:(NSString *)eventName
              parameters:(NSDictionary *)parameters
      isImplicitlyLogged:(BOOL)isImplicitlyLogged;

- (void)logInternalEvent:(NSString *)eventName
              parameters:(NSDictionary *)parameters
      isImplicitlyLogged:(BOOL)isImplicitlyLogged
             accessToken:(FBSDKAccessToken *)accessToken;

- (void)logInternalEvent:(NSString *)eventName
              valueToSum:(double)valueToSum
      isImplicitlyLogged:(BOOL)isImplicitlyLogged;

@end

NS_ASSUME_NONNULL_END
