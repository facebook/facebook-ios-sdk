/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !TARGET_OS_TV

#import <CoreGraphics/CGGeometry.h>
#import <CoreGraphics/CoreGraphics.h>
#import <Foundation/Foundation.h>

#import <FBSDKCoreKit/FBSDKWebDialogDelegate.h>

@protocol _FBSDKWindowFinding;

NS_ASSUME_NONNULL_BEGIN

/**
 Internal Type exposed to facilitate transition to Swift.
 API Subject to change or removal without warning. Do not use.

 @warning INTERNAL - DO NOT USE
 */
NS_SWIFT_NAME(WebDialog)
@interface FBSDKWebDialog : NSObject

/**
 Internal Type exposed to facilitate transition to Swift.
 API Subject to change or removal without warning. Do not use.

 @warning INTERNAL - DO NOT USE
 */
@property (nonatomic) BOOL shouldDeferVisibility;

/**
 Internal Type exposed to facilitate transition to Swift.
 API Subject to change or removal without warning. Do not use.

 @warning INTERNAL - DO NOT USE
 */
@property (nullable, nonatomic, strong) id<_FBSDKWindowFinding> windowFinder;

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

/**
 Internal Type exposed to facilitate transition to Swift.
 API Subject to change or removal without warning. Do not use.

 @warning INTERNAL - DO NOT USE
 */
+ (instancetype)dialogWithName:(NSString *)name
                      delegate:(id<FBSDKWebDialogDelegate>)delegate;

/**
 Internal Type exposed to facilitate transition to Swift.
 API Subject to change or removal without warning. Do not use.

 @warning INTERNAL - DO NOT USE
 */
// UNCRUSTIFY_FORMAT_OFF
+ (instancetype)createAndShowWithName:(NSString *)name
                           parameters:(nullable NSDictionary<NSString *, id> *)parameters
                                frame:(CGRect)frame
                             delegate:(id<FBSDKWebDialogDelegate>)delegate
                         windowFinder:(nullable id<_FBSDKWindowFinding>)windowFinder
NS_SWIFT_NAME(createAndShow(name:parameters:frame:delegate:windowFinder:));
// UNCRUSTIFY_FORMAT_ON

@end

NS_ASSUME_NONNULL_END

#endif
