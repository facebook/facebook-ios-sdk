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

#import "FBSDKCodelessIndexer+Internal.h"

NS_ASSUME_NONNULL_BEGIN

@interface FBSDKCodelessIndexer (Testing)

@property (class, nullable, nonatomic, readonly) id<FBSDKGraphRequestProviding> requestProvider;
@property (class, nullable, nonatomic, readonly) id<FBSDKServerConfigurationProviding> serverConfigurationProvider;
@property (class, nullable, nonatomic, readonly) id<FBSDKDataPersisting> store;
@property (class, nullable, nonatomic, copy) id<FBSDKGraphRequestConnectionProviding> connectionProvider;
@property (class, nullable, nonatomic, copy) Class<FBSDKSwizzling> swizzler;
@property (class, nullable, nonatomic, readonly) id<FBSDKSettings> settings;
@property (class, nullable, nonatomic, readonly) id<FBSDKAdvertiserIDProviding> advertiserIDProvider;
@property (class, nullable, nonatomic, readonly) NSString *currentSessionDeviceID;
@property (class, readonly) BOOL isCheckingSession;
@property (class, nullable, nonatomic, readonly) NSTimer *appIndexingTimer;

+ (nullable id<FBSDKGraphRequest>)requestToLoadCodelessSetup:(NSString *)appID
NS_SWIFT_NAME(requestToLoadCodelessSetup(appID:));

+ (void)loadCodelessSettingWithCompletionBlock:(FBSDKCodelessSettingLoadBlock)completionBlock;
+ (void)uploadIndexing:(nullable NSString *)tree;
+ (void)checkCodelessIndexingSession;
+ (NSDictionary<NSString *, NSNumber *> *)dimensionOf:(NSObject *)obj;

+ (void)reset;
+ (void)resetIsCodelessIndexing;

@end

NS_ASSUME_NONNULL_END
