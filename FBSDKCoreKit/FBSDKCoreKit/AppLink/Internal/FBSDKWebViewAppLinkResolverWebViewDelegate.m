/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !TARGET_OS_TV

#import "FBSDKWebViewAppLinkResolverWebViewDelegate.h"

#import <WebKit/WebKit.h>

NS_ASSUME_NONNULL_BEGIN

@implementation FBSDKWebViewAppLinkResolverWebViewDelegate

- (void)webView:(WKWebView *)webView didFinishNavigation:(null_unspecified WKNavigation *)navigation
{
  if (self.didFinishLoad) {
    self.didFinishLoad(webView);
  }
}

- (void)    webView:(WKWebView *)webView
  didFailNavigation:(null_unspecified WKNavigation *)navigation
          withError:(NSError *)error
{
  if (self.didFailLoadWithError) {
    self.didFailLoadWithError(webView, error);
  }
}

- (void)                  webView:(WKWebView *)webView
  decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction
                  decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler
{
  if (self.hasLoaded) {
    self.didFinishLoad(webView);
    decisionHandler(WKNavigationActionPolicyCancel);
  } else {
    self.hasLoaded = YES;
    decisionHandler(WKNavigationActionPolicyAllow);
  }
}

@end

NS_ASSUME_NONNULL_END

#endif
