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

#import <UIKit/UIKit.h>

#import "FBSDKAppEventName.h"
#import "FBSDKAppEventsNumberParser.h"
#import "FBSDKCodelessParameterComponent.h"

NS_ASSUME_NONNULL_BEGIN

@protocol FBSDKEventLogging;

NS_SWIFT_NAME(EventBinding)
@interface FBSDKEventBinding : NSObject

@property (class, nonatomic, readonly) id<FBSDKNumberParsing> numberParser;
@property (nullable, nonatomic, copy, readonly) FBSDKAppEventName eventName;
@property (nullable, nonatomic, copy, readonly) NSString *eventType;
@property (nullable, nonatomic, copy, readonly) NSString *appVersion;
@property (nullable, nonatomic, readonly) NSArray *path;
@property (nullable, nonatomic, copy, readonly) NSString *pathType;
@property (nullable, nonatomic, readonly) NSArray<FBSDKCodelessParameterComponent *> *parameters;

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

+ (BOOL)isPath:(nullable NSArray *)path matchViewPath:(nullable NSArray *)viewPath;
- (FBSDKEventBinding *)initWithJSON:(nullable NSDictionary<NSString *, id> *)dict
                        eventLogger:(id<FBSDKEventLogging>)eventLogger;
- (void)trackEvent:(nullable id)sender;
- (BOOL)isEqualToBinding:(FBSDKEventBinding *)binding;

@end

#endif

NS_ASSUME_NONNULL_END
