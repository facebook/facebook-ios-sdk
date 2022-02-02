/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !TARGET_OS_TV

#import <Foundation/Foundation.h>
#import <UIKit/UIImage.h>

NS_ASSUME_NONNULL_BEGIN

/**
 Service type for creating social compose view controllers.  There was a symbol
 in the Social framework named `SLServiceTypeFacebook` that was deprecated
 in iOS 11.  This constant replaces that deprecated symbol.

 Internal symbol exposed to facilitate transition to Swift.
 API Subject to change or removal without warning. Do not use.

 @warning INTERNAL - DO NOT USE
 */
FOUNDATION_EXPORT NSString *const _FBSDKSocialComposeServiceType;

/**
 Compose view controller result type to mirror the
 `SLComposeViewControllerResult` type in the Social framework.

 Internal Type exposed to facilitate transition to Swift.
 API Subject to change or removal without warning. Do not use.

 @warning INTERNAL - DO NOT USE
 */
typedef NS_ENUM(NSInteger, _FBSDKSocialComposeViewControllerResult) {
  FBSDKSocialComposeViewControllerResultCancelled,
  FBSDKSocialComposeViewControllerResultDone,
};

/**
 Compose view controller completion handler to mirror the
 `SLComposeViewControllerCompletionHandler` type in the Social framework.

 Internal Type exposed to facilitate transition to Swift.
 API Subject to change or removal without warning. Do not use.

 @warning INTERNAL - DO NOT USE
 */
typedef void (^_FBSDKSocialComposeViewControllerCompletionHandler)(_FBSDKSocialComposeViewControllerResult result);

/**
 Compose view controller interface to provide an abstraction on top of the
 `SLComposeViewController` type in the Social framework.

 Internal Type exposed to facilitate transition to Swift.
 API Subject to change or removal without warning. Do not use.

 @warning INTERNAL - DO NOT USE
 */
NS_SWIFT_NAME(_SocialComposeViewControllerProtocol)
@protocol _FBSDKSocialComposeViewController <NSObject>

@property (nonatomic, copy) _FBSDKSocialComposeViewControllerCompletionHandler completionHandler;

- (BOOL)setInitialText:(NSString *)text;
- (BOOL)addImage:(UIImage *)image;
- (BOOL)addURL:(NSURL *)url;

@end

NS_ASSUME_NONNULL_END

#endif
