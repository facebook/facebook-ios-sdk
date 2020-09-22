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

#import "FBSDKDeviceLoginViewController.h"

#import <FBSDKLoginKit/FBSDKDeviceLoginManager.h>

#ifdef FBSDKCOCOAPODS
 #import <FBSDKCoreKit/FBSDKCoreKit+Internal.h>
#else
 #import "FBSDKCoreKit+Internal.h"
#endif

@interface FBSDKDeviceLoginViewController () <
  FBSDKDeviceLoginManagerDelegate
>
@end

@implementation FBSDKDeviceLoginViewController
{
  FBSDKDeviceLoginManager *_loginManager;
  BOOL _isRetry;
}

- (void)viewDidDisappear:(BOOL)animated
{
  [super viewDidDisappear:animated];
  [self _cancel];
}

- (void)viewDidLoad
{
  [super viewDidLoad];

  [self _initializeLoginManager];
}

- (void)dealloc
{
  _loginManager.delegate = nil;
  _loginManager = nil;
}

#pragma mark - FBSDKDeviceLoginManagerDelegate

- (void)deviceLoginManager:(FBSDKDeviceLoginManager *)loginManager startedWithCodeInfo:(FBSDKDeviceLoginCodeInfo *)codeInfo
{
  ((FBSDKDeviceDialogView *)self.view).confirmationCode = codeInfo.loginCode;
}

- (void)deviceLoginManager:(FBSDKDeviceLoginManager *)loginManager completedWithResult:(FBSDKDeviceLoginManagerResult *)result error:(NSError *)error
{
  // Go ahead and clear the delegate to avoid double messaging (i.e., since we're dismissing
  // ourselves we don't want a didCancel (from viewDidDisappear) then didFinish.
  id<FBSDKDeviceLoginViewControllerDelegate> delegate = self.delegate;
  self.delegate = nil;

  FBSDKAccessToken *token = result.accessToken;
  BOOL requireConfirm = (([FBSDKServerConfigurationManager cachedServerConfiguration].smartLoginOptions & FBSDKServerConfigurationSmartLoginOptionsRequireConfirmation)
    && (token != nil)
    && !_isRetry);
  if (requireConfirm) {
    FBSDKGraphRequest *graphRequest = [[FBSDKGraphRequest alloc] initWithGraphPath:@"me"
                                                                        parameters:@{ @"fields" : @"name" }
                                                                       tokenString:token.tokenString
                                                                           version:nil
                                                                        HTTPMethod:@"GET"];
    [graphRequest startWithCompletionHandler:^(FBSDKGraphRequestConnection *connection, id graphResult, NSError *graphError) {
      dispatch_async(dispatch_get_main_queue(), ^{
        [self _presentConfirmationForDelegate:delegate
                                        token:result.accessToken
                                         name:graphResult[@"name"] ?: token.userID];
      });
    }];
  } else if ([self isNetworkError:error]) {
    NSString *networkErrorMessage = NSLocalizedStringWithDefaultValue(
      @"LoginError.SystemAccount.Network",
      @"FacebookSDK",
      [FBSDKInternalUtility bundleForStrings],
      @"Unable to connect to Facebook. Check your network connection and try again.",
      @"The user facing error message when the Accounts framework encounters a network error."
    );
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:networkErrorMessage preferredStyle:UIAlertControllerStyleAlert];
    NSString *localizedOK = NSLocalizedStringWithDefaultValue(
      @"ErrorRecovery.Alert.OK",
      @"FacebookSDK",
      [FBSDKInternalUtility bundleForStrings],
      @"OK",
      @"The title of the label to dismiss the alert when presenting user facing error messages"
    );
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:localizedOK
                                                       style:UIAlertActionStyleCancel
                                                     handler:^(UIAlertAction *_Nonnull action) {
                                                       [self dismissViewControllerAnimated:YES completion:^{
                                                         [delegate deviceLoginViewController:self didFailWithError:error];
                                                       }];
                                                     }];
    [alertController addAction:okAction];
    [self presentViewController:alertController animated:YES completion:nil];
  } else {
    [self dismissViewControllerAnimated:YES completion:^{
      if (result.isCancelled) {
        [self _cancel];
      } else if (token != nil) {
        [self _notifySuccessForDelegate:delegate token:token];
      } else {
        [delegate deviceLoginViewController:self didFailWithError:error];
      }
    }];
  }
}

- (BOOL)isNetworkError:(NSError *)error
{
  NSError *innerError = error.userInfo[NSUnderlyingErrorKey];
  if (innerError && [self isNetworkError:innerError]) {
    return YES;
  }
  switch (error.code) {
    case NSURLErrorTimedOut:
    case NSURLErrorCannotFindHost:
    case NSURLErrorCannotConnectToHost:
    case NSURLErrorNetworkConnectionLost:
    case NSURLErrorDNSLookupFailed:
    case NSURLErrorNotConnectedToInternet:
    case NSURLErrorInternationalRoamingOff:
    case NSURLErrorCallIsActive:
    case NSURLErrorDataNotAllowed:
      return YES;
    default:
      return NO;
  }
}

#pragma mark - Private impl

- (void)_notifySuccessForDelegate:(id<FBSDKDeviceLoginViewControllerDelegate>)delegate
                            token:(FBSDKAccessToken *)token
{
  [FBSDKAccessToken setCurrentAccessToken:token];
  [delegate deviceLoginViewControllerDidFinish:self];
}

- (void)_presentConfirmationForDelegate:(id<FBSDKDeviceLoginViewControllerDelegate>)delegate
                                  token:(FBSDKAccessToken *)token
                                   name:(NSString *)name
{
  NSString *title =
  NSLocalizedStringWithDefaultValue(
    @"SmartLogin.ConfirmationTitle",
    @"FacebookSDK",
    [FBSDKInternalUtility bundleForStrings],
    @"Confirm Login",
    @"The title for the alert when smart login requires confirmation"
  );
  NSString *cancelTitle =
  NSLocalizedStringWithDefaultValue(
    @"SmartLogin.NotYou",
    @"FacebookSDK",
    [FBSDKInternalUtility bundleForStrings],
    @"Not you?",
    @"The cancel label for the alert when smart login requires confirmation"
  );
  NSString *continueTitleFormatString =
  NSLocalizedStringWithDefaultValue(
    @"SmartLogin.Continue",
    @"FacebookSDK",
    [FBSDKInternalUtility bundleForStrings],
    @"Continue as %@",
    @"The format string to continue as <name> for the alert when smart login requires confirmation"
  );
  NSString *continueTitle = [NSString stringWithFormat:continueTitleFormatString, name];
  UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil
                                                                           message:title preferredStyle:UIAlertControllerStyleActionSheet];
  [alertController addAction:[UIAlertAction actionWithTitle:continueTitle
                                                      style:UIAlertActionStyleDestructive
                                                    handler:^(UIAlertAction *_Nonnull action) {
                                                      [self dismissViewControllerAnimated:YES completion:^{
                                                        [self _notifySuccessForDelegate:delegate token:token];
                                                      }];
                                                    }]];
  [alertController addAction:[UIAlertAction actionWithTitle:cancelTitle
                                                      style:UIAlertActionStyleCancel
                                                    handler:^(UIAlertAction *_Nonnull action) {
                                                      self->_isRetry = YES;
                                                      FBSDKDeviceDialogView *view = [[FBSDKDeviceDialogView alloc] initWithFrame:self.view.frame];
                                                      view.delegate = self;
                                                      self.view = view;
                                                      [self.view setNeedsDisplay];
                                                      [self _initializeLoginManager];
                                                      // reconnect delegate before since now
                                                      // we are not dismissing.
                                                      self.delegate = delegate;
                                                    }]];
  [self presentViewController:alertController animated:YES completion:NULL];
}

- (void)_initializeLoginManager
{
  // clear any existing login manager
  _loginManager.delegate = nil;
  [_loginManager cancel];
  _loginManager = nil;

  BOOL enableSmartLogin = (!_isRetry
    && ([FBSDKServerConfigurationManager cachedServerConfiguration].smartLoginOptions & FBSDKServerConfigurationSmartLoginOptionsEnabled));
  _loginManager = [[FBSDKDeviceLoginManager alloc] initWithPermissions:_permissions
                                                      enableSmartLogin:enableSmartLogin];
  _loginManager.delegate = self;
  _loginManager.redirectURL = self.redirectURL;
  [_loginManager start];
}

- (void)_cancel
{
  [_loginManager cancel];
  [self.delegate deviceLoginViewControllerDidCancel:self];
}

@end
