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

#import "AppDelegate.h"

#import <Bolts/Bolts.h>

#import <FBSDKCoreKit/FBSDKCoreKit.h>

#import <FBSDKShareKit/FBSDKShareKit.h>

#import "GameViewController.h"

@implementation AppDelegate

#pragma mark - Class Methods

+ (void)initialize
{
  [BFAppLinkReturnToRefererView class];
  [FBSDKSendButton class];
  [FBSDKShareButton class];
}

#pragma mark - Application Lifecycle

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
  [[FBSDKApplicationDelegate sharedInstance] application:application didFinishLaunchingWithOptions:launchOptions];
  return YES;
}

- (BOOL)application:(UIApplication *)application
            openURL:(NSURL *)url
            options:(nonnull NSDictionary<UIApplicationOpenURLOptionsKey,id> *)options
{
  return [self application:application
                   openURL:url
         sourceApplication:options[UIApplicationOpenURLOptionsSourceApplicationKey]
                annotation:options[UIApplicationOpenURLOptionsAnnotationKey]];
}

// Still need this for iOS8
- (BOOL)application:(UIApplication *)application
            openURL:(NSURL *)url
  sourceApplication:(nullable NSString *)sourceApplication
         annotation:(nonnull id)annotation
{
  if ([[FBSDKApplicationDelegate sharedInstance] application:application
                                                     openURL:url
                                           sourceApplication:sourceApplication
                                                  annotation:annotation]) {
    return YES;
  }
  if ([self _handleAppLink:url sourceApplication:sourceApplication]) {
    return YES;
  }
  return NO;
}

#pragma mark - Helper Methods

- (GameViewController *)_gameViewController
{
  UIViewController *rootViewController = self.window.rootViewController;
  return ([rootViewController isKindOfClass:[GameViewController class]] ?
          (GameViewController *)rootViewController :
          nil);
}



- (BOOL)_handleAppLink:(NSURL *)url sourceApplication:(NSString *)sourceApplication
{
  BFURL *appLinkURL = [BFURL URLWithInboundURL:url sourceApplication:sourceApplication];
  NSURL *inputURL = appLinkURL.inputURL;
  return ([inputURL.scheme.lowercaseString isEqualToString:@"iconicus"] &&
          [inputURL.host.lowercaseString isEqualToString:@"game"] &&
          [[self _gameViewController] loadGameFromAppLinkURL:appLinkURL]);
}

@end
