/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <Foundation/Foundation.h>

#import <FBSDKShareKit/FBSDKSharingContent.h>

NS_ASSUME_NONNULL_BEGIN

@protocol FBSDKSharingDelegate;

/**
  The common interface for components that initiate sharing.

 @see FBSDKShareDialog

 @see FBSDKMessageDialog
 */
NS_SWIFT_NAME(Sharing)
@protocol FBSDKSharing <NSObject>

/**
  The receiver's delegate or nil if it doesn't have a delegate.
 */
@property (nonatomic, weak) id<FBSDKSharingDelegate> delegate;

/**
  The content to be shared.
 */
@property (nullable, nonatomic, copy) id<FBSDKSharingContent> shareContent;

/**
  A Boolean value that indicates whether the receiver should fail if it finds an error with the share content.

 If NO, the sharer will still be displayed without the data that was mis-configured.  For example, an
 invalid placeID specified on the shareContent would produce a data error.
 */
@property (nonatomic, assign) BOOL shouldFailOnDataError;

/**
  Validates the content on the receiver.
 @param errorRef If an error occurs, upon return contains an NSError object that describes the problem.
 @return YES if the content is valid, otherwise NO.
 */
- (BOOL)validateWithError:(NSError **)errorRef;

@end

/**
  The common interface for dialogs that initiate sharing.
 */
NS_SWIFT_NAME(SharingDialog)
@protocol FBSDKSharingDialog <FBSDKSharing>

/**
  A Boolean value that indicates whether the receiver can initiate a share.

 May return NO if the appropriate Facebook app is not installed and is required or an access token is
 required but not available.  This method does not validate the content on the receiver, so this can be checked before
 building up the content.

 @see [FBSDKSharing validateWithError:]
 @return YES if the receiver can share, otherwise NO.
 */
@property (nonatomic, readonly) BOOL canShow;

/**
  Shows the dialog.
 @return YES if the receiver was able to begin sharing, otherwise NO.
 */
- (BOOL)show;

@end

/**
  A delegate for FBSDKSharing.

 The delegate is notified with the results of the sharer as long as the application has permissions to
 receive the information.  For example, if the person is not signed into the containing app, the sharer may not be able
 to distinguish between completion of a share and cancellation.
 */
NS_SWIFT_NAME(SharingDelegate)
@protocol FBSDKSharingDelegate

/**
 Sent to the delegate when the share completes without error or cancellation.
 @param sharer The FBSDKSharing that completed.
 @param results The results from the sharer.  This may be nil or empty.
 */
- (void)sharer:(id<FBSDKSharing>)sharer didCompleteWithResults:(NSDictionary<NSString *, id> *)results;

/**
 Sent to the delegate when the sharer encounters an error.
 @param sharer The FBSDKSharing that completed.
 @param error The error.
 */
- (void)sharer:(id<FBSDKSharing>)sharer didFailWithError:(NSError *)error;

/**
 Sent to the delegate when the sharer is cancelled.
 @param sharer The FBSDKSharing that completed.
 */
- (void)sharerDidCancel:(id<FBSDKSharing>)sharer;

@end

NS_ASSUME_NONNULL_END
