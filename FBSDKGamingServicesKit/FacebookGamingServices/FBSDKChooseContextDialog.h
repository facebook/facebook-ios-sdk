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

@class FBSDKChooseContextContent;
@protocol FBSDKInternalUtility;

#if !TARGET_OS_TV

#import <Foundation/Foundation.h>
#import <FacebookGamingServices/FBSDKDialogProtocol.h>
#import <FacebookGamingServices/FBSDKContextWebDialog.h>

NS_ASSUME_NONNULL_BEGIN
/**
  A dialog for the choose context through app switch
 */
NS_SWIFT_NAME(ChooseContextDialog)
@interface FBSDKChooseContextDialog : FBSDKContextWebDialog

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

/**
 Convenience method to build up a choose context app switch with content and a delegate.
 @param content The content for the choose context dialog
 @param delegate The receiver's delegate.
 */
+ (instancetype)dialogWithContent:(FBSDKChooseContextContent *)content
                         delegate:(nullable id<FBSDKContextDialogDelegate>)delegate
NS_SWIFT_NAME(init(content:delegate:));

/**
 Convenience method to build up a choose context app switch with content , a delegate and a utility object.
 @param content The content for the choose context dialog
 @param delegate The receiver's delegate.
 @param internalUtility The dialog's utility used to build the url and decide how to display the dialog
 */
+ (instancetype)dialogWithContent:(FBSDKChooseContextContent *)content
                         delegate:(id<FBSDKContextDialogDelegate>)delegate
                  internalUtility:(id<FBSDKInternalUtility>)internalUtility
NS_SWIFT_NAME(init(content:delegate:internalUtility:));


@end
NS_ASSUME_NONNULL_END

#endif
