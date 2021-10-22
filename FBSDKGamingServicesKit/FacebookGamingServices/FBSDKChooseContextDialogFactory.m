/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "FBSDKChooseContextDialogFactory.h"

#import "FBSDKChooseContextDialog.h"
#import "FBSDKContextDialogs+Showable.h"

@implementation FBSDKChooseContextDialogFactory

- (nonnull id<FBSDKShowable>)makeChooseContextDialogWithContent:(FBSDKChooseContextContent *)content
                                                       delegate:(id<FBSDKContextDialogDelegate>)delegate
{
  return [FBSDKChooseContextDialog dialogWithContent:content
                                            delegate:delegate];
}

@end
