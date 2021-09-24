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

#if !TARGET_OS_TV
#import "FBSDKContextWebDialog.h"

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import <FBSDKCoreKit_Basics/FBSDKCoreKit_Basics.h>

#import "FBSDKGamingContext.h"

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

  NSError *error = [FBSDKError errorWithCode:[FBSDKTypeUtility unsignedIntegerValue:results[@"error_code"]]
                                     message:[FBSDKTypeUtility coercedToStringValue:results[@"error_message"]]];
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

#pragma mark - Helper Methods

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
        FBSDKGamingContext.currentContext = [FBSDKGamingContext createContextWithIdentifier:identifier size:size];
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
