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

NS_ASSUME_NONNULL_BEGIN

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_10_0

/*!
 @abstract The error domain for all errors from FBSDKTVOSKit.
 @discussion Error codes from the SDK in the range 400-499 are reserved for this domain.
 */
FOUNDATION_EXPORT NSErrorDomain const FBSDKTVOSErrorDomain
NS_SWIFT_NAME(TVOSErrorDomain);

#else

/*!
 @abstract The error domain for all errors from FBSDKTVOSKit.
 @discussion Error codes from the SDK in the range 400-499 are reserved for this domain.
 */
FOUNDATION_EXPORT NSString *const FBSDKTVOSErrorDomain
NS_SWIFT_NAME(TVOSErrorDomain);

#endif

/*!
 FBSDKTVOSError
 @abstract Error codes for FBSDKTVOSErrorDomain.
 */
typedef NS_ERROR_ENUM(FBSDKTVOSErrorDomain, FBSDKTVOSError)
{
  /*!
   @abstract Reserved.
   */
  FBSDKTVOSErrorReserved = 400,

  /*!
   @abstract The error code for unknown errors.
   */
  FBSDKTVOSErrorUnknown,
} NS_SWIFT_NAME(TVOSError);

NS_ASSUME_NONNULL_END
