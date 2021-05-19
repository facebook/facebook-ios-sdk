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
#import "FBSDKLoggingBehavior.h"
#else
#import <FBSDKCoreKit/FBSDKLoggingBehavior.h>
#endif

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(Logging)
@protocol FBSDKLogging

@property (copy, nonatomic, readonly) NSString *contents;
@property (copy, nonatomic, readonly) FBSDKLoggingBehavior loggingBehavior;

- (instancetype)initWithLoggingBehavior:(FBSDKLoggingBehavior)loggingBehavior;

+ (void)singleShotLogEntry:(FBSDKLoggingBehavior)loggingBehavior
                  logEntry:(NSString *)logEntry;

- (void)logEntry:(NSString *)logEntry;

@end

NS_ASSUME_NONNULL_END
