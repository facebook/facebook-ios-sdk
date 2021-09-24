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

#if !TARGET_OS_TV

#import "FBSDKShareDialog.h"
#import "FBSDKShareInternalURLOpening.h"

@protocol FBSDKShareUtility;
@protocol FBSDKSocialComposeViewControllerFactory;

NS_ASSUME_NONNULL_BEGIN

@interface FBSDKShareDialog ()

@property (class, nullable, nonatomic) id<FBSDKShareInternalURLOpening> internalURLOpener;
@property (class, nullable, nonatomic) id<FBSDKInternalUtility> internalUtility;
@property (class, nullable, nonatomic) id<FBSDKSettings> settings;
@property (class, nullable, nonatomic) Class<FBSDKShareUtility> shareUtility;
@property (class, nullable, nonatomic) id<FBSDKBridgeAPIRequestCreating> bridgeAPIRequestFactory;
@property (class, nullable, nonatomic) id<FBSDKBridgeAPIRequestOpening> bridgeAPIRequestOpener;
@property (class, nullable, nonatomic) id<FBSDKSocialComposeViewControllerFactory> socialComposeViewControllerFactory;

@end

NS_ASSUME_NONNULL_END

#endif
