/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !TARGET_OS_TV

#import <CoreGraphics/CoreGraphics.h>
#import <Foundation/Foundation.h>

#import <FBSDKCoreKit/FBSDKWebDialog.h>

NS_ASSUME_NONNULL_BEGIN

@protocol FBSDKWebDialogDelegate;

@interface FBSDKWebDialog ()

@property (nonatomic, weak) id<FBSDKWebDialogDelegate> delegate;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSDictionary<NSString *, id> *parameters;
@property (nonatomic) CGRect webViewFrame;

- (BOOL)show;

@end

NS_ASSUME_NONNULL_END

#endif
