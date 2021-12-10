/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "TargetConditionals.h"

#if !TARGET_OS_TV

 #import <Foundation/Foundation.h>

 #import <FacebookGamingServices/FBSDKDialogProtocol.h>
NS_ASSUME_NONNULL_BEGIN

/**
 A model for an instant games createAsync cross play request.
 */
NS_SWIFT_NAME(CreateContextContent)
@interface FBSDKCreateContextContent : NSObject <NSSecureCoding, FBSDKValidatable>

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

/**
  Builds a content object that will be use to display a create context dialog
 @param playerID The player ID of the user being challenged which will be used  to create a game context
 */

// UNCRUSTIFY_FORMAT_OFF
- (instancetype)initDialogContentWithPlayerID:(NSString *)playerID
NS_SWIFT_NAME(init(playerID:));
// UNCRUSTIFY_FORMAT_ON

/**
 The ID of the player that is being challenged.
 @return The ID for the player being challenged
 */
@property (nonatomic, copy) NSString *playerID;
@end

NS_ASSUME_NONNULL_END

#endif
