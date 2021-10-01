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

#import "FBSDKSKAdNetworkConversionConfiguration.h"
#import "FBSDKSKAdNetworkReporter.h"

typedef void (^FBSDKSKAdNetworkReporterBlock)(void);

NS_ASSUME_NONNULL_BEGIN

@interface FBSDKSKAdNetworkReporter (Testing)

@property (nonatomic) BOOL isSKAdNetworkReportEnabled;
@property (nonnull, nonatomic) NSMutableArray<FBSDKSKAdNetworkReporterBlock> *completionBlocks;
@property (nonnull, nonatomic) dispatch_queue_t serialQueue;
@property (nullable, nonatomic) FBSDKSKAdNetworkConversionConfiguration *config;
@property (nonnull, nonatomic) NSDate *configRefreshTimestamp;
@property (nonatomic) NSInteger conversionValue;
@property (nonatomic) NSDate *timestamp;
@property (nonnull, nonatomic) NSMutableSet<NSString *> *recordedEvents;
@property (nonnull, nonatomic) NSMutableDictionary<NSString *, id> *recordedValues;

@property (nonnull, nonatomic, readonly) id<FBSDKGraphRequestFactory> graphRequestFactory;
@property (nonnull, nonatomic, readonly) id<FBSDKDataPersisting> store;
@property (nonnull, nonatomic, readonly) Class<FBSDKConversionValueUpdating> conversionValueUpdatable;

- (void)setConfiguration:(FBSDKSKAdNetworkConversionConfiguration *)configuration;
- (void)_loadReportData;
- (void)_recordAndUpdateEvent:(NSString *)event
                     currency:(nullable NSString *)currency
                        value:(nullable NSNumber *)value;
- (void)_updateConversionValue:(NSInteger)value;

- (void)setSKAdNetworkReportEnabled:(BOOL)enabled;

- (void)_loadConfigurationWithBlock:(FBSDKSKAdNetworkReporterBlock)block;
- (void)configureWithGraphRequestFactory:(id<FBSDKGraphRequestFactory>)graphRequestFactory
                                   store:(id<FBSDKDataPersisting>)store;

- (instancetype)initWithGraphRequestFactory:(id<FBSDKGraphRequestFactory>)graphRequestFactory
                                      store:(id<FBSDKDataPersisting>)store
                   conversionValueUpdatable:(Class<FBSDKConversionValueUpdating>)conversionValueUpdatable;

@end

NS_ASSUME_NONNULL_END
