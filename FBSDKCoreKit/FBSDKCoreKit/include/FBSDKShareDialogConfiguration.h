/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// Constant used to describe the 'Message' dialog
FOUNDATION_EXPORT NSString *const FBSDKDialogConfigurationNameMessage;
/// Constant used to describe the 'Share' dialog
FOUNDATION_EXPORT NSString *const FBSDKDialogConfigurationNameShare;

/**
 A lightweight interface to expose aspects of FBSDKServerConfiguration that are used by dialogs in ShareKit.

 Internal Use Only
 */
NS_SWIFT_NAME(ShareDialogConfiguration)
@interface FBSDKShareDialogConfiguration : NSObject

@property (nonatomic, readonly, copy) NSString *defaultShareMode;

- (BOOL)shouldUseNativeDialogForDialogName:(NSString *)dialogName;
- (BOOL)shouldUseSafariViewControllerForDialogName:(NSString *)dialogName;

@end

NS_ASSUME_NONNULL_END
