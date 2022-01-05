/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !TARGET_OS_TV
#import "FBSDKContextWebDialog.h"

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import <FBSDKCoreKit_Basics/FBSDKCoreKit_Basics.h>

#import <FacebookGamingServices/FacebookGamingServices-Swift.h>

@implementation FBSDKContextWebDialog

@synthesize delegate = _delegate;
@synthesize dialogContent = _dialogContent;

- (instancetype)initWithDelegate:(id<FBSDKContextDialogDelegate>)delegate;
{
  if ((self = [super init])) {
    _delegate = delegate;
  }
  return self;
}

- (BOOL)show
{
  return false;
}

- (BOOL)validateWithError:(NSError *__autoreleasing _Nullable *_Nullable)errorRef
{
  return false;
}

#pragma mark - FBSDKWebDialogDelegate

- (void)webDialog:(FBSDKWebDialog *)webDialog didCompleteWithResults:(NSDictionary<NSString *, id> *)results
{
  if (self.currentWebDialog != webDialog) {
    return;
  }

  id<FBSDKErrorCreating> errorFactory = [FBSDKErrorFactory new];
  NSError *error = [errorFactory errorWithCode:[FBSDKTypeUtility unsignedIntegerValue:results[@"error_code"]]
                                      userInfo:nil
                                       message:[FBSDKTypeUtility coercedToStringValue:results[@"error_message"]]
                               underlyingError:nil];
  [self _handleCompletionWithDialogResults:results error:error];
  [FBSDKInternalUtility.sharedUtility unregisterTransientObject:self];
}

- (void)webDialog:(FBSDKWebDialog *)webDialog didFailWithError:(NSError *)error
{
  if (self.currentWebDialog != webDialog) {
    return;
  }
  [self _handleCompletionWithDialogResults:nil error:error];
  [FBSDKInternalUtility.sharedUtility unregisterTransientObject:self];
}

- (void)webDialogDidCancel:(FBSDKWebDialog *)webDialog
{
  if (self.currentWebDialog != webDialog) {
    return;
  }
  [self.delegate contextDialogDidCancel:self];
  [FBSDKInternalUtility.sharedUtility unregisterTransientObject:self];
}

- (void)_handleCompletionWithDialogResults:(NSDictionary<NSString *, id> *)results error:(NSError *)error
{
  if (!self.delegate) {
    return;
  }
  switch (error.code) {
    case 0: {
      if ([results isKindOfClass:[NSDictionary<NSString *, id> class]] && results[@"context_id"] != nil) {
        NSString *const identifier = results[@"context_id"];
        NSString *const sizeString = results[@"context_size"];
        NSInteger size = [sizeString isKindOfClass:NSString.class] ? [sizeString integerValue] : 0;
        FBSDKGamingContext.currentContext = [[FBSDKGamingContext alloc] initWithIdentifier:identifier size:size];
        [self.delegate contextDialogDidComplete:self];
      } else {
        [self.delegate contextDialogDidCancel:self];
      }
      break;
    }
    case 4201: {
      [self.delegate contextDialogDidCancel:self];
      break;
    }
    default: {
      [self.delegate contextDialog:self didFailWithError:error];
      break;
    }
  }
}

- (CGRect)createWebDialogFrameWithWidth:(CGFloat)width height:(CGFloat)height windowFinder:(id<FBSDKWindowFinding>)windowFinder
{
  CGRect windowFrame = [windowFinder findWindow].frame;
  CGFloat xPoint = windowFrame.size.width < width ? 0 : CGRectGetMidX(windowFrame) - (width / 2);
  CGFloat yPoint = windowFrame.size.height < height ? 0 : CGRectGetMidY(windowFrame) - (height / 2);
  CGFloat dialogWidth = windowFrame.size.width < width ? windowFrame.size.width : width;
  CGFloat dialogHeight = windowFrame.size.height < height ? windowFrame.size.height : height;

  return CGRectMake(xPoint, yPoint, dialogWidth, dialogHeight);
}

@end
#endif
