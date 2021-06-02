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

@protocol FBSDKEventLogging;
@protocol FBSDKServerConfigurationProviding;

NS_ASSUME_NONNULL_BEGIN

// Class to encapsulate persisting of time spent data collected by [FBSDKAppEvents activateApp].  The activate app App Event is
// logged when restore: is called with sufficient time since the last deactivation.
NS_SWIFT_NAME(TimeSpentData)
@interface FBSDKTimeSpentData : NSObject

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithEventLogger:(id<FBSDKEventLogging>)eventLogger
        serverConfigurationProvider:(Class<FBSDKServerConfigurationProviding>)serverConfigurationProvider;

- (void)setSourceApplication:(nullable NSString *)sourceApplication openURL:(nullable NSURL *)url;
- (void)setSourceApplication:(nullable NSString *)sourceApplication isFromAppLink:(BOOL)isFromAppLink;
- (void)registerAutoResetSourceApplication;
- (void)suspend;
- (void)restore:(BOOL)calledFromActivateApp;

@end

NS_ASSUME_NONNULL_END
