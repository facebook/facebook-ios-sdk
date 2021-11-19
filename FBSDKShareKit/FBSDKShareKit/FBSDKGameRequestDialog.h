/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !TARGET_OS_TV

#import <Foundation/Foundation.h>

#import <FBSDKShareKit/FBSDKGameRequestContent.h>

NS_ASSUME_NONNULL_BEGIN

@protocol FBSDKGameRequestDialogDelegate;

/**
  A dialog for sending game requests.
 */
NS_SWIFT_NAME(GameRequestDialog)
@interface FBSDKGameRequestDialog : NSObject

- (instancetype)init NS_DESIGNATED_INITIALIZER
  NS_SWIFT_UNAVAILABLE("Use init(content:delegate:) instead");
+ (instancetype)new NS_UNAVAILABLE;

/**
 Convenience method to build up a game request with content and a delegate.
 @param content The content for the game request.
 @param delegate The receiver's delegate.
 */

// UNCRUSTIFY_FORMAT_OFF
+ (instancetype)dialogWithContent:(FBSDKGameRequestContent *)content
                         delegate:(nullable id<FBSDKGameRequestDialogDelegate>)delegate
NS_SWIFT_NAME(init(content:delegate:));
// UNCRUSTIFY_FORMAT_ON

/**
 Convenience method to build up and show a game request with content and a delegate.
 @param content The content for the game request.
 @param delegate The receiver's delegate.
 */
+ (instancetype)showWithContent:(FBSDKGameRequestContent *)content
                       delegate:(nullable id<FBSDKGameRequestDialogDelegate>)delegate
  NS_SWIFT_UNAVAILABLE("Use init(content:delegate:).show() instead");

/**
  The receiver's delegate or nil if it doesn't have a delegate.
 */
@property (nullable, nonatomic, weak) id<FBSDKGameRequestDialogDelegate> delegate;

/**
  The content for game request.
 */
@property (nonatomic, copy) FBSDKGameRequestContent *content;

/**
  Specifies whether frictionless requests are enabled.
 */
@property (nonatomic, getter = isFrictionlessRequestsEnabled, assign) BOOL frictionlessRequestsEnabled;

/**
  A Boolean value that indicates whether the receiver can initiate a game request.

 May return NO if the appropriate Facebook app is not installed and is required or an access token is
 required but not available.  This method does not validate the content on the receiver, so this can be checked before
 building up the content.

 @see validateWithError:
 @return YES if the receiver can share, otherwise NO.
 */
@property (nonatomic, readonly) BOOL canShow;

/**
  Begins the game request from the receiver.
 @return YES if the receiver was able to show the dialog, otherwise NO.
 */
- (BOOL)show;

/**
  Validates the content on the receiver.
 @param errorRef If an error occurs, upon return contains an NSError object that describes the problem.
 @return YES if the content is valid, otherwise NO.
 */
- (BOOL)validateWithError:(NSError *__autoreleasing *)errorRef;

@end

NS_ASSUME_NONNULL_END

#endif
