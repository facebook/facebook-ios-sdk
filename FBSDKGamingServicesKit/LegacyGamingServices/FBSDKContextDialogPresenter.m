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

#import "TargetConditionals.h"

#if !TARGET_OS_TV

 #import "FBSDKContextDialogPresenter.h"

 #import "FBSDKChooseContextContent.h"
 #import "FBSDKChooseContextDialog.h"
 #import "FBSDKCreateContextDialog.h"
 #import "FBSDKDialogProtocol.h"
 #import "FBSDKGamingContext.h"
 #import "FBSDKGamingServicesCoreKitImport.h"
 #import "FBSDKSwitchContextDialog.h"

@interface FBSDKInternalUtility () <FBSDKWindowFinding>
@end

@interface FBSDKContextDialogPresenter ()

@property (nonatomic) FBSDKWebDialog *webDialog;

@end

@implementation FBSDKContextDialogPresenter

 #pragma mark - Class Methods

+ (nullable FBSDKCreateContextDialog *)createContextDialogWithContent:(FBSDKCreateContextContent *)content delegate:(id<FBSDKContextDialogDelegate>)delegate
{
  if (![FBSDKAccessToken currentAccessToken]) {
    return nil;
  }
  FBSDKCreateContextDialog *dialog = [FBSDKCreateContextDialog dialogWithContent:content
                                                                    windowFinder:FBSDKInternalUtility.sharedUtility
                                                                        delegate:delegate];
  return dialog;
}

+ (nullable NSError *)showCreateContextDialogWithContent:(FBSDKCreateContextContent *)content delegate:(id<FBSDKContextDialogDelegate>)delegate
{
  FBSDKCreateContextDialog *dialog = [self createContextDialogWithContent:content delegate:delegate];
  if (dialog) {
    [dialog show];
    return nil;
  }
  NSError *tokenError = [FBSDKError
                         errorWithCode:FBSDKErrorAccessTokenRequired
                         message:@"A valid access token is required to launch the Dialog"];
  return tokenError;
}

+ (nullable FBSDKSwitchContextDialog *)switchContextDialogWithContent:(FBSDKSwitchContextContent *)content delegate:(id<FBSDKContextDialogDelegate>)delegate
{
  if (![FBSDKAccessToken currentAccessToken]) {
    return nil;
  }
  FBSDKSwitchContextDialog *dialog = [FBSDKSwitchContextDialog dialogWithContent:content windowFinder:FBSDKInternalUtility.sharedUtility delegate:delegate];
  return dialog;
}

+ (nullable NSError *)showSwitchContextDialogWithContent:(FBSDKSwitchContextContent *)content delegate:(id<FBSDKContextDialogDelegate>)delegate
{
  FBSDKSwitchContextDialog *dialog = [self switchContextDialogWithContent:content delegate:delegate];
  if (dialog) {
    [dialog show];
    return nil;
  }
  NSError *tokenError = [FBSDKError
                         errorWithCode:FBSDKErrorAccessTokenRequired
                         message:@"A valid access token is required to launch the Dialog"];
  return tokenError;
}

+ (FBSDKChooseContextDialog *)chooseContextDialogWithContent:(FBSDKChooseContextContent *)content delegate:(id<FBSDKContextDialogDelegate>)delegate
{
  FBSDKChooseContextDialog *dialog = [FBSDKChooseContextDialog dialogWithContent:content delegate:delegate];
  return dialog;
}

+ (FBSDKChooseContextDialog *)showChooseContextDialogWithContent:(FBSDKChooseContextContent *)content delegate:(id<FBSDKContextDialogDelegate>)delegate
{
  FBSDKChooseContextDialog *dialog = [self chooseContextDialogWithContent:content delegate:delegate];
  [dialog show];
  return dialog;
}

@end

#endif
