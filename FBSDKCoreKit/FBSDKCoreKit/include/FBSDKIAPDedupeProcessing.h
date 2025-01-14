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
NS_SWIFT_NAME(_IAPDedupeProcessing)
@protocol FBSDKIAPDedupeProcessing

@property (readonly, assign) BOOL isEnabled;
- (void)enable;
- (void)disable;
- (void)saveNonProcessedEvents;
- (void)processSavedEvents;
- (void)processManualEvent:(FBSDKAppEventName)eventName
          valueToSum:(nullable NSNumber *)valueToSum
          parameters:(nullable NSDictionary<FBSDKAppEventParameterName, id> *)parameters
               accessToken:(nullable FBSDKAccessToken *)accessToken
     operationalParameters:(nullable NSDictionary<FBSDKAppOperationalDataType, NSDictionary<NSString *, id> *> *)operationalParameters;
- (void)processImplicitEvent:(FBSDKAppEventName)eventName
          valueToSum:(nullable NSNumber *)valueToSum
          parameters:(nullable NSDictionary<FBSDKAppEventParameterName, id> *)parameters
                 accessToken:(nullable FBSDKAccessToken *)accessToken
       operationalParameters:(nullable NSDictionary<FBSDKAppOperationalDataType, NSDictionary<NSString *, id> *> *)operationalParameters;
- (BOOL)shouldDedupeEvent:(FBSDKAppEventName)eventName
               valueToSum:(nullable NSNumber *)valueToSum
               parameters:(nullable NSDictionary<FBSDKAppEventParameterName, id> *)parameters;

@end

NS_ASSUME_NONNULL_END
