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

#import "FBSDKCoreKit+Internal.h"

typedef NS_ENUM(NSUInteger, FBSDKTVOSErrorSubcode) {
  /**
   Your device is polling too frequently.
   */
  FBSDKTVOSExcessivePollingErrorSubcode = 1349172,
  /**
   User has declined to authorize your application.
   */
  FBSDKTVOSAuthorizationDeclinedErrorSubcode = 1349173,
  /**
   User has not yet authorized your application. Continue polling.
   */
  FBSDKTVOSAuthorizationPendingErrorSubcode = 1349174,
  /**
   The code you entered has expired.
   */
  FBSDKTVOSCodeExpiredErrorSubcode = 1349152
};

NS_ASSUME_NONNULL_BEGIN

@interface FBSDKTVOSError : FBSDKError

@end

NS_ASSUME_NONNULL_END
