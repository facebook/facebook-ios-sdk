/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <Foundation/Foundation.h>

#import <FBSDKCoreKit/FBSDKSettingsProtocol.h>
#import <FBSDKCoreKit/__FBSDKLoggerCreating.h>
#import <FBSDKCoreKit_Basics/FBSDKCoreKit_Basics.h>

#import "FBSDKAppStoreReceiptProviding.h"
#import "FBSDKEventLogging.h"
#import "FBSDKGateKeeperManaging.h"
#import "FBSDKPaymentProductRequestorCreating.h"
#import "FBSDKProductsRequestProtocols.h"

NS_ASSUME_NONNULL_BEGIN

/// Factory used to create `FBSDKPaymentProductRequestor` instances with dependencies.
NS_SWIFT_NAME(PaymentProductRequestorFactory)
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
