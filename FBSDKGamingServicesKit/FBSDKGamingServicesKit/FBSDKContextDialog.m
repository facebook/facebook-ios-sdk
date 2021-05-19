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

 #import "FBSDKContextDialog.h"

 #import "FBSDKCoreKitInternalImport.h"

@interface FBSDKContextDialog () <FBSDKWebDialogDelegate>

@property (nonatomic) FBSDKWebDialog *webDialog;

@end

@implementation FBSDKContextDialog

 #define FBSDK_CONTEXT_METHOD_NAME @"context"

 #pragma mark - Class Methods

+ (instancetype)createAsyncDialogWithContent:(FBSDKContextCreateAsyncContent *)content delegate:(id<FBSDKContextDialogDelegate>)delegate
{
  FBSDKContextDialog *dialog = [[self alloc] init];
  dialog.createAsyncContent = content;
  dialog.delegate = delegate;
  return dialog;
}

+ (instancetype)createAsyncShowWithContent:(FBSDKContextCreateAsyncContent *)content delegate:(id<FBSDKContextDialogDelegate>)delegate
{
  FBSDKContextDialog *dialog = [self createAsyncDialogWithContent:content delegate:delegate];
  [dialog show];
  return dialog;
}

+ (instancetype)switchAsyncDialogWithContent:(FBSDKContextSwitchAsyncContent *)content delegate:(id<FBSDKContextDialogDelegate>)delegate
{
  FBSDKContextDialog *dialog = [[self alloc] init];
  dialog.switchAsyncContent = content;
  dialog.delegate = delegate;
  return dialog;
}

+ (instancetype)switchAsyncShowWithContent:(FBSDKContextSwitchAsyncContent *)content delegate:(id<FBSDKContextDialogDelegate>)delegate
{
  FBSDKContextDialog *dialog = [self switchAsyncDialogWithContent:content delegate:delegate];
  [dialog show];
  return dialog;
}

 #pragma mark - Public Methods

- (BOOL)canShow
{
  return YES;
}

- (BOOL)show
{
  NSError *error;
  if (!self.canShow) {
    error = [FBSDKError errorWithDomain:FBSDKErrorDomain
                                   code:FBSDKErrorDialogUnavailable
                                message:@"Context dialog is not available."];
    [_delegate contextDialog:self didFailWithError:error];
    return NO;
  }
  if (![self validateWithError:&error]) {
    [_delegate contextDialog:self didFailWithError:error];
    return NO;
  }

  FBSDKContextCreateAsyncContent *createAsyncContent = self.createAsyncContent;
  FBSDKContextSwitchAsyncContent *switchAsyncContent = self.switchAsyncContent;

  if (error) {
    return NO;
  }

  NSMutableDictionary *parameters = [NSMutableDictionary new];

  if (createAsyncContent) {
    [FBSDKTypeUtility dictionary:parameters setObject:createAsyncContent.playerID forKey:@"player_id"];
  } else {
    [FBSDKTypeUtility dictionary:parameters setObject:switchAsyncContent.contextToken forKey:@"context_token"];
  }

  self.webDialog = [FBSDKWebDialog showWithName:FBSDK_CONTEXT_METHOD_NAME
                                     parameters:parameters
                                       delegate:self];
  [FBSDKInternalUtility registerTransientObject:self];
  return YES;
}

- (BOOL)validateWithError:(NSError *__autoreleasing *)errorRef
{
  if (self.createAsyncContent) {
    if ([self.createAsyncContent respondsToSelector:@selector(validateWithError:)]) {
      return [self.createAsyncContent validateWithError:errorRef];
    }

    if (errorRef != NULL) {
      *errorRef = [FBSDKError invalidArgumentErrorWithDomain:FBSDKErrorDomain
                                                        name:@"createAsyncContent"
                                                       value:self.createAsyncContent
                                                     message:nil];
    }
  }

  if (self.switchAsyncContent) {
    if ([self.switchAsyncContent respondsToSelector:@selector(validateWithError:)]) {
      return [self.switchAsyncContent validateWithError:errorRef];
    }

    if (errorRef != NULL) {
      *errorRef = [FBSDKError invalidArgumentErrorWithDomain:FBSDKErrorDomain
                                                        name:@"switchAsyncContent"
                                                       value:self.switchAsyncContent
                                                     message:nil];
    }
  }

  return NO;
}

 #pragma mark - FBSDKWebDialogDelegate

- (void)webDialog:(FBSDKWebDialog *)webDialog didCompleteWithResults:(NSDictionary *)results
{
  if (self.webDialog != webDialog) {
    return;
  }

  NSError *error = [FBSDKError errorWithCode:[FBSDKTypeUtility unsignedIntegerValue:results[@"error_code"]]
                                     message:[FBSDKTypeUtility coercedToStringValue:results[@"error_message"]]];
  [self _handleCompletionWithDialogResults:results error:error];
  [FBSDKInternalUtility unregisterTransientObject:self];
}

- (void)webDialog:(FBSDKWebDialog *)webDialog didFailWithError:(NSError *)error
{
  if (self.webDialog != webDialog) {
    return;
  }
  [self _handleCompletionWithDialogResults:nil error:error];
  [FBSDKInternalUtility unregisterTransientObject:self];
}

- (void)webDialogDidCancel:(FBSDKWebDialog *)webDialog
{
  if (self.webDialog != webDialog) {
    return;
  }
  [_delegate contextDialogDidCancel:self];
  [FBSDKInternalUtility unregisterTransientObject:self];
}

 #pragma mark - Helper Methods

- (void)_handleCompletionWithDialogResults:(NSDictionary *)results error:(NSError *)error
{
  if (!_delegate) {
    return;
  }
  switch (error.code) {
    case 0: {
      [_delegate contextDialog:self didCompleteWithResults:results];
      break;
    }
    case 4201: {
      [_delegate contextDialogDidCancel:self];
      break;
    }
    default: {
      [_delegate contextDialog:self didFailWithError:error];
      break;
    }
  }
  if (error) {
    return;
  }
}

@end

#endif
