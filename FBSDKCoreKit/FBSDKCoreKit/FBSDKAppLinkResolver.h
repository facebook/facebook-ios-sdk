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

#import "FBSDKAppLinkResolving.h"

NS_ASSUME_NONNULL_BEGIN

/**

  Provides an implementation of the FBSDKAppLinkResolving protocol that uses the Facebook App Link
 Index API to resolve App Links given a URL. It also provides an additional helper method that can resolve
 multiple App Links in a single call.

 Usage of this type requires a client token. See `[FBSDKSettings setClientToken:]`
 */

@interface FBSDKAppLinkResolver : NSObject<FBSDKAppLinkResolving>

/**
 Asynchronously resolves App Link data for a given array of URLs.

 @param urls The URLs to resolve into an App Link.
 @param handler The completion block that will return an App Link for the given URL.
 */
- (void)appLinksFromURLs:(NSArray<NSURL *> *)urls handler:(FBSDKAppLinksFromURLArrayHandler)handler
NS_EXTENSION_UNAVAILABLE_IOS("Not available in app extension");

/**
  Allocates and initializes a new instance of FBSDKAppLinkResolver.
 */
+ (instancetype)resolver;

@end

NS_ASSUME_NONNULL_END
