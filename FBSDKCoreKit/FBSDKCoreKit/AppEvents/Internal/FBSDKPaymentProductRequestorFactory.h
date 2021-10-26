/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <Foundation/Foundation.h>

#import "FBSDKPaymentProductRequestorCreating.h"

@protocol FBSDKSettings;
@protocol FBSDKEventLogging;
@protocol FBSDKGateKeeperManaging;
@protocol FBSDKDataPersisting;
@protocol FBSDKLoggingCreating;
@protocol FBSDKProductsRequestCreating;
@protocol FBSDKAppStoreReceiptProviding;

NS_ASSUME_NONNULL_BEGIN

/// Factory used to create `FBSDKPaymentProductRequestor` instances with dependencies.
NS_SWIFT_NAME(PaymentProductRequestorFactory)
@interface FBSDKPaymentProductRequestorFactory : NSObject <FBSDKPaymentProductRequestorCreating>

// UNCRUSTIFY_FORMAT_OFF
- (instancetype)initWithSettings:(id<FBSDKSettings>)settings
                     eventLogger:(id<FBSDKEventLogging>)eventLogger
               gateKeeperManager:(Class<FBSDKGateKeeperManaging>)gateKeeperManager
                           store:(id<FBSDKDataPersisting>)store
                   loggerFactory:(id<FBSDKLoggingCreating>)logger
          productsRequestFactory:(id<FBSDKProductsRequestCreating>)productsRequestFactory
         appStoreReceiptProvider:(id<FBSDKAppStoreReceiptProviding>)receiptProvider
NS_SWIFT_NAME(init(settings:eventLogger:gateKeeperManager:store:loggerFactory:productsRequestFactory:receiptProvider:));
// UNCRUSTIFY_FORMAT_ON

@end

NS_ASSUME_NONNULL_END
