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

/// Whether the developer permits user journey metadata collection (`FBSDKMetaDataCollectionEnabled`).
@property (nonatomic, readonly) BOOL isMetaDataCollectionEnabled;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

/// Installs the `viewDidAppear:` swizzle. Hops to the main thread and is a no-op after the first
/// call, so it is safe to invoke from any thread and any number of times.
- (void)startObserving;
- (nullable NSString *)currentScreenTitle;
- (void)setScreenTitle:(nullable NSString *)screenTitle;

+ (nullable NSString *)findLargeContentTitleInView:(nullable UIView *)rootView;

@end

NS_ASSUME_NONNULL_END
