/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "TargetConditionals.h"

#if !TARGET_OS_TV

 #import <Foundation/Foundation.h>
@protocol FBSDKValidatable;
@protocol FBSDKContextDialogDelegate;
@class FBSDKContextWebDialog;

NS_ASSUME_NONNULL_BEGIN

/**
  The protocol sdk dialogs must conform to and implement all the following methods.
 */
NS_SWIFT_NAME(DialogProtocol)
@protocol FBSDKDialog
/**
  The receiver's delegate or nil if it doesn't have a delegate.
 */
@property (nullable, nonatomic, weak) id<FBSDKContextDialogDelegate> delegate;

/**
  The content object used to create the specific dialog
 */
@property (nullable, nonatomic) id<FBSDKValidatable> dialogContent;

/**
  Begins to show the specfic dialog
 @return YES if the receiver was able to show the dialog, otherwise NO.
 */
- (BOOL)show;

/**
  Validates the content for the dialog
 @param errorRef If an error occurs, upon return contains an NSError object that describes the problem.
 @return YES if the content is valid, otherwise NO.
 */
- (BOOL)validateWithError:(NSError *__autoreleasing *)errorRef;
@end

/**
  A delegate for context dialogs to communicate with the dialog handler.

 The delegate is notified with the results of the cross play request as long as the application has permissions to
 receive the information.  For example, if the person is not signed into the containing app, the shower may not be able
 to distinguish between completion of a cross play request and cancellation.
 */
NS_SWIFT_NAME(ContextDialogDelegate)
@protocol FBSDKContextDialogDelegate <NSObject>

/**
  Sent to the delegate when the context dialog completes without error.
 @param contextDialog The FBSDKContextDialog that completed.
 */
- (void)contextDialogDidComplete:(FBSDKContextWebDialog *)contextDialog;

/**
  Sent to the delegate when the context dialog encounters an error.
 @param contextDialog The FBSDKContextDialog that completed.
 @param error The error.
 */
- (void)contextDialog:(FBSDKContextWebDialog *)contextDialog didFailWithError:(NSError *)error;

/**
  Sent to the delegate when the cross play request dialog is cancelled.
 @param contextDialog The FBSDKContextDialog that completed.
 */
- (void)contextDialogDidCancel:(FBSDKContextWebDialog *)contextDialog;

@end

/**
  A protocol that a content object must conform to be used in a Gaming Services dialog
 */
NS_SWIFT_NAME(ValidatableProtocol)
@protocol FBSDKValidatable <NSObject>

- (BOOL)validateWithError:(NSError *__autoreleasing *)errorRef;
@end

NS_ASSUME_NONNULL_END
#endif
