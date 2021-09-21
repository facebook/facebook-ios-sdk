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

#import "FBSDKGateKeeperManager.h"

NS_ASSUME_NONNULL_BEGIN

@interface FBSDKGateKeeperManager (Testing)

@property (class, nonatomic, readonly) BOOL canLoadGateKeepers;
@property (class, nonatomic, nullable) FBSDKLogger *logger;
@property (class, nonatomic, nullable) id<FBSDKSettings> settings;
@property (class, nonatomic, nullable) id<FBSDKGraphRequestFactory> graphRequestFactory;
@property (class, nonatomic, nullable) id<FBSDKGraphRequestConnectionFactory> graphRequestConnectionFactory;
@property (class, nonatomic, nullable) id<FBSDKDataPersisting> store;

@property (class, nonatomic, nullable) NSDictionary<NSString *, id> *gateKeepers;
@property (class, nonatomic) BOOL requeryFinishedForAppStart;
@property (class, nonatomic, nullable) NSDate *timestamp;
@property (class, nonatomic) BOOL isLoadingGateKeepers;

+ (void)configureWithSettings:(id<FBSDKSettings>)settings
              graphRequestFactory:(id<FBSDKGraphRequestFactory>)graphRequestFactory
           graphRequestConnectionFactory:(nonnull id<FBSDKGraphRequestConnectionFactory>)graphRequestConnectionFactory
                        store:(id<FBSDKDataPersisting>)store
NS_SWIFT_NAME(configure(settings:graphRequestFactory:graphRequestConnectionFactory:store:));
+ (id<FBSDKGraphRequest>)requestToLoadGateKeepers;
+ (void)processLoadRequestResponse:(nullable id)result error:(nullable NSError *)error
NS_SWIFT_NAME(parse(result:error:));
+ (BOOL)_gateKeeperIsValid;
+ (void)reset;
+ (id<FBSDKGraphRequestFactory>)graphRequestFactory;

@end

NS_ASSUME_NONNULL_END
