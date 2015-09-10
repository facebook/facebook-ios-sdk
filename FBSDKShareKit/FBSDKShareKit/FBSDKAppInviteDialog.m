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

#import "FBSDKAppInviteDialog.h"

#import "FBSDKCoreKit+Internal.h"
#import "FBSDKShareConstants.h"
#import "FBSDKShareDefines.h"
#import "FBSDKShareError.h"
#import "FBSDKShareUtility.h"

@implementation FBSDKAppInviteDialog

#define FBSDK_APP_INVITE_METHOD_MIN_VERSION @"20140410"
#define FBSDK_APP_INVITE_METHOD_NAME @"appinvites"

+ (void)initialize
{
  if ([FBSDKAppInviteDialog class] == self) {
    [FBSDKInternalUtility checkRegisteredCanOpenURLScheme:FBSDK_CANOPENURL_FACEBOOK];
    // ensure that we have updated the dialog configs if we haven't already
    [FBSDKServerConfigurationManager loadServerConfigurationWithCompletionBlock:NULL];
  }
}

#pragma mark - Class Methods


+ (instancetype)showWithContent:(FBSDKAppInviteContent *)content delegate:(id<FBSDKAppInviteDialogDelegate>)delegate
{
  return [self showFromViewController:nil withContent:content delegate:delegate];
}

+ (instancetype)showFromViewController:(UIViewController *)viewController
                           withContent:(FBSDKAppInviteContent *)content
                              delegate:(id<FBSDKAppInviteDialogDelegate>)delegate;
{
  FBSDKAppInviteDialog *appInvite = [[self alloc] init];
  appInvite.content = content;
  appInvite.delegate = delegate;
  appInvite.fromViewController = viewController;
  [appInvite show];
  return appInvite;
}

#pragma mark - Public Methods

- (BOOL)canShow
{
  return YES;
}

- (BOOL)show
{
  NSError *error;
  if (![self canShow]) {
    error = [FBSDKShareError errorWithCode:FBSDKShareDialogNotAvailableErrorCode
                                   message:@"App invite dialog is not available."];
    [self _invokeDelegateDidFailWithError:error];
    return NO;
  }
  if (![self validateWithError:&error]) {
    [self _invokeDelegateDidFailWithError:error];
    return NO;
  }

  NSMutableDictionary *parameters = [[NSMutableDictionary alloc] init];
  [FBSDKInternalUtility dictionary:parameters setObject:self.content.appLinkURL forKey:@"app_link_url"];
  [FBSDKInternalUtility dictionary:parameters setObject:self.content.appInvitePreviewImageURL forKey:@"preview_image_url"];
  FBSDKBridgeAPIRequest *webBridgeRequest = [FBSDKBridgeAPIRequest bridgeAPIRequestWithProtocolType:FBSDKBridgeAPIProtocolTypeWeb
                                                                                             scheme:FBSDK_SHARE_JS_DIALOG_SCHEME
                                                                                         methodName:FBSDK_APP_INVITE_METHOD_NAME
                                                                                      methodVersion:nil
                                                                                         parameters:parameters
                                                                                           userInfo:nil];
  FBSDKBridgeAPICallbackBlock completionBlock = ^(FBSDKBridgeAPIResponse *response) {
    [self _handleCompletionWithDialogResults:response.responseParameters error:response.error];
  };

  [self _logDialogShow];

  FBSDKServerConfiguration *configuration = [FBSDKServerConfigurationManager cachedServerConfiguration];
  BOOL useSafariViewController = [configuration useSafariViewControllerForDialogName:FBSDKDialogConfigurationNameAppInvite];
  if ([self _canShowNative]) {
    FBSDKBridgeAPIRequest *nativeRequest = [FBSDKBridgeAPIRequest bridgeAPIRequestWithProtocolType:FBSDKBridgeAPIProtocolTypeNative
                                                                                            scheme:FBSDK_CANOPENURL_FACEBOOK
                                                                                        methodName:FBSDK_APP_INVITE_METHOD_NAME
                                                                                     methodVersion:FBSDK_APP_INVITE_METHOD_MIN_VERSION
                                                                                        parameters:parameters
                                                                                          userInfo:nil];
    void (^nativeCompletionBlock)(FBSDKBridgeAPIResponse *) = ^(FBSDKBridgeAPIResponse *response) {
      if (response.error.code == FBSDKAppVersionUnsupportedErrorCode) {
        [[FBSDKApplicationDelegate sharedInstance] openBridgeAPIRequest:webBridgeRequest
                                                useSafariViewController:useSafariViewController
                                                     fromViewController:self.fromViewController
                                                        completionBlock:completionBlock];
      } else {
        completionBlock(response);
      }
    };
    [[FBSDKApplicationDelegate sharedInstance] openBridgeAPIRequest:nativeRequest
                                            useSafariViewController:useSafariViewController
                                                 fromViewController:self.fromViewController
                                                    completionBlock:nativeCompletionBlock];
  } else {
    [[FBSDKApplicationDelegate sharedInstance] openBridgeAPIRequest:webBridgeRequest
                                            useSafariViewController:useSafariViewController
                                                 fromViewController:self.fromViewController
                                                    completionBlock:completionBlock];
  }
  return YES;
}

- (BOOL)validateWithError:(NSError *__autoreleasing *)errorRef
{
  return [FBSDKShareUtility validateAppInviteContent:self.content error:errorRef];
}

#pragma mark - Helper Methods

- (BOOL)_canShowNative
{
  FBSDKServerConfiguration *configuration = [FBSDKServerConfigurationManager cachedServerConfiguration];
  BOOL useNativeDialog = [configuration useNativeDialogForDialogName:FBSDKDialogConfigurationNameAppInvite];
  return (useNativeDialog && [FBSDKInternalUtility isFacebookAppInstalled]);
}

- (void)_handleCompletionWithDialogResults:(NSDictionary *)results error:(NSError *)error
{
  if (error) {
    [self _invokeDelegateDidFailWithError:error];
  } else {
    [self _invokeDelegateDidCompleteWithResults:results];
  }
}

- (void)_invokeDelegateDidCompleteWithResults:(NSDictionary *)results
{
  NSDictionary * parameters =@{
                               FBSDKAppEventParameterDialogOutcome : FBSDKAppEventsDialogOutcomeValue_Completed,
                               };

  [FBSDKAppEvents logImplicitEvent:FBSDKAppEventNameFBSDKEventAppInviteShareDialogResult
                        valueToSum:nil
                        parameters:parameters
                       accessToken:[FBSDKAccessToken currentAccessToken]];

  if (!_delegate) {
    return;
  }

  [_delegate appInviteDialog:self didCompleteWithResults:[results copy]];
}

- (void)_invokeDelegateDidFailWithError:(NSError *)error
{
  NSDictionary * parameters =@{
                               FBSDKAppEventParameterDialogOutcome : FBSDKAppEventsDialogOutcomeValue_Failed,
                               FBSDKAppEventParameterDialogErrorMessage : [NSString stringWithFormat:@"%@", error]
                               };

  [FBSDKAppEvents logImplicitEvent:FBSDKAppEventNameFBSDKEventAppInviteShareDialogResult
                        valueToSum:nil
                        parameters:parameters
                       accessToken:[FBSDKAccessToken currentAccessToken]];

  if (!_delegate) {
    return;
  }

  [_delegate appInviteDialog:self didFailWithError:error];
}

- (void)_logDialogShow
{
  [FBSDKAppEvents logImplicitEvent:FBSDKAppEventNameFBSDKEventAppInviteShareDialogShow
                        valueToSum:nil
                        parameters:nil
                       accessToken:[FBSDKAccessToken currentAccessToken]];
}

@end
