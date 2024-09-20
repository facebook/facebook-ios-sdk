/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <Foundation/Foundation.h>
#import <UIKit/UIApplication.h>

NS_ASSUME_NONNULL_BEGIN

/**
 Internal type exposed to facilitate transition to Swift.
 API Subject to change or removal without warning. Do not use.

 @warning INTERNAL - DO NOT USE
 */
NS_SWIFT_NAME(_InternalURLOpener)
@protocol FBSDKInternalURLOpener

- (BOOL)canOpenURL:(NSURL *)url;
- (BOOL)openURL:(NSURL *)url;
- (void)    openURL:(NSURL *)url
            options:(NSDictionary<UIApplicationOpenExternalURLOptionsKey, id> *)options
  completionHandler:(nullable void (^)(BOOL success))completion;

@end

NS_ASSUME_NONNULL_END
