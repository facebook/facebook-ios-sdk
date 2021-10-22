/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !TARGET_OS_TV

#import <UIKit/UIKit.h>

@protocol FBSDKWebDialogViewDelegate;
@protocol FBSDKWebViewProviding;
@protocol FBSDKInternalURLOpener;

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(FBWebDialogView)
@interface FBSDKWebDialogView : UIView

@property (nonatomic, weak) id<FBSDKWebDialogViewDelegate> delegate;

+ (void)configureWithWebViewProvider:(id<FBSDKWebViewProviding>)provider
                           urlOpener:(id<FBSDKInternalURLOpener>)urlOpener;

- (void)loadURL:(NSURL *)URL;
- (void)stopLoading;

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
