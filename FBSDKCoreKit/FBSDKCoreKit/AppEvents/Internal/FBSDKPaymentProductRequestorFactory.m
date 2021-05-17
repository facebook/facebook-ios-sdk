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

#import "FBSDKPaymentProductRequestorFactory.h"

#import "FBSDKAppEvents+EventLogging.h"
#import "FBSDKAppStoreReceiptProviding.h"
#import "FBSDKGateKeeperManager.h"
#import "FBSDKGateKeeperManaging.h"
#import "FBSDKLoggerFactory.h"
#import "FBSDKPaymentProductRequestor.h"
#import "FBSDKProductRequestFactory.h"
#import "FBSDKProductsRequestProtocols.h"
#import "FBSDKSettings+Internal.h"
#import "FBSDKSettings+SettingsProtocols.h"
#import "NSUserDefaults+FBSDKDataPersisting.h"

@interface FBSDKPaymentProductRequestorFactory ()

@property (nonatomic, readonly) id<FBSDKSettings> settings;
@property (nonatomic, readonly) id<FBSDKEventLogging> eventLogger;
@property (nullable, nonatomic) Class<FBSDKGateKeeperManaging> gateKeeperManager;
@property (nullable, nonatomic) id<FBSDKDataPersisting> store;
@property (nullable, nonatomic) id<FBSDKLoggingCreating> loggerFactory;
@property (nonatomic, readonly) id<FBSDKProductsRequestCreating> productsRequestFactory;
@property (nonatomic, readonly) id<FBSDKAppStoreReceiptProviding> appStoreReceiptProvider;

@end

@implementation FBSDKPaymentProductRequestorFactory

- (instancetype)init
{
  return [self initWithSettings:FBSDKSettings.sharedSettings
                      eventLogger:FBSDKAppEvents.singleton
                gateKeeperManager:FBSDKGateKeeperManager.class
                            store:NSUserDefaults.standardUserDefaults
                    loggerFactory:[FBSDKLoggerFactory new]
           productsRequestFactory:[FBSDKProductRequestFactory new]
          appStoreReceiptProvider:[NSBundle bundleForClass:self.class]];
}

- (instancetype)initWithSettings:(id<FBSDKSettings>)settings
                     eventLogger:(id<FBSDKEventLogging>)eventLogger
               gateKeeperManager:(Class<FBSDKGateKeeperManaging>)gateKeeperManager
                           store:(id<FBSDKDataPersisting>)store
                   loggerFactory:(id<FBSDKLoggingCreating>)loggerFactory
          productsRequestFactory:(id<FBSDKProductsRequestCreating>)productsRequestFactory
         appStoreReceiptProvider:(id<FBSDKAppStoreReceiptProviding>)receiptProvider
{
  if ((self = [super init])) {
    _settings = settings;
    _eventLogger = eventLogger;
    _gateKeeperManager = gateKeeperManager;
    _store = store;
    _loggerFactory = loggerFactory;
    _productsRequestFactory = productsRequestFactory;
    _appStoreReceiptProvider = receiptProvider;
  }

  return self;
}

- (nonnull FBSDKPaymentProductRequestor *)createRequestorWithTransaction:(SKPaymentTransaction *)transaction
{
  return [[FBSDKPaymentProductRequestor alloc] initWithTransaction:transaction
                                                          settings:self.settings
                                                       eventLogger:self.eventLogger
                                                 gateKeeperManager:self.gateKeeperManager
                                                             store:self.store
                                                     loggerFactory:self.loggerFactory
                                            productsRequestFactory:self.productsRequestFactory
                                           appStoreReceiptProvider:self.appStoreReceiptProvider];
}

@end
