/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !TARGET_OS_TV

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
  Extension protocol for NSMutableCopying that adds the mutableCopy method, which is implemented on NSObject.

 NSObject<NSCopying, NSMutableCopying> implicitly conforms to this protocol.
 */
NS_SWIFT_NAME(MutableCopying)
@protocol FBSDKMutableCopying <NSCopying, NSObject, NSMutableCopying>

/**
  Implemented by NSObject as a convenience to mutableCopyWithZone:.
 @return A mutable copy of the receiver.
 */
- (id)mutableCopy;

@end

NS_ASSUME_NONNULL_END

#endif
