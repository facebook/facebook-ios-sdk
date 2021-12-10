/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !TARGET_OS_TV

#import <Foundation/Foundation.h>

#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <FBSDKShareKit/FBSDKGameRequestURLProvider.h>
#import <FBSDKShareKit/FBSDKSharingValidation.h>

NS_ASSUME_NONNULL_BEGIN

/**
  A model for a game request.
 */
NS_SWIFT_NAME(GameRequestContent)
@interface FBSDKGameRequestContent : NSObject <NSCopying, NSObject, FBSDKSharingValidation, NSSecureCoding>

/**
  Used when defining additional context about the nature of the request.

 The parameter 'objectID' is required if the action type is either
 'FBSDKGameRequestSendActionType' or 'FBSDKGameRequestAskForActionType'.

- SeeAlso:objectID
 */
@property (nonatomic, assign) FBSDKGameRequestActionType actionType;

/**
  Compares the receiver to another game request content.
 @param content The other content
 @return YES if the receiver's values are equal to the other content's values; otherwise NO
 */
- (BOOL)isEqualToGameRequestContent:(FBSDKGameRequestContent *)content;

/**
  Additional freeform data you may pass for tracking. This will be stored as part of
 the request objects created. The maximum length is 255 characters.
 */
@property (nullable, nonatomic, copy) NSString *data;

/**
  This controls the set of friends someone sees if a multi-friend selector is shown.
 It is FBSDKGameRequestNoFilter by default, meaning that all friends can be shown.
 If specify as FBSDKGameRequestAppUsersFilter, only friends who use the app will be shown.
 On the other hands, use FBSDKGameRequestAppNonUsersFilter to filter only friends who do not use the app.

 The parameter name is preserved to be consistent with the counter part on desktop.
 */
@property (nonatomic, assign) FBSDKGameRequestFilter filters;

/**
  A plain-text message to be sent as part of the request. This text will surface in the App Center view
 of the request, but not on the notification jewel. Required parameter.
 */
@property (nonatomic, copy) NSString *message;

/**
  The Open Graph object ID of the object being sent.

- SeeAlso:actionType
 */
@property (nonatomic, copy) NSString *objectID;

/**
  An array of user IDs, usernames or invite tokens (NSString) of people to send request.

 These may or may not be a friend of the sender. If this is specified by the app,
 the sender will not have a choice of recipients. If not, the sender will see a multi-friend selector

 This is equivalent to the "to" parameter when using the web game request dialog.
 */
@property (nonatomic, copy) NSArray<NSString *> *recipients;

/**
  An array of user IDs that will be included in the dialog as the first suggested friends.
 Cannot be used together with filters.

 This is equivalent to the "suggestions" parameter when using the web game request dialog.
*/
@property (nonatomic, copy) NSArray<NSString *> *recipientSuggestions;

/**
  The title for the dialog.
 */
@property (nonatomic, copy) NSString *title;

/**
  The call to action for the dialog.
 */
@property (nonatomic, copy) NSString *cta;

@end

NS_ASSUME_NONNULL_END

#endif
