/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !TARGET_OS_TV

#import <FBSDKCoreKit/FBSDKShareDialogConfiguration.h>

#import "FBSDKShareDialogConfigurationProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@interface FBSDKShareDialogConfiguration (ShareDialogConfiguration) <FBSDKShareDialogConfiguration>
@end

NS_ASSUME_NONNULL_END

#endif
