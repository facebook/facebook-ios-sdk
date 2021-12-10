/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <Foundation/Foundation.h>

#import <FacebookGamingServices/FBSDKGamingServiceCompletionHandler.h>

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(FriendFinderDialog)
@interface FBSDKFriendFinderDialog : NSObject

- (instancetype _Nonnull)init NS_SWIFT_UNAVAILABLE("Should not create instances of this class");

/**
 Opens the Friend Finder dialog inside the Facebook app if it's installed, otherwise
 mobile web will be opened.

 @param completionHandler a callback that is fired once the user returns to the
  caller app or an error ocurrs
 */
+ (void)launchFriendFinderDialogWithCompletionHandler:(FBSDKGamingServiceCompletionHandler _Nonnull)completionHandler;

@end

NS_ASSUME_NONNULL_END
