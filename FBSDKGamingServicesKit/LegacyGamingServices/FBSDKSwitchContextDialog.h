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

@class FBSDKSwitchContextContent;
#if !TARGET_OS_TV

#import <Foundation/Foundation.h>
#import "FBSDKDialogProtocol.h"
#import "FBSDKContextWebDialog.h"


NS_ASSUME_NONNULL_BEGIN
/**
  A dialog to switch context through web view
 */
NS_SWIFT_NAME(SwitchContextDialog)
@interface FBSDKSwitchContextDialog : FBSDKContextWebDialog

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

/**
 Builds a switch context web dialog with content and a delegate.
 @param content The content for the switch context dialog
 @param windowFinder The application window finder that provides the window to display the dialog
 @param delegate The receiver's delegate used to let the receiver know a context was switch was successful or failure
 */
+ (instancetype)dialogWithContent:(FBSDKSwitchContextContent *)content
                     windowFinder:(id<FBSDKWindowFinding>)windowFinder
                         delegate:(id<FBSDKContextDialogDelegate>)delegate
NS_SWIFT_NAME(init(content:windowFinder:delegate:));

@end
NS_ASSUME_NONNULL_END

#endif
