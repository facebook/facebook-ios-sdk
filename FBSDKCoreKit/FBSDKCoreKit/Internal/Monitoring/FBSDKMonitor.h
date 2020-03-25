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

#import "FBSDKCoreKit+Internal.h"

NS_ASSUME_NONNULL_BEGIN

/**
 The shared implementation for 'Monitoring' types to call into.
 For example if you want to record performance metrics you should
 add a PerformanceMonitoring class and call `[PerformanceMonitor record:metric]`.
 Internally the `record:` method should invoke the shared instance of this
 monitor class.

 Important: Should not be called directly.
 */
@interface FBSDKMonitor : NSObject

/**
 Stores entry in local memory until a limit is reached or a flush is forced.
 Will only record entries if the monitor is enabled.

 Important: Should not be called directly.
 */
+ (void)record:(_Nonnull id<FBSDKMonitorEntry>)entry;

/**
 Enable entries to be recorded.
 */
+ (void)enable;

@end

NS_ASSUME_NONNULL_END
