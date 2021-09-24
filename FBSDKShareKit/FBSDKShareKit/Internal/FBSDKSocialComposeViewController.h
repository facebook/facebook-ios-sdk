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

 #import <Foundation/Foundation.h>
 #import <UIKit/UIImage.h>

NS_ASSUME_NONNULL_BEGIN

/**
 Service type for creating social compose view controllers.  There was a symbol
 in the Social framework named `SLServiceTypeFacebook` that was deprecated
 in iOS 11.  This constant replaces that deprecated symbol.
 */
FOUNDATION_EXPORT NSString *const FBSDKSocialComposeServiceType;

/**
 Compose view controller result type to mirror the
 `SLComposeViewControllerResult` type in the Social framework.
 */
typedef NS_ENUM(NSInteger, FBSDKSocialComposeViewControllerResult) {
  FBSDKSocialComposeViewControllerResultCancelled,
  FBSDKSocialComposeViewControllerResultDone,
};

/**
 Compose view controller completion handler to mirror the
 `SLComposeViewControllerCompletionHandler` type in the Social framework.
 */
typedef void (^FBSDKSocialComposeViewControllerCompletionHandler)(FBSDKSocialComposeViewControllerResult result);

/**
 Compose view controller interface to provide an abstraction on top of the
 `SLComposeViewController` type in the Social framework.
 */
NS_SWIFT_NAME(SocialComposeViewControllerProtocol)
@protocol FBSDKSocialComposeViewController <NSObject>

@property (nonatomic, copy) FBSDKSocialComposeViewControllerCompletionHandler completionHandler;

- (BOOL)setInitialText:(NSString *)text;
- (BOOL)addImage:(UIImage *)image;
- (BOOL)addURL:(NSURL *)url;

@end

NS_ASSUME_NONNULL_END

#endif
