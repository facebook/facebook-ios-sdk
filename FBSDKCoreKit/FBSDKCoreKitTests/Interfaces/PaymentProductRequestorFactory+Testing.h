/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "FBSDKPaymentProductRequestorFactory.h"

NS_ASSUME_NONNULL_BEGIN

@interface FBSDKPaymentProductRequestorFactory (Testing)

@property (nonatomic, readonly) id<FBSDKSettings> settings;
@property (nonatomic, readonly) id<FBSDKEventLogging> eventLogger;
@property (nullable, nonatomic) Class<FBSDKGateKeeperManaging> gateKeeperManager;
@property (nullable, nonatomic) id<FBSDKDataPersisting> store;
@property (nullable, nonatomic) id<__FBSDKLoggerCreating> loggerFactory;
@property (nonatomic, readonly) id<FBSDKProductsRequestCreating> productsRequestFactory;
@property (nonatomic, readonly) id<FBSDKAppStoreReceiptProviding> appStoreReceiptProvider;

@end

NS_ASSUME_NONNULL_END
