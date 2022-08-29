/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <StoreKit/StoreKit.h>

@protocol FBSDKSettings;
@protocol FBSDKEventLogging;
@protocol FBSDKGateKeeperManaging;
@protocol FBSDKDataPersisting;
@protocol __FBSDKLoggerCreating;
@protocol FBSDKProductsRequestCreating;
@protocol FBSDKAppStoreReceiptProviding;

NS_ASSUME_NONNULL_BEGIN

/**
 Used for requesting information about purchase events from StoreKit to use when
 logging AppEvents
 */
NS_SWIFT_NAME(PaymentProductRequestor)
@interface FBSDKPaymentProductRequestor : NSObject <SKProductsRequestDelegate>

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithTransaction:(SKPaymentTransaction *)transaction
                           settings:(id<FBSDKSettings>)settings
                        eventLogger:(id<FBSDKEventLogging>)eventLogger
                  gateKeeperManager:(Class<FBSDKGateKeeperManaging>)gateKeeperManager
                              store:(id<FBSDKDataPersisting>)store
                      loggerFactory:(id<__FBSDKLoggerCreating>)loggerFactory
             productsRequestFactory:(id<FBSDKProductsRequestCreating>)productRequestFactory
            appStoreReceiptProvider:(id<FBSDKAppStoreReceiptProviding>)receiptProvider;

- (void)resolveProducts;

@end

NS_ASSUME_NONNULL_END
