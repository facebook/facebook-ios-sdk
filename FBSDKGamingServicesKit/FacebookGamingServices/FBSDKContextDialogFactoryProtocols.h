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

 #import <FacebookGamingServices/FBSDKChooseContextContent.h>
 #import <FacebookGamingServices/FBSDKCreateContextContent.h>
 #import <FacebookGamingServices/FBSDKSwitchContextContent.h>

@protocol FBSDKShowable;
@protocol FBSDKWindowFinding;
@protocol FBSDKContextDialogDelegate;

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(CreateContextDialogMaking)
@protocol FBSDKCreateContextDialogMaking

- (nullable id<FBSDKShowable>)makeCreateContextDialogWithContent:(FBSDKCreateContextContent *)content
                                                    windowFinder:(id<FBSDKWindowFinding>)windowFinder
                                                        delegate:(id<FBSDKContextDialogDelegate>)delegate;

@end

NS_SWIFT_NAME(ChooseContextDialogMaking)
@protocol FBSDKChooseContextDialogMaking

- (id<FBSDKShowable>)makeChooseContextDialogWithContent:(FBSDKChooseContextContent *)content
                                               delegate:(id<FBSDKContextDialogDelegate>)delegate;

@end

NS_ASSUME_NONNULL_END

#endif
