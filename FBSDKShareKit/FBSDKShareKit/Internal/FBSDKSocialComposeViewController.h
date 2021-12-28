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
