/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <Foundation/Foundation.h>

#import <FBSDKCoreKit/FBSDKLoginTooltip.h>

NS_ASSUME_NONNULL_BEGIN

/**
 Internal block type exposed to facilitate transition to Swift.
 API Subject to change or removal without warning. Do not use.

 @warning INTERNAL - DO NOT USE
 */
NS_SWIFT_NAME(LoginTooltipBlock)
typedef void (^FBSDKLoginTooltipBlock)(FBSDKLoginTooltip *_Nullable loginTooltip, NSError *_Nullable error);

/**
Internal Type exposed to facilitate transition to Swift.
API Subject to change or removal without warning. Do not use.

@warning INTERNAL - DO NOT USE
 */
NS_SWIFT_NAME(ServerConfigurationProvider)
@interface FBSDKServerConfigurationProvider : NSObject

/**
 Internal method exposed to facilitate transition to Swift.
 API Subject to change or removal without warning. Do not use.

 @warning INTERNAL - DO NOT USE
 */
@property (nonatomic, readonly) NSString *loggingToken;

/**
 Internal method exposed to facilitate transition to Swift.
 API Subject to change or removal without warning. Do not use.

 @warning INTERNAL - DO NOT USE
 */
- (NSUInteger)cachedSmartLoginOptions;

/**
 Internal method exposed to facilitate transition to Swift.
 API Subject to change or removal without warning. Do not use.

 @warning INTERNAL - DO NOT USE
 */
- (BOOL)useSafariViewControllerForDialogName:(NSString *)dialogName;

/**
 Internal method exposed to facilitate transition to Swift.
 API Subject to change or removal without warning. Do not use.

 @warning INTERNAL - DO NOT USE
 */
- (void)loadServerConfigurationWithCompletionBlock:(nullable FBSDKLoginTooltipBlock)completionBlock;
@end

NS_ASSUME_NONNULL_END
