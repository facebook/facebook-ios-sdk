/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

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
@property (nonatomic, readonly) id<__FBSDKLoggerCreating> loggerFactory;
@property (nonatomic, readonly) id<FBSDKAppStoreReceiptProviding> appStoreReceiptProvider;

- (NSData *)fetchDeviceReceipt;
- (void)logImplicitTransactionEvent:(FBSDKAppEventName)eventName
                         valueToSum:(double)valueToSum
                         parameters:(nullable NSDictionary<NSString *, id> *)parameters;
- (BOOL)isSubscription:(SKProduct *)product;
- (NSMutableDictionary<NSString *, id> *)getEventParametersOfProduct:(nullable SKProduct *)product
                                                     withTransaction:(SKPaymentTransaction *)transaction;
- (void)logImplicitSubscribeTransaction:(SKPaymentTransaction *)transaction
                              ofProduct:(nullable SKProduct *)product;
- (void)appendOriginalTransactionID:(NSString *)transactionID;
- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response;

@end

NS_ASSUME_NONNULL_END
