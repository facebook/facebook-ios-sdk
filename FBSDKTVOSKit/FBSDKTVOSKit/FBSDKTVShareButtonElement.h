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

#import <FBSDKTVOSKit/FBSDKDeviceLoginButton.h>

#import <TVMLKit/TVViewElement.h>

NS_ASSUME_NONNULL_BEGIN

/*!
 @abstract Represents a <FBSDKShareButton /> tag in TVML. Requires FBSDKShareKit.framework to be linked.
 @discussion You should not need to use this class directly. Instead, make sure you
 initialize a `FBSDKTVInterfaceFactory` instance correctly.

 The '<FBSDKShareButton />' tag must also have the following attributes to define
  the share content:
 - `href` the url to share; or,
 - `action_type` and `object_url` and `key` where `action_type` is the Open Graph action type
 and `object_url` is a url that supports Open Graph and `key` is the Open Graph object name (see `FBSDKShareOpenGraphAction`).

 Examples:
 @code
 <FBSDKShareButton href="http://developers.facebook.com/docs/tvos/tvml" />

 <FBSDKShareButton action_type="video.watches" object_url="http://samples.ogp.me/453907197960619" key="movie"/>

 */
@interface FBSDKTVShareButtonElement : TVViewElement

@end

NS_ASSUME_NONNULL_END
