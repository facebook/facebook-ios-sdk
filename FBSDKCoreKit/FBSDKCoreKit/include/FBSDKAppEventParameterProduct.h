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

/**
 @methodgroup Predefined event name parameters for common additional information to accompany events logged through the `logProductItem` method on `FBSDKAppEvents`.
 */

/// typedef for FBSDKAppEventParameterProduct
typedef NSString *const FBSDKAppEventParameterProduct NS_TYPED_EXTENSIBLE_ENUM NS_SWIFT_NAME(AppEvents.ParameterProduct);

/** Parameter key used to specify the product item's category. */
FOUNDATION_EXPORT FBSDKAppEventParameterProduct FBSDKAppEventParameterProductCategory;

/** Parameter key used to specify the product item's custom label 0. */
FOUNDATION_EXPORT FBSDKAppEventParameterProduct FBSDKAppEventParameterProductCustomLabel0;

/** Parameter key used to specify the product item's custom label 1. */
FOUNDATION_EXPORT FBSDKAppEventParameterProduct FBSDKAppEventParameterProductCustomLabel1;

/** Parameter key used to specify the product item's custom label 2. */
FOUNDATION_EXPORT FBSDKAppEventParameterProduct FBSDKAppEventParameterProductCustomLabel2;

/** Parameter key used to specify the product item's custom label 3. */
FOUNDATION_EXPORT FBSDKAppEventParameterProduct FBSDKAppEventParameterProductCustomLabel3;

/** Parameter key used to specify the product item's custom label 4. */
FOUNDATION_EXPORT FBSDKAppEventParameterProduct FBSDKAppEventParameterProductCustomLabel4;

/** Parameter key used to specify the product item's AppLink app URL for iOS. */
FOUNDATION_EXPORT FBSDKAppEventParameterProduct FBSDKAppEventParameterProductAppLinkIOSUrl;

/** Parameter key used to specify the product item's AppLink app ID for iOS App Store. */
FOUNDATION_EXPORT FBSDKAppEventParameterProduct FBSDKAppEventParameterProductAppLinkIOSAppStoreID;

/** Parameter key used to specify the product item's AppLink app name for iOS. */
FOUNDATION_EXPORT FBSDKAppEventParameterProduct FBSDKAppEventParameterProductAppLinkIOSAppName;

/** Parameter key used to specify the product item's AppLink app URL for iPhone. */
FOUNDATION_EXPORT FBSDKAppEventParameterProduct FBSDKAppEventParameterProductAppLinkIPhoneUrl;

/** Parameter key used to specify the product item's AppLink app ID for iPhone App Store. */
FOUNDATION_EXPORT FBSDKAppEventParameterProduct FBSDKAppEventParameterProductAppLinkIPhoneAppStoreID;

/** Parameter key used to specify the product item's AppLink app name for iPhone. */
FOUNDATION_EXPORT FBSDKAppEventParameterProduct FBSDKAppEventParameterProductAppLinkIPhoneAppName;

/** Parameter key used to specify the product item's AppLink app URL for iPad. */
FOUNDATION_EXPORT FBSDKAppEventParameterProduct FBSDKAppEventParameterProductAppLinkIPadUrl;

/** Parameter key used to specify the product item's AppLink app ID for iPad App Store. */
FOUNDATION_EXPORT FBSDKAppEventParameterProduct FBSDKAppEventParameterProductAppLinkIPadAppStoreID;

/** Parameter key used to specify the product item's AppLink app name for iPad. */
FOUNDATION_EXPORT FBSDKAppEventParameterProduct FBSDKAppEventParameterProductAppLinkIPadAppName;

/** Parameter key used to specify the product item's AppLink app URL for Android. */
FOUNDATION_EXPORT FBSDKAppEventParameterProduct FBSDKAppEventParameterProductAppLinkAndroidUrl;

/** Parameter key used to specify the product item's AppLink fully-qualified package name for intent generation. */
FOUNDATION_EXPORT FBSDKAppEventParameterProduct FBSDKAppEventParameterProductAppLinkAndroidPackage;

/** Parameter key used to specify the product item's AppLink app name for Android. */
FOUNDATION_EXPORT FBSDKAppEventParameterProduct FBSDKAppEventParameterProductAppLinkAndroidAppName;

/** Parameter key used to specify the product item's AppLink app URL for Windows Phone. */
FOUNDATION_EXPORT FBSDKAppEventParameterProduct FBSDKAppEventParameterProductAppLinkWindowsPhoneUrl;

/** Parameter key used to specify the product item's AppLink app ID, as a GUID, for App Store. */
FOUNDATION_EXPORT FBSDKAppEventParameterProduct FBSDKAppEventParameterProductAppLinkWindowsPhoneAppID;

/** Parameter key used to specify the product item's AppLink app name for Windows Phone. */
FOUNDATION_EXPORT FBSDKAppEventParameterProduct FBSDKAppEventParameterProductAppLinkWindowsPhoneAppName;
