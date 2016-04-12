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

#import "FBSDKOrganicDeeplinkHelper.h"

#import <Foundation/Foundation.h>
#import <SafariServices/SafariServices.h>
#import <UIKit/UIKit.h>

#import "FBSDKApplicationDelegate+Internal.h"
#import "FBSDKDynamicFrameworkLoader.h"
#import "FBSDKInternalUtility.h"
#import "FBSDKSettings.h"


@interface FBSDKOrganicDeeplinkHelper () <
SFSafariViewControllerDelegate
>
@end

@implementation FBSDKOrganicDeeplinkHelper {
  UIWindow *_safariWindow;
  UIViewController *_safariViewController;
  FBSDKDeferredAppInviteHandler _handler;
}

- (bool)fetchOrganicDeeplink:(FBSDKDeferredAppInviteHandler) handler
{
  _handler = handler;

  // trying to dynamically load SFSafariViewController class
  // so for the cases when it is available we can send users through Safari View Controller flow
  // in cases it is not available regular flow will be selected
  Class SFSafariViewControllerClass = fbsdkdfl_SFSafariViewControllerClass();
  if(!SFSafariViewControllerClass) {
    return NO;
  }

  _safariWindow = [[UIWindow alloc] initWithFrame:[[[[UIApplication sharedApplication] delegate] window] bounds]];

  _safariWindow.windowLevel = UIWindowLevelNormal - 1;

  _safariWindow.rootViewController = [[UIViewController alloc] init];;
  [_safariWindow setHidden:NO];
  _safariViewController = [[SFSafariViewControllerClass alloc] initWithURL: [self constructDeeplinkRetrievalUrl]];
  dispatch_async(dispatch_get_main_queue(), ^{
    [FBSDKApplicationDelegate sharedInstance].organicDeeplinkHandler = handler;
    [self presentSafariViewController];

    // Dispatch a fallback handler call, if we get no response within 10 seconds.
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
      if([FBSDKApplicationDelegate sharedInstance].organicDeeplinkHandler)
      {
        [self cleanUpSafariViewController];
        [FBSDKApplicationDelegate sharedInstance].organicDeeplinkHandler = nil;
        _handler(nil);

      }
    });
  });

  return YES;
}

- (void)presentSafariViewController
{
  _safariViewController.view.userInteractionEnabled = NO;
  _safariViewController.view.alpha = 0;
  [_safariWindow.rootViewController addChildViewController:_safariViewController];
  [_safariWindow.rootViewController.view addSubview:_safariViewController.view];
  [_safariViewController performSelector:@selector(setDelegate:) withObject:self];
  [_safariViewController didMoveToParentViewController:_safariWindow.rootViewController];
  _safariViewController.view.frame = CGRectZero;
  return;
}

- (void)cleanUpSafariViewController
{
  if(_safariViewController)
  {
    [_safariViewController performSelector:@selector(setDelegate:) withObject:nil];
    [_safariViewController willMoveToParentViewController:nil];
    [_safariViewController.view removeFromSuperview];
    [_safariViewController removeFromParentViewController];
    _safariViewController = nil;
    _safariWindow.rootViewController = nil;
    _safariWindow = nil;
  }
  return;
}

- (NSURL*)constructDeeplinkRetrievalUrl
{
  NSString *appID = [FBSDKSettings appID];
  UIDevice* device = [UIDevice currentDevice];
  NSString* deviceName = @"default";

  switch (device.userInterfaceIdiom) {
    case UIUserInterfaceIdiomPad:
      deviceName = @"ipad";
      break;

    case UIUserInterfaceIdiomPhone:
      deviceName = @"iphone";
      break;

    case UIUserInterfaceIdiomTV:
      deviceName = @"tvos";
      break;

#if __IPHONE_9_3
    case UIUserInterfaceIdiomCarPlay:
#endif
    case UIUserInterfaceIdiomUnspecified:
      deviceName = @"unspecified";
      break;
  }

  NSMutableDictionary *parameters = [[NSMutableDictionary alloc] init];
  parameters[@"application_id"] = appID;
  parameters[@"device"] = deviceName;
  return [FBSDKInternalUtility facebookURLWithHostPrefix:@"m"
                                                    path:@"/deferreddeeplink/retrieve/"
                                         queryParameters:parameters
                                          defaultVersion: @""
                                                   error:nil];
}

#pragma mark - SFSafariViewControllerDelegate
- (void)safariViewController:(SFSafariViewController *)controller didCompleteInitialLoad:(BOOL)didLoadSuccessfully
{
  // Mark request as complete, Safari would redirect to url with correct deeplink or default uri.
  [self cleanUpSafariViewController];
}

@end
