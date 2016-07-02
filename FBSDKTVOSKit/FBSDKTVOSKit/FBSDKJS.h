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

#import <Foundation/Foundation.h>
#import <JavaScriptCore/JavaScriptCore.h>

NS_ASSUME_NONNULL_BEGIN

/*!
 @abstract Marker protocol to export native functions to Javascript contexts.
 @discussion see `FBSDKJS` for integration in TVML apps.
 */
@protocol FBSDKJSExports <JSExport>

/*!
 @abstract Returns the current access token string, if available.
 */
+ (nullable NSString *)accessTokenString;

/*!
 @abstract Returns true if there is a current access token and the permission has been granted.
 */
+ (BOOL)hasGranted:(NSString *)permission;

/*!
 @abstract returns true if there is a current access token.
 */
+ (BOOL)isLoggedIn;

/*!
 @abstract Log an event for analytics. In TVJS this is defined as `FBSDKJS.logEventParameters(...)`.
 @param eventName the event name
 @param parameters the parameters (optional).
 @discussion See `FBSDKAppEvents logEvent:parameters:`.
 */
+ (void)logEvent:(NSString *)eventName parameters:(nullable NSDictionary<NSString *, id> *)parameters;

/*!
 @abstract Log an event for analytics. In TVJS this is defined as `FBSDKJS.logPurchaseCurrencyParameters(...)`.
 @param purchaseAmount the purchase amount
 @param currency the currency, e.g, "USD"
 @param parameters additional parameters (optional).
 @discussion See `FBSDKAppEvents logPurchase:currency:parameters:`.
 */
+ (void)logPurchase:(double)purchaseAmount currency:(NSString *)currency parameters:(nullable NSDictionary<NSString *, id> *)parameters;

@end

/*!
 @abstract Utility class to export common native functions to Javascript contexts.
 @discussion You should connect this to your `TVApplicationControllerDelegate`. For example,
 <code>
   func appController(appController: TVApplicationController, evaluateAppJavaScriptInContext jsContext: JSContext) {
     // Add the TVML/TVJS extensions for FBSDK
     jsContext.setObject(FBSDKJS.self, forKeyedSubscript: "FBSDKJS")
   }
 </code>

 Then your TVJS scripts can call functions like `FBSDKJS.hasLoggedIn()` to conditionally perform work
 if the user is logged in.
 */
@interface FBSDKJS : NSObject <FBSDKJSExports>

@end

NS_ASSUME_NONNULL_END
