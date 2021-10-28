/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(SourceApplicationTracking)
@protocol FBSDKSourceApplicationTracking

- (void)setSourceApplication:(nullable NSString *)sourceApplication openURL:(nullable NSURL *)url;
- (void)setSourceApplication:(nullable NSString *)sourceApplication isFromAppLink:(BOOL)isFromAppLink;
- (void)registerAutoResetSourceApplication;

@end

NS_ASSUME_NONNULL_END
