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

typedef NS_ENUM(NSInteger, FBSDKChooseContextFilter) {
  FBSDKChooseContextFilterNone = 0,
  FBSDKChooseContextFilterNewContextOnly,
  FBSDKChooseContextFilterExistingChallenges,
  FBSDKChooseContextFilterNewPlayersOnly,
}NS_SWIFT_NAME(ChooseContextFilter);

NS_ASSUME_NONNULL_BEGIN

/**
 A model for an instant games choose context app switch dialog
 */
NS_SWIFT_NAME(ChooseContextContent)
@interface FBSDKChooseContextContent : NSObject <FBSDKValidatable>

/**
  This sets the filter which determines which context will show when the user is app switched to the choose context dialog.
 */
@property (nonatomic) FBSDKChooseContextFilter filter;

/**
  This sets the maximum number of participants that the suggested context(s) shown in the dialog should have.
 */
@property (nonatomic) int maxParticipants;

/**
  This sets the minimum number of participants that the suggested context(s) shown in the dialog should have.
 */
@property (nonatomic) int minParticipants;

+ (NSString *)filtersNameForFilters:(FBSDKChooseContextFilter)filter;

@end

NS_ASSUME_NONNULL_END

#endif
