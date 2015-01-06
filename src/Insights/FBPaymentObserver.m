/*
 * Copyright 2010-present Facebook.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#import "FBPaymentObserver.h"

#import <StoreKit/StoreKit.h>

#import "FBAppEvents+Internal.h"
#import "FBDynamicFrameworkLoader.h"
#import "FBLogger.h"
#import "FBSettings.h"

static NSString *const FBAppEventNamePurchaseFailed = @"fb_mobile_purchase_failed";
static NSString *const FBAppEventParameterNameProductTitle = @"fb_content_title";
static NSString *const FBAppEventParameterNameTransactionID = @"fb_transaction_id";
static int const FBMaxParameterValueLength = 100;

@interface FBPaymentProductRequestor : NSObject<SKProductsRequestDelegate>

@property (nonatomic, retain) SKPaymentTransaction *transaction;

- (instancetype)initWithTransaction:(SKPaymentTransaction*)transaction;
- (void)resolveProducts;

@end

@interface FBPaymentObserver() <SKPaymentTransactionObserver>
@end

@implementation FBPaymentObserver {
    BOOL _observingTransactions;
}

+ (void)startObservingTransactions {
    [[self singleton] startObservingTransactions];
}

+ (void)stopObservingTransactions {
    [[self singleton] stopObservingTransactions];
}

//
// Internal methods
//

+ (FBPaymentObserver *)singleton {
    static dispatch_once_t pred;
    static FBPaymentObserver *shared = nil;

    dispatch_once(&pred, ^{
        shared = [[FBPaymentObserver alloc] init];
    });
    return shared;
}

- (instancetype) init {
    self = [super init];
    if (self) {
        _observingTransactions = NO;
    }
    return self;
}

- (void)startObservingTransactions {
    @synchronized (self) {
        if (!_observingTransactions) {
            [(SKPaymentQueue *)[fbdfl_SKPaymentQueueClass() defaultQueue] addTransactionObserver:self];
            _observingTransactions = YES;
        }
    }
}

- (void)stopObservingTransactions {
    @synchronized (self) {
        if (_observingTransactions) {
            [(SKPaymentQueue *)[fbdfl_SKPaymentQueueClass() defaultQueue] removeTransactionObserver:self];
            _observingTransactions = NO;
        }
    }
}

- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions {
    for (SKPaymentTransaction *transaction in transactions) {
        switch (transaction.transactionState) {
            case SKPaymentTransactionStatePurchasing:
            case SKPaymentTransactionStatePurchased:
            case SKPaymentTransactionStateFailed:
                [self handleTransaction:transaction];
                break;
            case SKPaymentTransactionStateDeferred:
            case SKPaymentTransactionStateRestored:
                break;
        }
    }
}

- (void)handleTransaction:(SKPaymentTransaction *)transaction {
    FBPaymentProductRequestor *productRequest = [[[FBPaymentProductRequestor alloc] initWithTransaction:transaction] autorelease];
    [productRequest resolveProducts];
}


@end

@interface FBPaymentProductRequestor()
@property (nonatomic, retain) SKProductsRequest *productRequest;
@end

@implementation FBPaymentProductRequestor

- (instancetype)initWithTransaction:(SKPaymentTransaction*)transaction {
    self = [super init];
    if (self) {
        _transaction = [transaction retain];
    }
    return self;
}

- (void)dealloc {
    self.transaction = nil;
    self.productRequest = nil;
    [super dealloc];
}

- (void)setProductRequest:(SKProductsRequest *)productRequest {
    if (productRequest != _productRequest) {
        if (_productRequest) {
            _productRequest.delegate = nil;
            [_productRequest release];
        }
        _productRequest = [productRequest retain];
    }
}

- (void)resolveProducts {
    NSString *productId = self.transaction.payment.productIdentifier;
    NSSet *productIdentifiers = [NSSet setWithObjects:productId, nil];
    self.productRequest = [[[fbdfl_SKProductsRequestClass() alloc] initWithProductIdentifiers:productIdentifiers] autorelease];
    self.productRequest.delegate = self;
    [self retain];
    [self.productRequest start];
}

- (NSString *)getTruncatedString:(NSString *)inputString {
    if (!inputString) {
        return @"";
    }

    return [inputString length] <= FBMaxParameterValueLength ? inputString : [inputString substringToIndex:FBMaxParameterValueLength];
}

- (void)logTransactionEvent:(SKProduct *)product {
    NSString *eventName = nil;
    NSString *transactionID = nil;
    switch (self.transaction.transactionState) {
        case SKPaymentTransactionStatePurchasing:
            eventName = FBAppEventNameInitiatedCheckout;
            break;
        case SKPaymentTransactionStatePurchased:
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wdeprecated-declarations"
            eventName = FBAppEventNamePurchased;
            transactionID = self.transaction.transactionIdentifier;
#pragma GCC diagnostic pop
            break;
        case SKPaymentTransactionStateFailed:
            eventName = FBAppEventNamePurchaseFailed;
            break;
        case SKPaymentTransactionStateDeferred:
        case SKPaymentTransactionStateRestored:
            return;
    }
    if (!eventName) {
        [FBLogger singleShotLogEntry:FBLoggingBehaviorAppEvents
                        formatString:@"FBPaymentObserver logTransactionEvent: event name cannot be nil"];
        return;
    }

    SKPayment *payment = self.transaction.payment;
    NSMutableDictionary *eventParameters = [NSMutableDictionary dictionaryWithDictionary:@ {
        FBAppEventParameterNameContentID: payment.productIdentifier ?: @"",
        FBAppEventParameterNameNumItems: @(payment.quantity),
    }];
    double totalAmount = 0;
    if (product) {
        totalAmount = payment.quantity * product.price.doubleValue;
        [eventParameters addEntriesFromDictionary:@ {
            FBAppEventParameterNameCurrency: [product.priceLocale objectForKey:NSLocaleCurrencyCode],
            FBAppEventParameterNameNumItems: @(payment.quantity),
            FBAppEventParameterNameProductTitle: [self getTruncatedString:product.localizedTitle],
            FBAppEventParameterNameDescription: [self getTruncatedString:product.localizedDescription],
        }];
        if (transactionID) {
            [eventParameters setObject:transactionID forKey:FBAppEventParameterNameTransactionID];
        }
    }

    [FBAppEvents logImplicitPurchaseEvent:eventName
                               valueToSum:@(totalAmount)
                               parameters:eventParameters
                                  session:nil
     ];
}

- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response {
    NSArray* products = response.products;
    NSArray* invalidProductIdentifiers = response.invalidProductIdentifiers;
    if (products.count + invalidProductIdentifiers.count != 1) {
        [FBLogger singleShotLogEntry:FBLoggingBehaviorAppEvents
                        formatString:@"FBPaymentObserver: Expect to resolve one product per request"];
    }
    SKProduct *product = nil;
    if (products.count) {
        product = products[0];
    }
    [self logTransactionEvent:product];
}

- (void)requestDidFinish:(SKRequest *)request {
    [self autorelease];
}

- (void)request:(SKRequest *)request didFailWithError:(NSError *)error {
    [self logTransactionEvent:nil];
    [self autorelease];
}

@end
