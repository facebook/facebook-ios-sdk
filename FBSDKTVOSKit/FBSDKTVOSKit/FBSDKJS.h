/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <Foundation/Foundation.h>
#import <JavaScriptCore/JavaScriptCore.h>

#import <FBSDKCoreKit/FBSDKCoreKit.h>

NS_ASSUME_NONNULL_BEGIN

/**
 Marker protocol to export native functions to Javascript contexts.
 see `FBSDKJS` for integration in TVML apps.
 */
NS_SWIFT_NAME(JSExports)
@protocol FBSDKJSExports <JSExport>

/// Returns the current access token string, if available.
@property (class, nullable, nonatomic, readonly, copy) NSString *accessTokenString;

/// returns true if there is a current access token.
@property (class, nonatomic, readonly, getter = isLoggedIn, assign) BOOL loggedIn;

/// Returns true if there is a current access token and the permission has been granted.

// UNCRUSTIFY_FORMAT_OFF
+ (BOOL)hasGranted:(NSString *)permission
NS_SWIFT_NAME(hasGranted(permission:));
// UNCRUSTIFY_FORMAT_ON

/**
 Log an event for analytics. In TVJS this is defined as `FBSDKJS.logEventParameters(...)`.
 @param eventName the event name
 See `FBSDKAppEvents logEvent:parameters:`.
 */
+ (void)logEvent:(FBSDKAppEventName)eventName;

/**
 Log an event for analytics. In TVJS this is defined as `FBSDKJS.logEventParameters(...)`.
 @param eventName the event name
 @param parameters the parameters (optional).
 See `FBSDKAppEvents logEvent:parameters:`.
 */
+ (void)logEvent:(FBSDKAppEventName)eventName parameters:(nullable NSDictionary<FBSDKAppEventParameterName, id> *)parameters;

/**
 Log an event for analytics. In TVJS this is defined as `FBSDKJS.logPurchaseCurrencyParameters(...)`.
 @param purchaseAmount the purchase amount
 @param currency the currency, e.g, "USD"
 See `FBSDKAppEvents logPurchase:currency:parameters:`.
 */
+ (void)logPurchase:(double)purchaseAmount currency:(NSString *)currency;

/**
 Log an event for analytics. In TVJS this is defined as `FBSDKJS.logPurchaseCurrencyParameters(...)`.
 @param purchaseAmount the purchase amount
 @param currency the currency, e.g, "USD"
 @param parameters additional parameters (optional).
 See `FBSDKAppEvents logPurchase:currency:parameters:`.
 */
+ (void)logPurchase:(double)purchaseAmount
           currency:(NSString *)currency
         parameters:(nullable NSDictionary<FBSDKAppEventParameterName, id> *)parameters;

@end

/**
 Utility class to export common native functions to Javascript contexts.
 You should connect this to your `TVApplicationControllerDelegate`. For example,
 <code>
   func appController(appController: TVApplicationController, evaluateAppJavaScriptInContext jsContext: JSContext) {
     // Add the TVML/TVJS extensions for FBSDK
     jsContext.setObject(FBSDKJS.self, forKeyedSubscript: "FBSDKJS")
   }
 </code>

 Then your TVJS scripts can call functions like `FBSDKJS.hasLoggedIn()` to conditionally perform work
 if the user is logged in.
 */
NS_SWIFT_NAME(JS)
@interface FBSDKJS : NSObject <FBSDKJSExports>

@end

NS_ASSUME_NONNULL_END
