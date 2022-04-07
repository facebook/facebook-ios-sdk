/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !TARGET_OS_TV

#import <CoreGraphics/CoreGraphics.h>
#import <Foundation/Foundation.h>

#import <FBSDKCoreKit/FBSDKCoreKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol FBSDKWebDialogDelegate;

@interface FBSDKWebDialog ()

@property (class, nullable, nonatomic) id<FBSDKErrorCreating> errorFactory;

@property (nonatomic, weak) id<FBSDKWebDialogDelegate> delegate;
@property (nonatomic, copy) NSString *name;
@property (nullable, nonatomic, copy) NSDictionary<NSString *, id> *parameters;
@property (nonatomic) CGRect webViewFrame;

- (BOOL)show;

// UNCRUSTIFY_FORMAT_OFF
+ (void)configureWithErrorFactory:(id<FBSDKErrorCreating>)errorFactory
NS_SWIFT_NAME(configure(errorFactory:));
// UNCRUSTIFY_FORMAT_ON

#if DEBUG

+ (void)resetClassDependencies;

#endif

@end

NS_ASSUME_NONNULL_END

#endif
