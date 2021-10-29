/*
 * Copyright (c) Facebook, Inc. and its affiliates.
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

@protocol FBSDKWindowFinding;

NS_ASSUME_NONNULL_BEGIN

/**
 Internal Type exposed to facilitate transition to Swift.
 API Subject to change or removal without warning. Do not use.

 @warning UNSAFE - DO NOT USE
 */
NS_SWIFT_NAME(WebDialog)
@interface FBSDKWebDialog : NSObject

/**
 Internal Type exposed to facilitate transition to Swift.
 API Subject to change or removal without warning. Do not use.

 @warning UNSAFE - DO NOT USE
 */
@property (nonatomic) BOOL shouldDeferVisibility;

/**
 Internal Type exposed to facilitate transition to Swift.
 API Subject to change or removal without warning. Do not use.

 @warning UNSAFE - DO NOT USE
 */
@property (nonatomic, strong) id<FBSDKWindowFinding> windowFinder;

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

/**
 Internal Type exposed to facilitate transition to Swift.
 API Subject to change or removal without warning. Do not use.

 @warning UNSAFE - DO NOT USE
 */
+ (instancetype)dialogWithName:(NSString *)name
                      delegate:(id<FBSDKWebDialogDelegate>)delegate;

/**
 Internal Type exposed to facilitate transition to Swift.
 API Subject to change or removal without warning. Do not use.

 @warning UNSAFE - DO NOT USE
 */
+ (instancetype)showWithName:(NSString *)name
                  parameters:(NSDictionary<NSString *, id> *)parameters
                    delegate:(id<FBSDKWebDialogDelegate>)delegate;

/**
 Internal Type exposed to facilitate transition to Swift.
 API Subject to change or removal without warning. Do not use.

 @warning UNSAFE - DO NOT USE
 */
+ (instancetype)createAndShow:(NSString *)name
                   parameters:(NSDictionary<NSString *, id> *)parameters
                        frame:(CGRect)frame
                     delegate:(id<FBSDKWebDialogDelegate>)delegate
                 windowFinder:(id<FBSDKWindowFinding>)windowFinder;

@end

NS_ASSUME_NONNULL_END

#endif
