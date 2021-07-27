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

#import <UIKit/UIKit.h>

#import "TargetConditionals.h"

#if !TARGET_OS_TV

 #import "FBSDKSwitchContextDialog.h"

 #import "FBSDKSwitchContextContent.h"

 #define FBSDK_CONTEXT_METHOD_NAME @"context"
 #define FBSDKWEBDIALOGFRAMEWIDTH 300.0
 #define FBSDKWEBDIALOGFRAMEHEIGHT 170.0

@interface FBSDKSwitchContextDialog ()
@property id<FBSDKWindowFinding> windowFinder;
@end

@implementation FBSDKSwitchContextDialog

+ (instancetype)dialogWithContent:(FBSDKSwitchContextContent *)content windowFinder:(id<FBSDKWindowFinding>)windowFinder delegate:(id<FBSDKContextDialogDelegate>)delegate
{
  FBSDKSwitchContextDialog *dialog = [self new];
  dialog.dialogContent = content;
  dialog.delegate = delegate;
  dialog.windowFinder = windowFinder;
  return dialog;
}

- (BOOL)show
{
  NSError *error;
  if (![self validateWithError:&error]) {
    [self.delegate contextDialog:self didFailWithError:error];
    return NO;
  }

  NSMutableDictionary *parameters = [NSMutableDictionary new];

  if ([self.dialogContent isKindOfClass:[FBSDKSwitchContextContent class]] && self.dialogContent) {
    FBSDKSwitchContextContent *content = (FBSDKSwitchContextContent *)self.dialogContent;
    if (content.contextTokenID) {
      parameters[@"context_id"] = content.contextTokenID;
    }
  }

  CGRect frame = [self createWebDialogFrameWithWidth:FBSDKWEBDIALOGFRAMEWIDTH height:FBSDKWEBDIALOGFRAMEHEIGHT windowFinder:self.windowFinder];
  self.currentWebDialog = [FBSDKWebDialog createAndShow:FBSDK_CONTEXT_METHOD_NAME
                                             parameters:parameters
                                                  frame:frame
                                               delegate:self
                                           windowFinder:self.windowFinder];

  [FBSDKInternalUtility.sharedUtility registerTransientObject:self];
  return YES;
}

- (BOOL)validateWithError:(NSError *__autoreleasing *)errorRef
{
  if (errorRef == NULL) {
    return NO;
  }
  if (!self.dialogContent) {
    *errorRef = [FBSDKError invalidArgumentErrorWithDomain:FBSDKErrorDomain
                                                      name:@"content"
                                                     value:self.dialogContent
                                                   message:nil];
    return NO;
  }
  if ([self.dialogContent respondsToSelector:@selector(validateWithError:)]) {
    return [self.dialogContent validateWithError:errorRef];
  }
  return NO;
}

@end
#endif
