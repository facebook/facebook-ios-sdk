/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !TARGET_OS_TV

#import <UIKit/UIKit.h>

@protocol FBSDKWebDialogViewDelegate;
@protocol FBSDKWebViewProviding;

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(FBWebDialogView)
@interface FBSDKWebDialogView : UIView

@property (nonatomic, weak) id<FBSDKWebDialogViewDelegate> delegate;

- (void)loadURL:(NSURL *)URL;
- (void)stopLoading;

/**
 Internal method exposed to facilitate transition to Swift.
 API Subject to change or removal without warning. Do not use.

 @warning INTERNAL - DO NOT USE
 */
// UNCRUSTIFY_FORMAT_OFF
+ (void)configureWithWebViewProvider:(id<FBSDKWebViewProviding>)webViewProvider
                           urlOpener:(id<FBSDKInternalURLOpener>)urlOpener
                        errorFactory:(id<FBSDKErrorCreating>)errorFactory
NS_SWIFT_NAME(configure(webViewProvider:urlOpener:errorFactory:));
// UNCRUSTIFY_FORMAT_ON

@end

NS_SWIFT_NAME(WebDialogViewDelegate)
@protocol FBSDKWebDialogViewDelegate <NSObject>

- (void)webDialogView:(FBSDKWebDialogView *)webDialogView didCompleteWithResults:(NSDictionary<NSString *, id> *)results;
- (void)webDialogView:(FBSDKWebDialogView *)webDialogView didFailWithError:(NSError *)error;
- (void)webDialogViewDidCancel:(FBSDKWebDialogView *)webDialogView;
- (void)webDialogViewDidFinishLoad:(FBSDKWebDialogView *)webDialogView;

@end

NS_ASSUME_NONNULL_END

#endif
