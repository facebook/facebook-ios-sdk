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

#import "FBSDKPaymentProductRequestor.h"

@protocol FBSDKProductsRequest;
@protocol FBSDKProductsRequestCreating;

NS_ASSUME_NONNULL_BEGIN

@interface FBSDKPaymentProductRequestor (Testing)

@property (class, nonatomic, readonly) NSMutableArray *pendingRequestors;
@property (nonatomic, retain) id<FBSDKProductsRequest> productsRequest;
@property (nonatomic, retain) SKPaymentTransaction *transaction;
@property (nonatomic, readonly) id<FBSDKProductsRequestCreating> productRequestFactory;
@property (nonatomic, readonly) id<FBSDKSettings> settings;
@property (nonatomic, readonly) id<FBSDKEventLogging> eventLogger;
@property (nonatomic, readonly) Class<FBSDKGateKeeperManaging> gateKeeperManager;
@property (nonatomic, readonly) id<FBSDKDataPersisting> store;
@property (nonatomic, readonly) id<FBSDKLoggingCreating> loggerFactory;
@property (nonatomic, readonly) id<FBSDKAppStoreReceiptProviding> appStoreReceiptProvider;

- (NSData *)fetchDeviceReceipt;
- (void)logImplicitTransactionEvent:(NSString *)eventName
                         valueToSum:(double)valueToSum
                         parameters:(NSDictionary<NSString *, id> *)parameters;
- (BOOL)isSubscription:(SKProduct *)product;
- (NSMutableDictionary<NSString *, id> *)getEventParametersOfProduct:(nullable SKProduct *)product
                                                     withTransaction:(SKPaymentTransaction *)transaction;
- (void)logImplicitSubscribeTransaction:(SKPaymentTransaction *)transaction
                              ofProduct:(nullable SKProduct *)product;
- (void)appendOriginalTransactionID:(NSString *)transactionID;
- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response;

@end

NS_ASSUME_NONNULL_END
