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

#import <Foundation/Foundation.h>

#import "FBSDKCreateContextContent.h"
#import "FBSDKSwitchContextContent.h"
#import "FBSDKChooseContextContent.h"
NS_ASSUME_NONNULL_BEGIN

@protocol FBSDKContextDialogDelegate;
@class FBSDKChooseContextDialog;
@class FBSDKCreateContextDialog;
@class FBSDKSwitchContextDialog;

/**
  A dialog presenter responsible for creating and showing all the dialogs that create, switch, choose and otherwise manipulate the gaming context.
 */
NS_SWIFT_NAME(ContextDialogPresenter)
@interface FBSDKContextDialogPresenter : NSObject

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

/**
 Convenience method to build up an instant games create context dialog with content and delegate.
 @param content The content for the create context dialog
 @param delegate The receiver's delegate.
 */
+ (nullable FBSDKCreateContextDialog*)createContextDialogWithContent:(FBSDKCreateContextContent *)content
                                                            delegate:(nullable id<FBSDKContextDialogDelegate>)delegate
NS_SWIFT_NAME(init(createContextDialogWithContent:delegate:));

/**
 Convenience method to build up and show an instant games create context dialog with content and delegate.
 @param content The content for create context dialog
 @param delegate The receiver's delegate.
 */
+ (nullable NSError *)showCreateContextDialogWithContent:(FBSDKCreateContextContent *)content
                                                delegate:(nullable id<FBSDKContextDialogDelegate>)delegate
NS_SWIFT_UNAVAILABLE("Use init(createContextDialogWithContent:delegate:).show() instead");

/**
 Convenience method to build up an instant games switch context dialog with the giving content and delegate.
 @param content The content for the switch context dialog
 @param delegate The receiver's delegate.
 */
+ (nullable FBSDKSwitchContextDialog*)switchContextDialogWithContent:(FBSDKSwitchContextContent *)content
                                                            delegate:(nullable id<FBSDKContextDialogDelegate>)delegate
NS_SWIFT_NAME(init(switchContextDialogWithContent:delegate:));

/**
 Convenience method to build up and show an instant games switch context dialog with the giving content and delegate.
 @param content The content for the switch context dialog
 @param delegate The receiver's delegate.
 */
+ (nullable NSError *)showSwitchContextDialogWithContent:(FBSDKSwitchContextContent *)content
                                                delegate:(nullable id<FBSDKContextDialogDelegate>)delegate
NS_SWIFT_UNAVAILABLE("Use init(switchContextDialogWithContent:delegate:).show() instead");

/**
 Convenience method to build up and show an instant games choose context dialog with content and a delegate.
 @param content The content for the cross play request.
 @param delegate The receiver's delegate.
 */
+ (FBSDKChooseContextDialog *)showChooseContextDialogWithContent:(FBSDKChooseContextContent *)content
                                                        delegate:(id<FBSDKContextDialogDelegate>)delegate;
@end


NS_ASSUME_NONNULL_END
#endif
