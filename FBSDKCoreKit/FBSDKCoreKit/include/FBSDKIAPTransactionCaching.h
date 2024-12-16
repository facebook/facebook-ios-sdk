/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 Internal type exposed to facilitate transition to Swift.
 API Subject to change or removal without warning. Do not use.

 @warning INTERNAL - DO NOT USE
 */
NS_SWIFT_NAME(_IAPTransactionCaching)
@protocol FBSDKIAPTransactionCaching

@property (nonatomic, strong, nullable) NSDate *newCandidatesDate;
@property (nonatomic, assign) BOOL hasRestoredPurchases;

- (void)addTransaction:(nullable NSString *)transactionID
             eventName:(FBSDKAppEventName)eventName
             productID:(NSString *)productID
NS_SWIFT_NAME(addTransaction(transactionID:eventName:productID:));

- (void)removeTransaction:(nullable NSString *)transactionID
                eventName:(FBSDKAppEventName)eventName
                productID:(NSString *)productID
NS_SWIFT_NAME(removeTransaction(transactionID:eventName:productID:));

- (BOOL)contains:(nullable NSString *)transactionID
       eventName:(FBSDKAppEventName)eventName
       productID:(NSString *)productID
NS_SWIFT_NAME(contains(transactionID:eventName:productID:));

- (BOOL)contains:(nullable NSString *)transactionID
       productID:(NSString *)productID
NS_SWIFT_NAME(contains(transactionID:productID:));

- (void)trimIfNeeded:(BOOL)hasLowMemory
NS_SWIFT_NAME(trimIfNeeded(hasLowMemory:));

@end

NS_ASSUME_NONNULL_END
