/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <Foundation/Foundation.h>

#import <FBSDKCoreKit/FBSDKAppStoreReceiptProviding.h>
#import <FBSDKCoreKit/FBSDKEventLogging.h>
#import <FBSDKCoreKit/FBSDKProductsRequestProtocols.h>
#import <FBSDKCoreKit_Basics/FBSDKCoreKit_Basics.h>

NS_ASSUME_NONNULL_BEGIN

/**
 Internal type exposed to facilitate transition to Swift.
 API Subject to change or removal without warning. Do not use.

 @warning INTERNAL - DO NOT USE
 */
NS_SWIFT_NAME(_PaymentProductRequestorFactory)
@interface FBSDKPaymentProductRequestorFactory : NSObject <FBSDKPaymentProductRequestorCreating>

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

// UNCRUSTIFY_FORMAT_OFF
- (instancetype)initWithSettings:(id<FBSDKSettings>)settings
                     eventLogger:(id<FBSDKEventLogging>)eventLogger
               gateKeeperManager:(Class<FBSDKGateKeeperManaging>)gateKeeperManager
                           store:(id<FBSDKDataPersisting>)store
                   loggerFactory:(id<__FBSDKLoggerCreating>)logger
          productsRequestFactory:(id<FBSDKProductsRequestCreating>)productsRequestFactory
         appStoreReceiptProvider:(id<FBSDKAppStoreReceiptProviding>)receiptProvider
NS_SWIFT_NAME(init(settings:eventLogger:gateKeeperManager:store:loggerFactory:productsRequestFactory:receiptProvider:))
NS_DESIGNATED_INITIALIZER;
// UNCRUSTIFY_FORMAT_ON

@end

NS_ASSUME_NONNULL_END
