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

#import "FBSDKLoggingBehavior.h"
#import "FBSDKAdvertisingTrackingStatus.h"

NS_SWIFT_NAME(SettingsProtocol)
@protocol FBSDKSettings

@property (class, nonatomic, copy, nullable) NSString *appID;
@property (class, nonatomic, copy, nullable) NSString *clientToken;
@property (class, nullable, nonatomic, copy) NSString *userAgentSuffix;
@property (class, nullable, nonatomic, copy) NSString *sdkVersion;
@property (class, nonatomic, copy, nonnull) NSSet<FBSDKLoggingBehavior> *loggingBehaviors;
@property (nonatomic, copy, nullable) NSString *appID;
@property (nonatomic, readonly) BOOL isDataProcessingRestricted;
@property (nonatomic, readonly) BOOL isAutoLogAppEventsEnabled;
@property (nonatomic, readonly) BOOL isSetATETimeExceedsInstallTime;
@property (nonatomic, readonly) BOOL isSKAdNetworkReportEnabled;
@property (nonatomic, readonly, nonnull) NSSet<FBSDKLoggingBehavior> *loggingBehaviors;
@property (nonatomic) FBSDKAdvertisingTrackingStatus advertisingTrackingStatus;
@property (nonatomic, readonly, nullable) NSDate* installTimestamp;
@property (nonatomic, readonly, nullable) NSDate* advertiserTrackingEnabledTimestamp;
@property (nonatomic, readonly) BOOL shouldLimitEventAndDataUsage;
@property (nonatomic) BOOL shouldUseTokenOptimizations;
@property (nonatomic, readonly) NSString * _Nonnull graphAPIVersion;

@end
