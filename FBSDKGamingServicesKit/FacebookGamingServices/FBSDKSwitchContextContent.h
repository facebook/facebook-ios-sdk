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
 A model for an instant games switchAsync cross play request.
 */
NS_SWIFT_NAME(SwitchContextContent)
@interface FBSDKSwitchContextContent : NSObject <NSSecureCoding, FBSDKValidatable>

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

/**
  Builds a content object that will be use to display a switch context dialog
 @param contextID  The context ID of the context instance to switch and set as the current game context
 */

// UNCRUSTIFY_FORMAT_OFF
- (instancetype)initDialogContentWithContextID:(NSString *)contextID
NS_SWIFT_NAME(init(contextID:));
// UNCRUSTIFY_FORMAT_ON

/**
 The context token of the existing context for which this request is being made.
 @return The context token of the existing context
 */
@property (nonatomic, copy) NSString *contextTokenID;
@end

NS_ASSUME_NONNULL_END

#endif
