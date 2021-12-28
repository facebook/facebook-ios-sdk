/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

NS_ASSUME_NONNULL_BEGIN

/**
 A delegate for FBSDKGameRequestDialog.

 The delegate is notified with the results of the game request as long as the application has permissions to
 receive the information.  For example, if the person is not signed into the containing app, the shower may not be able
 to distinguish between completion of a game request and cancellation.
 */
NS_SWIFT_NAME(GameRequestDialogDelegate)
@protocol FBSDKGameRequestDialogDelegate <NSObject>

/**
 Sent to the delegate when the game request completes without error.
 @param gameRequestDialog The FBSDKGameRequestDialog that completed.
 @param results The results from the dialog.  This may be nil or empty.
 */
- (void)gameRequestDialog:(FBSDKGameRequestDialog *)gameRequestDialog didCompleteWithResults:(NSDictionary<NSString *, id> *)results;

/**
 Sent to the delegate when the game request encounters an error.
 @param gameRequestDialog The FBSDKGameRequestDialog that completed.
 @param error The error.
 */
- (void)gameRequestDialog:(FBSDKGameRequestDialog *)gameRequestDialog didFailWithError:(NSError *)error;

/**
 Sent to the delegate when the game request dialog is cancelled.
 @param gameRequestDialog The FBSDKGameRequestDialog that completed.
 */
- (void)gameRequestDialogDidCancel:(FBSDKGameRequestDialog *)gameRequestDialog;

@end

NS_ASSUME_NONNULL_END
