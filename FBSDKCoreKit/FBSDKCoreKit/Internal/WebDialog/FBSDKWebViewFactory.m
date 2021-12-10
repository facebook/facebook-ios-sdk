/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !TARGET_OS_TV

#import "FBSDKWebViewFactory.h"

#import "WKWebView+WebViewProtocol.h"

@protocol FBSDKWebView;

@implementation FBSDKWebViewFactory

- (nonnull id<FBSDKWebView>)createWebViewWithFrame:(CGRect)frame
{
  return [[WKWebView alloc] initWithFrame:frame];
}

@end

#endif
