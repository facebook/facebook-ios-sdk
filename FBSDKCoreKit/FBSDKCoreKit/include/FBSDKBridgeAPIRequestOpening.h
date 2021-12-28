/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !TARGET_OS_TV

#import <Foundation/Foundation.h>
#import <UIKit/UIViewController.h>

#import <FBSDKCoreKit/FBSDKBridgeAPIResponse.h>
#import <FBSDKCoreKit/FBSDKConstants.h>

@protocol FBSDKBridgeAPIRequest;
@protocol FBSDKURLOpening;

NS_ASSUME_NONNULL_BEGIN

/**
 Internal Type exposed to facilitate transition to Swift.
 API Subject to change or removal without warning. Do not use.

 @warning INTERNAL - DO NOT USE
 */
NS_SWIFT_NAME(BridgeAPIRequestOpening)
@protocol FBSDKBridgeAPIRequestOpening <NSObject>

- (void)openBridgeAPIRequest:(NSObject<FBSDKBridgeAPIRequest> *)request
     useSafariViewController:(BOOL)useSafariViewController
          fromViewController:(nullable UIViewController *)fromViewController
             completionBlock:(FBSDKBridgeAPIResponseBlock)completionBlock;

// UNCRUSTIFY_FORMAT_OFF
- (void)openURLWithSafariViewController:(NSURL *)url
                                 sender:(nullable id<FBSDKURLOpening>)sender
                     fromViewController:(nullable UIViewController *)fromViewController
                                handler:(FBSDKSuccessBlock)handler
NS_SWIFT_NAME(openURLWithSafariViewController(url:sender:from:handler:));
// UNCRUSTIFY_FORMAT_ON

- (void)openURL:(NSURL *)url
         sender:(nullable id<FBSDKURLOpening>)sender
        handler:(FBSDKSuccessBlock)handler;
@end

NS_ASSUME_NONNULL_END

#endif
