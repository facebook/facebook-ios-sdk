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
