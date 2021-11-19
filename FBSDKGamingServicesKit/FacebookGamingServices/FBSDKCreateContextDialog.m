/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <UIKit/UIKit.h>

#if !TARGET_OS_TV

 #import "FBSDKCreateContextDialog.h"

 #import <FBSDKCoreKit_Basics/FBSDKCoreKit_Basics.h>

 #import <FacebookGamingServices/FacebookGamingServices-Swift.h>

 #import "FBSDKCreateContextContent.h"

 #define FBSDK_CONTEXT_METHOD_NAME @"context"
 #define FBSDKWEBDIALOGFRAMEWIDTH 300
 #define FBSDKWEBDIALOGFRAMEHEIGHT 185

@interface FBSDKCreateContextDialog ()
@property (nonatomic) id<FBSDKWindowFinding> windowFinder;
@end

@implementation FBSDKCreateContextDialog

+ (instancetype)dialogWithContent:(FBSDKCreateContextContent *)content
                     windowFinder:(id<FBSDKWindowFinding>)windowFinder
                         delegate:(id<FBSDKContextDialogDelegate>)delegate
{
  FBSDKCreateContextDialog *dialog = [self new];
  dialog.dialogContent = content;
  dialog.delegate = delegate;
  dialog.windowFinder = windowFinder;
  return dialog;
}

- (BOOL)show
{
  NSError *error;
  if (![self validateWithError:&error]) {
    if (error) {
      [self.delegate contextDialog:self didFailWithError:error];
    }
    return NO;
  }

  NSMutableDictionary<NSString *, id> *parameters = [NSMutableDictionary new];

  if ([self.dialogContent isKindOfClass:FBSDKCreateContextContent.class] && self.dialogContent) {
    FBSDKCreateContextContent *content = (FBSDKCreateContextContent *)self.dialogContent;
    if (content.playerID) {
      parameters[@"player_id"] = content.playerID;
    }
  }

  CGRect frame = [self createWebDialogFrameWithWidth:(CGFloat)FBSDKWEBDIALOGFRAMEWIDTH height:(CGFloat)FBSDKWEBDIALOGFRAMEHEIGHT windowFinder:self.windowFinder];
  self.currentWebDialog = [FBSDKWebDialog createAndShowWithName:FBSDK_CONTEXT_METHOD_NAME
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
