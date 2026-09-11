/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <Foundation/Foundation.h>

@class UIView;

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(_ScreenTitleObserver)
@interface FBSDKScreenTitleObserver : NSObject

@property (class, readonly, strong) FBSDKScreenTitleObserver *shared;

@property (nullable, nonatomic, readonly) IMP originalViewDidAppearImplementation;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

- (void)startObserving;
- (void)stopObserving;
- (nullable NSString *)currentScreenTitle;
- (void)setScreenTitle:(nullable NSString *)screenTitle;

+ (nullable NSString *)findLargeContentTitleInView:(nullable UIView *)rootView;

@end

NS_ASSUME_NONNULL_END
