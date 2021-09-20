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

#import <FBSDKCoreKit_Basics/FBSDKCoreKit_Basics.h>

NS_ASSUME_NONNULL_BEGIN

@protocol FBSDKFeatureChecking;
@protocol FBSDKGraphRequestFactory;
@protocol FBSDKSettings;

NS_SWIFT_NAME(CrashObserver)
@interface FBSDKCrashObserver : NSObject <FBSDKCrashObserving>

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

- (instancetype)initWithFeatureChecker:(id<FBSDKFeatureChecking>)featureChecker
                   graphRequestFactory:(id<FBSDKGraphRequestFactory>)graphRequestFactory
                              settings:(id<FBSDKSettings>)settings
                          crashHandler:(id<FBSDKCrashHandler>)crashHandler
NS_SWIFT_NAME(init(featureChecker:graphRequestFactory:settings:crashHandler:));

@end

NS_ASSUME_NONNULL_END
