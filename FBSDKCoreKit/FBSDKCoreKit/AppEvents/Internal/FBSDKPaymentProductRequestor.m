/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "FBSDKPaymentProductRequestor.h"

#import <StoreKit/StoreKit.h>

#import <FBSDKCoreKit/__FBSDKLoggerCreating.h>
#import <FBSDKCoreKit_Basics/FBSDKCoreKit_Basics.h>

#import "FBSDKAppEventName+Internal.h"
#import "FBSDKAppEventParameterName+Internal.h"
#import "FBSDKAppEventsFlushReason.h"
#import "FBSDKAppStoreReceiptProviding.h"
#import "FBSDKEventLogging.h"
#import "FBSDKGateKeeperManaging.h"
#import "FBSDKProductsRequestProtocols.h"
#import "FBSDKSettingsProtocol.h"

static NSString *const FBSDKPaymentObserverOriginalTransactionKey = @"com.facebook.appevents.PaymentObserver.originalTransaction";
static NSString *const FBSDKPaymentObserverDelimiter = @",";

static NSString *const FBSDKGateKeeperAppEventsIfAutoLogSubs = @"app_events_if_auto_log_subs";
static int const FBSDKMaxParameterValueLength = 100;

@interface FBSDKPaymentProductRequestor ()

@property (class, nonatomic, readonly) NSMutableArray<FBSDKPaymentProductRequestor *> *pendingRequestors;
@property (nonatomic, retain) SKPaymentTransaction *transaction;
@property (nonatomic, readonly) id<FBSDKAppStoreReceiptProviding> appStoreReceiptProvider;
@property (nonatomic, retain) id<FBSDKProductsRequest> productsRequest;
@property (nonatomic, readonly) id<FBSDKProductsRequestCreating> productRequestFactory;
@property (nonatomic, readonly) id<FBSDKSettings> settings;
@property (nonatomic, readonly) id<FBSDKEventLogging> eventLogger;
@property (nonatomic, readonly) Class<FBSDKGateKeeperManaging> gateKeeperManager;
@property (nonatomic, readonly) id<FBSDKDataPersisting> store;
@property (nonatomic, readonly) id<__FBSDKLoggerCreating> loggerFactory;
@property (nonatomic) NSMutableSet<NSString *> *originalTransactionSet;
@property (nonatomic) NSSet<NSString *> *eventsWithReceipt;
@property (nonatomic, readonly) NSDateFormatter *formatter;

@end

@implementation FBSDKPaymentProductRequestor

static NSMutableArray<FBSDKPaymentProductRequestor *> *_pendingRequestors;

+ (void)initialize
{
  if (self.class == FBSDKPaymentProductRequestor.class) {
    _pendingRequestors = [NSMutableArray new];
  }
}

- (instancetype)initWithTransaction:(SKPaymentTransaction *)transaction
                           settings:(id<FBSDKSettings>)settings
                        eventLogger:(id<FBSDKEventLogging>)eventLogger
                  gateKeeperManager:(Class<FBSDKGateKeeperManaging>)gateKeeperManager
                              store:(id<FBSDKDataPersisting>)store
                      loggerFactory:(id<__FBSDKLoggerCreating>)loggerFactory
             productsRequestFactory:(id<FBSDKProductsRequestCreating>)productRequestFactory
            appStoreReceiptProvider:(id<FBSDKAppStoreReceiptProviding>)receiptProvider
{
  if ((self = [super init])) {
    _settings = settings;
    _eventLogger = eventLogger;
    _gateKeeperManager = gateKeeperManager;
    _store = store;
    _loggerFactory = loggerFactory;
    _productRequestFactory = productRequestFactory;
    _appStoreReceiptProvider = receiptProvider;
    _transaction = transaction;
    _formatter = [NSDateFormatter new];
    _formatter.dateFormat = @"yyyy-MM-dd HH:mm:ssZ";
    NSString *data = [_store fb_stringForKey:FBSDKPaymentObserverOriginalTransactionKey];
    _eventsWithReceipt = [NSSet setWithArray:@[FBSDKAppEventNamePurchased, FBSDKAppEventNameSubscribe,
                                               FBSDKAppEventNameStartTrial]];
    if (data) {
      _originalTransactionSet = [NSMutableSet setWithArray:[data componentsSeparatedByString:FBSDKPaymentObserverDelimiter]];
    } else {
      _originalTransactionSet = [NSMutableSet new];
    }
  }
  return self;
}

+ (NSMutableArray<FBSDKPaymentProductRequestor *> *)pendingRequestors
{
  return _pendingRequestors;
}

- (void)setProductsRequest:(id<FBSDKProductsRequest>)productsRequest
{
  if (productsRequest != _productsRequest) {
    if (_productsRequest) {
      _productsRequest.delegate = nil;
    }
    _productsRequest = productsRequest;
  }
}

- (void)resolveProducts
{
  NSString *productId = self.transaction.payment.productIdentifier;
  NSSet<NSString *> *productIdentifiers = [NSSet setWithObjects:productId, nil];
  self.productsRequest = [self.productRequestFactory createWithProductIdentifiers:productIdentifiers];
  self.productsRequest.delegate = self;
  @synchronized(self.class.pendingRequestors) {
    [FBSDKTypeUtility array:self.class.pendingRequestors addObject:self];
  }
  [self.productsRequest start];
}

- (NSString *)getTruncatedString:(NSString *)inputString
{
  if (!inputString) {
    return @"";
  }

  return inputString.length <= FBSDKMaxParameterValueLength ? inputString : [inputString substringToIndex:FBSDKMaxParameterValueLength];
}

- (void)logTransactionEvent:(SKProduct *)product
{
  if ([self isSubscription:product]
      && [self.gateKeeperManager boolForKey:FBSDKGateKeeperAppEventsIfAutoLogSubs
                               defaultValue:NO]) {
    [self logImplicitSubscribeTransaction:self.transaction ofProduct:product];
  } else {
    [self logImplicitPurchaseTransaction:self.transaction ofProduct:product];
  }
}

- (BOOL)isSubscription:(SKProduct *)product
{
#if !TARGET_OS_TV
  if (@available(iOS 11.2, *)) {
    return (product.subscriptionPeriod != nil) && ((unsigned long)product.subscriptionPeriod.numberOfUnits > 0);
  }
#endif
  return NO;
}

- (NSMutableDictionary<NSString *, id> *)getEventParametersOfProduct:(SKProduct *)product
                                                     withTransaction:(SKPaymentTransaction *)transaction
{
  NSString *transactionID = nil;
  NSString *transactionDate = nil;
  switch (transaction.transactionState) {
    case SKPaymentTransactionStatePurchasing:
      break;
    case SKPaymentTransactionStatePurchased:
      transactionID = transaction.transactionIdentifier;
      transactionDate = [_formatter stringFromDate:transaction.transactionDate];
      break;
    case SKPaymentTransactionStateFailed:
      break;
    case SKPaymentTransactionStateRestored:
      transactionDate = [_formatter stringFromDate:transaction.transactionDate];
      break;
    default: break;
  }
  SKPayment *payment = transaction.payment;
  NSMutableDictionary<NSString *, id> *eventParameters = [NSMutableDictionary dictionaryWithDictionary:@{
                                                            FBSDKAppEventParameterNameContentID : payment.productIdentifier ?: @"",
                                                            FBSDKAppEventParameterNameNumItems : @(payment.quantity),
                                                            FBSDKAppEventParameterNameTransactionDate : transactionDate ?: @"",
                                                          }];
  if (product) {
    [eventParameters addEntriesFromDictionary:@{
       FBSDKAppEventParameterNameNumItems : @(payment.quantity),
       FBSDKAppEventParameterNameProductTitle : [self getTruncatedString:product.localizedTitle],
       FBSDKAppEventParameterNameDescription : [self getTruncatedString:product.localizedDescription],
     }];
    [FBSDKTypeUtility dictionary:eventParameters
                       setObject:product.priceLocale.currencyCode
                          forKey:FBSDKAppEventParameterNameCurrency];
    if (transactionID) {
      [FBSDKTypeUtility dictionary:eventParameters setObject:transactionID forKey:FBSDKAppEventParameterNameTransactionID];
    }
  }

#if !TARGET_OS_TV
  if (@available(iOS 11.2, *)) {
    if ([self isSubscription:product]) {
      // subs inapp
      [FBSDKTypeUtility dictionary:eventParameters setObject:[self durationOfSubscriptionPeriod:product.subscriptionPeriod] forKey:FBSDKAppEventParameterNameSubscriptionPeriod];
      [FBSDKTypeUtility dictionary:eventParameters setObject:@"subs" forKey:FBSDKAppEventParameterNameInAppPurchaseType];
      [FBSDKTypeUtility dictionary:eventParameters setObject:[self isStartTrial:transaction ofProduct:product] ? @"1" : @"0" forKey:FBSDKAppEventParameterNameIsStartTrial];
      // trial information for subs
      SKProductDiscount *discount = product.introductoryPrice;
      if (discount) {
        if (discount.paymentMode == SKProductDiscountPaymentModeFreeTrial) {
          [FBSDKTypeUtility dictionary:eventParameters setObject:@"1" forKey:FBSDKAppEventParameterNameHasFreeTrial];
        } else {
          [FBSDKTypeUtility dictionary:eventParameters setObject:@"0" forKey:FBSDKAppEventParameterNameHasFreeTrial];
        }
        [FBSDKTypeUtility dictionary:eventParameters setObject:[self durationOfSubscriptionPeriod:discount.subscriptionPeriod] forKey:FBSDKAppEventParameterNameTrialPeriod];
        [FBSDKTypeUtility dictionary:eventParameters setObject:discount.price forKey:FBSDKAppEventParameterNameTrialPrice];
      }
    } else {
      [FBSDKTypeUtility dictionary:eventParameters setObject:@"inapp" forKey:FBSDKAppEventParameterNameInAppPurchaseType];
    }
  }
#endif
  return eventParameters;
}

- (void)appendOriginalTransactionID:(NSString *)transactionID
{
  if (!transactionID) {
    return;
  }
  [self.originalTransactionSet addObject:transactionID];
  [self.store fb_setObject:[[self.originalTransactionSet allObjects] componentsJoinedByString:FBSDKPaymentObserverDelimiter]
                    forKey:FBSDKPaymentObserverOriginalTransactionKey];
}

- (void)clearOriginalTransactionID:(NSString *)transactionID
{
  if (!transactionID) {
    return;
  }
  [self.originalTransactionSet removeObject:transactionID];
  [self.store fb_setObject:[[self.originalTransactionSet allObjects] componentsJoinedByString:FBSDKPaymentObserverDelimiter]
                    forKey:FBSDKPaymentObserverOriginalTransactionKey];
}

- (BOOL)isStartTrial:(SKPaymentTransaction *)transaction
           ofProduct:(SKProduct *)product
{
#if !TARGET_OS_TV
  // promotional offer starting from iOS 12.2
  if (@available(iOS 12.2, *)) {
    SKPaymentDiscount *paymentDiscount = transaction.payment.paymentDiscount;
    if (paymentDiscount) {
      NSArray<SKProductDiscount *> *discounts = product.discounts;
      for (SKProductDiscount *discount in discounts) {
        if (discount.paymentMode == SKProductDiscountPaymentModeFreeTrial
            && [paymentDiscount.identifier isEqualToString:discount.identifier]) {
          return YES;
        }
      }
    }
  }
  // introductory offer starting from iOS 11.2
  if (@available(iOS 11.2, *)) {
    if (product.introductoryPrice
        && product.introductoryPrice.paymentMode == SKProductDiscountPaymentModeFreeTrial) {
      NSString *originalTransactionID = transaction.originalTransaction.transactionIdentifier;
      // only consider the very first trial transaction as start trial
      if (!originalTransactionID) {
        return YES;
      }
    }
  }
#endif
  return NO;
}

- (nullable NSString *)durationOfSubscriptionPeriod:(id)subcriptionPeriod
{
#if !TARGET_OS_TV
  if (@available(iOS 11.2, *)) {
    if (subcriptionPeriod && [subcriptionPeriod isKindOfClass:SKProductSubscriptionPeriod.class]) {
      SKProductSubscriptionPeriod *period = (SKProductSubscriptionPeriod *)subcriptionPeriod;
      NSString *unit = nil;
      switch (period.unit) {
        case SKProductPeriodUnitDay: unit = @"D"; break;
        case SKProductPeriodUnitWeek: unit = @"W"; break;
        case SKProductPeriodUnitMonth: unit = @"M"; break;
        case SKProductPeriodUnitYear: unit = @"Y"; break;
      }
      return [NSString stringWithFormat:@"P%lu%@", (unsigned long)period.numberOfUnits, unit];
    }
  }
#endif
  return nil;
}

- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response
{
  NSArray<SKProduct *> *products = response.products;
  NSArray<NSString *> *invalidProductIdentifiers = response.invalidProductIdentifiers;
  if (products.count + invalidProductIdentifiers.count != 1) {
    id<FBSDKLogging> logger = [self.loggerFactory createLoggerWithLoggingBehavior:FBSDKLoggingBehaviorAppEvents];
    [logger logEntry:@"FBSDKPaymentObserver: Expect to resolve one product per request"];
  }
  SKProduct *product = nil;
  if (products.count) {
    product = products.firstObject;
  }
  [self logTransactionEvent:product];
}

- (void)requestDidFinish:(SKRequest *)request
{
  [self cleanUp];
}

- (void)request:(SKRequest *)request didFailWithError:(NSError *)error
{
  [self logTransactionEvent:nil];
  [self cleanUp];
}

- (void)cleanUp
{
  @synchronized(self.class.pendingRequestors) {
    [self.class.pendingRequestors removeObject:self];
  }
}

- (void)logImplicitSubscribeTransaction:(SKPaymentTransaction *)transaction
                              ofProduct:(SKProduct *)product
{
  NSString *eventName = nil;
  NSString *originalTransactionID = transaction.originalTransaction.transactionIdentifier;
  switch (transaction.transactionState) {
    case SKPaymentTransactionStatePurchasing:
      eventName = @"SubscriptionInitiatedCheckout";
      break;
    case SKPaymentTransactionStatePurchased:
      if ([self isStartTrial:transaction ofProduct:product]) {
        eventName = FBSDKAppEventNameStartTrial;
        [self clearOriginalTransactionID:originalTransactionID];
      } else {
        if (originalTransactionID && [self.originalTransactionSet containsObject:originalTransactionID]) {
          return;
        }
        eventName = FBSDKAppEventNameSubscribe;
        [self appendOriginalTransactionID:(originalTransactionID ?: transaction.transactionIdentifier)];
      }
      break;
    case SKPaymentTransactionStateFailed:
      eventName = @"SubscriptionFailed";
      break;
    case SKPaymentTransactionStateRestored:
      eventName = @"SubscriptionRestore";
      break;
    case SKPaymentTransactionStateDeferred:
      return;
  }

  double totalAmount = 0;
  if (product) {
    totalAmount = transaction.payment.quantity * product.price.doubleValue;
  }

  [self logImplicitTransactionEvent:eventName
                         valueToSum:totalAmount
                         parameters:[self getEventParametersOfProduct:product withTransaction:transaction]];
}

- (void)logImplicitPurchaseTransaction:(SKPaymentTransaction *)transaction
                             ofProduct:(SKProduct *)product
{
  NSString *eventName = nil;
  switch (transaction.transactionState) {
    case SKPaymentTransactionStatePurchasing:
      eventName = FBSDKAppEventNameInitiatedCheckout;
      break;
    case SKPaymentTransactionStatePurchased:
      eventName = FBSDKAppEventNamePurchased;
      break;
    case SKPaymentTransactionStateFailed:
      eventName = FBSDKAppEventNamePurchaseFailed;
      break;
    case SKPaymentTransactionStateRestored:
      eventName = FBSDKAppEventNamePurchaseRestored;
      break;
    case SKPaymentTransactionStateDeferred:
      return;
  }

  double totalAmount = 0;
  if (product) {
    totalAmount = transaction.payment.quantity * product.price.doubleValue;
  }

  [self logImplicitTransactionEvent:eventName
                         valueToSum:totalAmount
                         parameters:[self getEventParametersOfProduct:product withTransaction:transaction]];
}

- (void)logImplicitTransactionEvent:(FBSDKAppEventName)eventName
                         valueToSum:(double)valueToSum
                         parameters:(nullable NSDictionary<NSString *, id> *)parameters
{
  NSMutableDictionary<FBSDKAppEventParameterName, id> *eventParameters = [NSMutableDictionary dictionaryWithDictionary:parameters];

  if ([_eventsWithReceipt containsObject:eventName]) {
    NSData *receipt = [self fetchDeviceReceipt];
    if (receipt) {
      NSString *base64encodedReceipt = [receipt base64EncodedStringWithOptions:0];
      [FBSDKTypeUtility dictionary:eventParameters setObject:base64encodedReceipt forKey:@"receipt_data"];
    }
  }

  [FBSDKTypeUtility dictionary:eventParameters setObject:@"1" forKey:FBSDKAppEventParameterNameImplicitlyLoggedPurchase];
  [self.eventLogger logEvent:eventName
                  valueToSum:valueToSum
                  parameters:eventParameters];

  // Unless the behavior is set to only allow explicit flushing, we go ahead and flush, since purchase events
  // are relatively rare and relatively high value and worth getting across on wire right away.
  if ([self.eventLogger flushBehavior] != FBSDKAppEventsFlushBehaviorExplicitOnly) {
    [self.eventLogger flushForReason:FBSDKAppEventsFlushReasonEagerlyFlushingEvent];
  }
}

// Fetch the current receipt for this application.
- (NSData *)fetchDeviceReceipt
{
  NSURL *receiptURL = self.appStoreReceiptProvider.appStoreReceiptURL;
  NSData *receipt = [NSData dataWithContentsOfURL:receiptURL];
  return receipt;
}

@end
