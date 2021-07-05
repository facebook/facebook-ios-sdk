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

 #import "FBSDKChooseContextDialog.h"

 #import "FBSDKChooseContextContent.h"
 #import "FBSDKCoreKitInternalImport.h"

 #define FBSDK_CONTEXT_DIALOG_URL_SCHEME @"https"
 #define FBSDK_CONTEXT_DIALOG_URL_HOST @"fb.gg"

@interface FBSDKChooseContextDialog () <FBSDKURLOpening>
@end

@implementation FBSDKChooseContextDialog

@synthesize dialogContent = _dialogContent;
@synthesize delegate = _delegate;

+ (instancetype)dialogWithContent:(FBSDKChooseContextContent *)content delegate:(id<FBSDKContextDialogDelegate>)delegate
{
  FBSDKChooseContextDialog *dialog = [self new];
  dialog.dialogContent = content;
  dialog.delegate = delegate;
  return dialog;
}

- (BOOL)show
{
  NSError *error;
  __weak typeof(self) weakSelf = self;
  if (![self validateWithError:&error] && !error) {
    return NO;
  }
  if (error) {
    [self.delegate contextDialog:self didFailWithError:error];
    return NO;
  }
  NSURL *appSwitchDeeplink = [FBSDKInternalUtility URLWithScheme:FBSDK_CONTEXT_DIALOG_URL_SCHEME
                                                            host:FBSDK_CONTEXT_DIALOG_URL_HOST
                                                            path:[NSString stringWithFormat:@"/dialog/choosecontext/%@/", FBSDKSettings.appID]
                                                 queryParameters:[self queryParameters]
                                                           error:&error];

  [[FBSDKBridgeAPI sharedInstance]
   openURL:appSwitchDeeplink
   sender:weakSelf
   handler:^(BOOL success, NSError *_Nullable bridgeError) {
     if (!success && bridgeError) {
       NSError *sdkError = [FBSDKError
                            errorWithCode:FBSDKErrorBridgeAPIInterruption
                            message:@"Error occured while interacting with Gaming Services, Failed to open bridge."
                            underlyingError:bridgeError];
       [self.delegate contextDialog:self didFailWithError:sdkError];
     }
   }];
  return YES;
}

- (BOOL)validateWithError:(NSError *__autoreleasing *)errorRef
{
  if (!errorRef) {
    return NO;
  }

  if (!FBSDKSettings.appID) {
    *errorRef = [FBSDKError errorWithCode:FBSDKErrorInvalidArgument message:@"App ID is not set in settings"];
    return NO;
  }
  if (![self.dialogContent respondsToSelector:@selector(validateWithError:)]) {
    [FBSDKError invalidArgumentErrorWithDomain:FBSDKErrorDomain
                                          name:@"content"
                                         value:self.dialogContent
                                       message:nil];
    return NO;
  }
  return [self.dialogContent validateWithError:errorRef];
}

- (NSMutableDictionary *)queryParameters
{
  NSMutableDictionary *parameters = [NSMutableDictionary new];
  if ([self.dialogContent isKindOfClass:[FBSDKChooseContextContent class]] && self.dialogContent) {
    FBSDKChooseContextContent *content = (FBSDKChooseContextContent *)self.dialogContent;
    [FBSDKTypeUtility dictionary:parameters setObject:[FBSDKChooseContextContent filtersNameForFilters:content.filter] forKey:@"filter"];
  }
  return parameters;
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{
  return NO;
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
  return;
}

- (BOOL)canOpenURL:(NSURL *)url forApplication:(UIApplication *)application sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{
  return NO;
}

- (BOOL)isAuthenticationURL:(NSURL *)url
{
  return NO;
}

@end
#endif
